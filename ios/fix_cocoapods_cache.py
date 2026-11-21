#!/usr/bin/env python3
"""Rewrite CocoaPods CDN version indexes to only local, lockfile-needed versions.

This prevents `pod install` from timing out while fetching every historical
podspec from cdn.jsdelivr.net / cdn.cocoapods.org.
"""

from __future__ import annotations

import json
import re
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parent
TRUNK = Path.home() / ".cocoapods/repos/trunk"
SPECS = TRUNK / "Specs"


def lockfile_versions() -> dict[str, set[str]]:
    lock = ROOT / "Podfile.lock"
    out: dict[str, set[str]] = defaultdict(set)
    if not lock.exists():
        return out
    text = lock.read_text()
    pods = re.search(r"^PODS:\n(.*?)(?:\nDEPENDENCIES:|\nSPEC REPOS:)", text, re.S | re.M)
    if not pods:
        return out
    for match in re.finditer(
        r"^\s+- ([A-Za-z0-9._+-]+)(?:/[^(\n]+)? \(([^)]+)\)",
        pods.group(1),
        re.M,
    ):
        out[match.group(1)].add(match.group(2))
    return out


def disk_versions() -> dict[str, dict[str, set[str]]]:
    """hash_key -> pod -> versions that have valid JSON podspecs on disk."""
    result: dict[str, dict[str, set[str]]] = defaultdict(lambda: defaultdict(set))
    for podspec in SPECS.glob("*/*/*/*/*/*.podspec.json"):
        try:
            rel = podspec.relative_to(SPECS)
            a, b, c, pod, version, _ = rel.parts
            data = json.loads(podspec.read_text())
            if not isinstance(data, dict):
                continue
            result[f"{a}/{b}/{c}"][pod].add(version)
        except Exception:
            continue
    return result


def write_index(hash_key: str, pods: dict[str, list[str]]) -> None:
    a, b, c = hash_key.split("/")
    idx = TRUNK / f"all_pods_versions_{a}_{b}_{c}.txt"
    lines = [f"{pod}/{'/'.join(versions)}" for pod, versions in sorted(pods.items()) if versions]
    idx.write_text("\n".join(lines) + "\n")
    etag = Path(str(idx) + ".etag")
    if etag.exists():
        etag.unlink()


def main() -> None:
    locked = lockfile_versions()
    on_disk = disk_versions()

    # Required pins that must exist
    must = {
        ("0/3/5", "Firebase", "12.19.3"),
        ("8/b/d", "FirebaseCore", "12.19.3"),
        ("7/9/1", "FirebaseCoreInternal", "12.19.0"),
        ("2/f/7", "FirebaseInstallations", "12.19.0"),
        ("2/d/6", "FirebaseMessaging", "12.19.0"),
        ("1/6/1", "DKImagePickerController", "4.3.9"),
        ("a/d/d", "GoogleMaps", "9.4.0"),
    }
    for hash_key, pod, version in must:
        path = SPECS / hash_key / pod / version / f"{pod}.podspec.json"
        if not path.exists() or path.stat().st_size < 200:
            raise SystemExit(f"Missing required local spec: {path}")
        json.loads(path.read_text())
        print(f"required ok: {pod}@{version}")

    rewritten = 0
    for hash_key, pods in on_disk.items():
        narrowed: dict[str, list[str]] = {}
        for pod, versions in pods.items():
            keep = set(versions)
            if pod in locked:
                # Prefer exact lockfile versions that exist on disk
                preferred = locked[pod] & versions
                if preferred:
                    keep = preferred
                elif len(versions) > 3:
                    # Avoid CDN crawl of huge histories
                    keep = {sorted(versions)[-1]}
            elif len(versions) > 3:
                keep = {sorted(versions)[-1]}
            narrowed[pod] = sorted(keep)
        write_index(hash_key, narrowed)
        rewritten += 1

    # Force critical pins even if other versions existed
    force = {
        "0/3/5": {"Firebase": ["12.19.3"]},
        "8/b/d": {"FirebaseCore": ["12.19.3"]},
        "7/9/1": {"FirebaseCoreInternal": ["12.19.0"]},
        "2/f/7": {"FirebaseInstallations": ["12.19.0"]},
        "2/d/6": {"FirebaseMessaging": ["12.19.0"]},
        "1/6/1": {"DKImagePickerController": ["4.3.9"]},
        "a/d/d": {"GoogleMaps": ["9.4.0"]},
        "3/5/e": {"Google-Maps-iOS-Utils": ["6.1.0"]} if (SPECS / "3/5/e/Google-Maps-iOS-Utils/6.1.0").exists() else {},
    }
    for hash_key, pins in force.items():
        if not pins:
            continue
        a, b, c = hash_key.split("/")
        idx = TRUNK / f"all_pods_versions_{a}_{b}_{c}.txt"
        existing: dict[str, list[str]] = {}
        if idx.exists():
            for line in idx.read_text().splitlines():
                if not line.strip():
                    continue
                parts = line.split("/")
                existing[parts[0]] = parts[1:]
        existing.update(pins)
        write_index(hash_key, existing)
        print(f"forced pins in {idx.name}: {pins}")

    print(f"rewrote {rewritten} CDN shard indexes")
    print("done")


if __name__ == "__main__":
    main()
