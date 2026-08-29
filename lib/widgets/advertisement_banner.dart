import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_export.dart';
import '../core/network/authenticated_image.dart';
import '../data/models/advertisement.dart';
import '../data/repositories/advertisement_repository.dart';

/// Fetches public ads for [placement], records impressions/clicks, and opens links.
///
/// Hides itself when the request fails, the list is empty, media URLs are
/// missing, or every network image fails — unless [fallback] is provided.
class AdvertisementBanner extends StatefulWidget {
  const AdvertisementBanner({
    super.key,
    required this.placement,
    this.limit = 5,
    this.height,
    this.aspectRatio = 16 / 5,
    this.borderRadius,
    this.fallback,
    this.autoAdvanceSeconds = 4,
    this.refreshToken = 0,
    this.repository,
  });

  final String placement;
  final int limit;

  /// Fixed height (e.g. compact editor strip). When null, uses [aspectRatio].
  final double? height;

  /// Used when [height] is null for a responsive full-width banner.
  final double aspectRatio;

  final BorderRadius? borderRadius;

  /// Optional placeholder when there are no ads. When null, the banner hides.
  final Widget? fallback;

  final int autoAdvanceSeconds;

  /// Increment to force a network refresh (home pull-to-refresh / revisit).
  final int refreshToken;

  /// Optional override for tests.
  final AdvertisementRepository? repository;

  @override
  State<AdvertisementBanner> createState() => AdvertisementBannerState();
}

@visibleForTesting
class AdvertisementBannerState extends State<AdvertisementBanner> {
  late final AdvertisementRepository _repo =
      widget.repository ?? AdvertisementRepository();
  final PageController _pageController = PageController();
  final Set<int> _recordedImpressions = {};
  final Set<int> _failedImageIds = {};

  List<Advertisement> _ads = const [];
  bool _loading = true;
  int _index = 0;
  Timer? _autoAdvance;

  List<Advertisement> get _visibleAds => _ads
      .where((ad) => !_failedImageIds.contains(ad.id))
      .toList(growable: false);

  @override
  void initState() {
    super.initState();
    // Skip session cache when a test/repo override is provided.
    if (widget.repository == null) {
      final cached = AdvertisementRepository.peekCachedAdsForCurrentPlatform(
        placement: widget.placement,
        limit: widget.limit,
      );
      if (cached != null && cached.isNotEmpty) {
        _ads = cached;
        _loading = false;
        _startAutoAdvance(cached.length);
        _recordImpressionForIndex(0);
      }
    }
    // Always refresh so empty/stale sessions are not sticky.
    _loadAds(forceRefresh: true);
  }

  @override
  void didUpdateWidget(covariant AdvertisementBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    final placementChanged =
        oldWidget.placement != widget.placement ||
        oldWidget.limit != widget.limit;
    final refreshRequested = oldWidget.refreshToken != widget.refreshToken;
    if (!placementChanged && !refreshRequested) return;

    _recordedImpressions.clear();
    _failedImageIds.clear();
    _autoAdvance?.cancel();
    if (placementChanged) {
      _ads = const [];
      _loading = true;
      _index = 0;
    }
    _loadAds(forceRefresh: true);
  }

  @override
  void dispose() {
    _autoAdvance?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadAds({required bool forceRefresh}) async {
    final result = await _repo.fetchAdsForCurrentPlatform(
      placement: widget.placement,
      limit: widget.limit,
      forceRefresh: forceRefresh,
    );
    if (!mounted) return;

    if (result is AdvertisementSuccess<List<Advertisement>>) {
      final ads = result.data;
      if (kDebugMode) {
        debugPrint(
          '[ads] banner ${widget.placement}: ${ads.length} ad(s) ready',
        );
      }
      setState(() {
        _ads = ads;
        _failedImageIds.clear();
        _loading = false;
        if (_index >= ads.length) _index = 0;
      });
      _autoAdvance?.cancel();
      if (ads.isNotEmpty) {
        _startAutoAdvance(ads.length);
        _recordImpressionForIndex(_index);
      }
      return;
    }

    if (kDebugMode) {
      final message = result is AdvertisementFailure<List<Advertisement>>
          ? result.message
          : 'unknown';
      debugPrint('[ads] banner ${widget.placement}: load failed ($message)');
    }
    // Keep previously shown ads on a soft refresh failure; hide if none.
    setState(() => _loading = false);
  }

  void _startAutoAdvance(int count) {
    _autoAdvance?.cancel();
    if (count <= 1 || widget.autoAdvanceSeconds <= 0) return;
    _autoAdvance = Timer.periodic(
      Duration(seconds: widget.autoAdvanceSeconds),
      (_) {
        final visible = _visibleAds;
        if (!mounted || !_pageController.hasClients || visible.length <= 1) {
          return;
        }
        final next = (_index + 1) % visible.length;
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeInOut,
        );
      },
    );
  }

