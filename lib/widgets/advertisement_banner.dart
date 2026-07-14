import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_export.dart';
import '../data/models/advertisement.dart';
import '../data/repositories/advertisement_repository.dart';

/// Fetches public ads for [placement], records impressions/clicks, and opens links.
class AdvertisementBanner extends StatefulWidget {
  const AdvertisementBanner({
    super.key,
    required this.placement,
    this.limit = 5,
    this.height,
    this.borderRadius,
    this.fallback,
    this.autoAdvanceSeconds = 4,
  });

  final String placement;
  final int limit;
  final double? height;
  final BorderRadius? borderRadius;
  final Widget? fallback;
  final int autoAdvanceSeconds;

  @override
  State<AdvertisementBanner> createState() => _AdvertisementBannerState();
}

class _AdvertisementBannerState extends State<AdvertisementBanner> {
  final AdvertisementRepository _repo = AdvertisementRepository();
  final PageController _pageController = PageController();
  final Set<int> _recordedImpressions = {};

  List<Advertisement> _ads = const [];
  bool _loading = true;
  int _index = 0;
  Timer? _autoAdvance;

  @override
  void initState() {
    super.initState();
    final cached = AdvertisementRepository.peekCachedAdsForCurrentPlatform(
      placement: widget.placement,
      limit: widget.limit,
    );
    if (cached != null) {
      _ads = cached;
      _loading = false;
      if (cached.isNotEmpty) {
        _startAutoAdvance(cached.length);
        _recordImpressionForIndex(0);
      }
      return;
    }
    _loadAds();
  }

  @override
  void didUpdateWidget(covariant AdvertisementBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.placement == widget.placement &&
        oldWidget.limit == widget.limit) {
      return;
    }
    _recordedImpressions.clear();
    _autoAdvance?.cancel();
    _ads = const [];
    _loading = true;
    _index = 0;
    _loadAds();
  }

  @override
  void dispose() {
    _autoAdvance?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadAds() async {
    final result = await _repo.fetchAdsForCurrentPlatform(
      placement: widget.placement,
      limit: widget.limit,
    );
    if (!mounted) return;
    if (result is AdvertisementSuccess<List<Advertisement>>) {
      final ads = result.data;
      setState(() {
        _ads = ads;
        _loading = false;
      });
      if (ads.isNotEmpty) {
        _startAutoAdvance(ads.length);
        _recordImpressionForIndex(0);
      }
      return;
    }
    setState(() => _loading = false);
  }

  void _startAutoAdvance(int count) {
    _autoAdvance?.cancel();
    if (count <= 1 || widget.autoAdvanceSeconds <= 0) return;
    _autoAdvance = Timer.periodic(Duration(seconds: widget.autoAdvanceSeconds), (_) {
      if (!mounted || !_pageController.hasClients || _ads.length <= 1) return;
      final next = (_index + 1) % _ads.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOut,
      );
    });
  }

  void _recordImpressionForIndex(int index) {
    if (index < 0 || index >= _ads.length) return;
    final id = _ads[index].id;
    if (_recordedImpressions.contains(id)) return;
    _recordedImpressions.add(id);
    unawaited(_repo.recordImpression(id));
  }

  Future<void> _onAdTap(Advertisement ad) async {
    final link = await _repo.recordClick(ad.id) ?? ad.linkUrl;
    if (link == null || link.trim().isEmpty) return;
    final uri = Uri.tryParse(link.trim());
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return SizedBox(
        height: widget.height ?? 120.v,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_ads.isEmpty) {
      return widget.fallback ?? _DefaultAdFallback(height: widget.height);
    }

    final radius = widget.borderRadius ?? BorderRadius.circular(14.adaptSize);
    final cs = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: widget.height ?? 120.v,
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
                itemCount: _ads.length,
                onPageChanged: (i) {
                  setState(() => _index = i);
                  _recordImpressionForIndex(i);
                },
                itemBuilder: (context, i) => _AdSlide(
                  ad: _ads[i],
                  onTap: () => _onAdTap(_ads[i]),
                ),
              ),
            ),
          ),
        ),
        if (_ads.length > 1) ...[
          SizedBox(height: 8.v),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_ads.length, (i) {
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
  const _AdSlide({required this.ad, required this.onTap});

  final Advertisement ad;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final imageUrl = ad.displayImageUrl;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl != null)
              CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, _) => ColoredBox(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (_, _, _) => _AdTextFallback(ad: ad),
              )
            else
              _AdTextFallback(ad: ad),
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
                    padding: EdgeInsets.symmetric(horizontal: 8.h, vertical: 3.v),
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

class _AdTextFallback extends StatelessWidget {
  const _AdTextFallback({required this.ad});

  final Advertisement ad;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14.h, vertical: 12.v),
      child: Center(
        child: Text(
          ad.title,
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
            height: 1.25,
          ),
        ),
      ),
    );
  }
}

class _DefaultAdFallback extends StatefulWidget {
  const _DefaultAdFallback({this.height});

  final double? height;

  @override
  State<_DefaultAdFallback> createState() => _DefaultAdFallbackState();
}

class _DefaultAdFallbackState extends State<_DefaultAdFallback> {
  static const _messages = [
    'Advertise your ad here',
    'Promote your business to our community',
    'Show your offer — this space is yours',
  ];

  late final PageController _controller = PageController();
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_controller.hasClients) return;
      final next = (_index + 1) % _messages.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: widget.height ?? 120.v,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14.adaptSize),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: PageView.builder(
            controller: _controller,
            itemCount: _messages.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) => Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 14.h),
                child: Text(
                  _messages[i],
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