  void _recordImpressionForIndex(int index) {
    final visible = _visibleAds;
    if (index < 0 || index >= visible.length) return;
    final id = visible[index].id;
    if (_recordedImpressions.contains(id)) return;
    _recordedImpressions.add(id);
    unawaited(_repo.recordImpression(id));
  }

  void _onImageFailed(Advertisement ad) {
    debugMarkImageFailed(ad.id);
  }

  /// Test helper: simulates a network image failure for [adId].
  @visibleForTesting
  void debugMarkImageFailed(int adId) {
    if (_failedImageIds.contains(adId)) return;
    if (kDebugMode) {
      debugPrint('[ads] image failed id=$adId');
    }
    setState(() {
      _failedImageIds.add(adId);
      final visible = _visibleAds;
      if (_index >= visible.length) {
        _index = visible.isEmpty ? 0 : visible.length - 1;
      }
    });
    final remaining = _visibleAds.length;
    _autoAdvance?.cancel();
    if (remaining > 1) {
      _startAutoAdvance(remaining);
    }
  }

  Future<void> _onAdTap(Advertisement ad) async {
    final existing = ad.linkUrl?.trim();
    if (existing == null || existing.isEmpty) {
      // Still record the click server-side when possible.
      unawaited(_repo.recordClick(ad.id));
      return;
    }

    final link = await _repo.recordClick(ad.id) ?? existing;
    if (link.trim().isEmpty) return;
    final uri = Uri.tryParse(link.trim());
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
      return;
    }
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Widget _wrapSize({required Widget child}) {
    if (widget.height != null) {
      return SizedBox(height: widget.height, child: child);
    }
    return AspectRatio(aspectRatio: widget.aspectRatio, child: child);
  }

  Widget _loadingPlaceholder(BorderRadius radius, ColorScheme cs) {
    return _wrapSize(
      child: ClipRRect(
        borderRadius: radius,
        child: ColoredBox(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
          child: Center(
            child: SizedBox.square(
              dimension: 22.adaptSize,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: cs.primary.withValues(alpha: 0.7),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(14.adaptSize);
    final cs = Theme.of(context).colorScheme;
    final visible = _visibleAds;

    if (_loading && visible.isEmpty) {
      return _loadingPlaceholder(radius, cs);
    }

    if (visible.isEmpty) {
      return widget.fallback ?? const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _wrapSize(
          child: ClipRRect(
            borderRadius: radius,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: PageView.builder(
                controller: _pageController,
                itemCount: visible.length,
                onPageChanged: (i) {
                  setState(() => _index = i);
                  _recordImpressionForIndex(i);
                },
                itemBuilder: (context, i) {
                  final ad = visible[i];
                  return _AdSlide(
                    ad: ad,
                    onTap: () => _onAdTap(ad),
                    onImageError: () => _onImageFailed(ad),
                  );
                },
              ),
            ),
          ),
        ),
        if (visible.length > 1) ...[
          SizedBox(height: 8.v),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(visible.length, (i) {
              final active = i == _index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: EdgeInsets.symmetric(horizontal: 3.h),
                width: active ? 18.h : 6.h,
                height: 6.v,
                decoration: BoxDecoration(
                  color: active
                      ? cs.primary
                      : cs.onSurface.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(99),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}

class _AdSlide extends StatelessWidget {
  const _AdSlide({
    required this.ad,
    required this.onTap,
    required this.onImageError,
  });

  final Advertisement ad;
  final VoidCallback onTap;
  final VoidCallback onImageError;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final imageUrl = ad.displayImageUrl ?? ad.mediaUrl;
    final hasLink = ad.linkUrl != null && ad.linkUrl!.trim().isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: hasLink ? onTap : null,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl != null && imageUrl.isNotEmpty)
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                headers: musamiAuthenticatedHeadersForUrl(imageUrl),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return ColoredBox(
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
                    child: Center(
                      child: SizedBox.square(
                        dimension: 20.adaptSize,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: cs.primary.withValues(alpha: 0.65),
                        ),
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    onImageError();
                  });
                  return const SizedBox.shrink();
                },
              )
            else
              const SizedBox.shrink(),
            if (ad.advertiserName != null && ad.advertiserName!.isNotEmpty)
              Positioned(
                left: 8.h,
                bottom: 6.v,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(6.adaptSize),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.h,
                      vertical: 3.v,
                    ),
                    child: Text(
                      ad.advertiserName!,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11.fSize,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
