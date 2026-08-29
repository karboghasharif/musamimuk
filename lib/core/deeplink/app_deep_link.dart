import '../../routes/app_routes.dart';
import '../../presentation/screen_contesttwo_screen/models/contest_detail_args.dart';
import 'app_link_config.dart';

/// Destination resolved from an incoming deep / App Link.
enum AppDeepLinkTarget {
  home,
  about,
  contestList,
  contestDetail,
  contestFeed,
  contestGallery,
  contestWinners,
  contestMySubmissions,
  onlineDesigns,
  myDesigns,
  openDesign,
  newDesign,
  removeBackground,
  qrGenerator,
  subscription,
  playStore,
}

/// Parsed deep-link payload ready for navigation.
class AppDeepLink {
  const AppDeepLink({
    required this.target,
    this.contestId,
    this.submissionId,
    this.designId,
    this.raw,
  });

  final AppDeepLinkTarget target;
  final int? contestId;
  final int? submissionId;
  final int? designId;
  final Uri? raw;

  String get routeName {
    return switch (target) {
      AppDeepLinkTarget.home => AppRoutes.screen1HomeScreen,
      AppDeepLinkTarget.about => AppRoutes.aboutUsScreen,
      AppDeepLinkTarget.contestList => AppRoutes.screenContestScreen,
      AppDeepLinkTarget.contestDetail => AppRoutes.screenContesttwoScreen,
      AppDeepLinkTarget.contestFeed => AppRoutes.contestFeedScreen,
      AppDeepLinkTarget.contestGallery => AppRoutes.contestGalleryScreen,
      AppDeepLinkTarget.contestWinners => AppRoutes.contestWinnersScreen,
      AppDeepLinkTarget.contestMySubmissions =>
        AppRoutes.contestMySubmissionsScreen,
      AppDeepLinkTarget.onlineDesigns => AppRoutes.screen16OnlineDesignsScreen,
      AppDeepLinkTarget.myDesigns => AppRoutes.screen18MyDesignsScreen,
      AppDeepLinkTarget.openDesign => AppRoutes.openDesignDeepLinkScreen,
      AppDeepLinkTarget.newDesign => AppRoutes.screen2NewDesignScreen,
      AppDeepLinkTarget.removeBackground =>
        AppRoutes.screen19RemoveBackgroundScreen,
      AppDeepLinkTarget.qrGenerator => AppRoutes.enhancedQrGeneratorScreen,
      AppDeepLinkTarget.subscription => AppRoutes.screen1SubcriptionScreen,
      AppDeepLinkTarget.playStore => AppRoutes.screen1HomeScreen,
    };
  }

  dynamic get arguments {
    return switch (target) {
      AppDeepLinkTarget.contestDetail when contestId != null && contestId! > 0 =>
        ContestDetailArgs(contestId: contestId!),
      AppDeepLinkTarget.contestGallery when contestId != null && contestId! > 0 =>
        contestId,
      AppDeepLinkTarget.contestWinners when contestId != null && contestId! > 0 =>
        contestId,
      AppDeepLinkTarget.contestMySubmissions
          when contestId != null && contestId! > 0 =>
        contestId,
      AppDeepLinkTarget.contestFeed => <String, dynamic>{
          if (contestId != null && contestId! > 0) 'contestId': contestId,
          if (submissionId != null && submissionId! > 0)
            'submissionId': submissionId,
        },
      AppDeepLinkTarget.openDesign when designId != null && designId! > 0 =>
        <String, dynamic>{'designId': designId},
      _ => null,
    };
  }
}

/// Parses https App Links and `musamimuk://` custom-scheme URIs.
class AppDeepLinkParser {
  const AppDeepLinkParser();

  AppDeepLink? parse(Uri uri) {
    final normalized = _normalize(uri);
    if (normalized == null) return null;

    final segments = normalized.pathSegments
        .where((s) => s.trim().isNotEmpty)
        .map((s) => s.trim().toLowerCase())
        .toList(growable: false);

    final queryContestId = _idFromQuery(normalized, const [
      'contest_id',
      'contestId',
      'contest',
    ]);
    final querySubmissionId = _idFromQuery(normalized, const [
      'submission_id',
      'submissionId',
      'share_id',
      'shareId',
    ]);
    final queryDesignId = _idFromQuery(normalized, const [
      'design_id',
      'designId',
    ]);

    if (segments.isEmpty) {
      if (querySubmissionId != null) {
        return AppDeepLink(
          target: AppDeepLinkTarget.contestFeed,
          contestId: queryContestId,
          submissionId: querySubmissionId,
          raw: uri,
        );
      }
      if (queryContestId != null) {
        return AppDeepLink(
          target: AppDeepLinkTarget.contestDetail,
          contestId: queryContestId,
          raw: uri,
        );
      }
      if (queryDesignId != null) {
        return AppDeepLink(
          target: AppDeepLinkTarget.openDesign,
          designId: queryDesignId,
          raw: uri,
        );
      }
      return AppDeepLink(target: AppDeepLinkTarget.home, raw: uri);
    }

    // Strip optional /open or /app prefix used by landing pages.
    var path = segments;
    if (path.isNotEmpty && (path.first == 'open' || path.first == 'app')) {
      path = path.sublist(1);
    }
    if (path.isEmpty) {
      return AppDeepLink(target: AppDeepLinkTarget.home, raw: uri);
    }

    final head = path.first;

    // Share / submission short links from backend.
    if (head == 'share' || head == 's' || head == 'submission') {
      final submissionId = path.length > 1
          ? int.tryParse(path[1])
          : querySubmissionId;
      final contestId = queryContestId ??
          (path.length > 3 && path[2] == 'contest' ? int.tryParse(path[3]) : null);
      if (submissionId != null && submissionId > 0) {
        return AppDeepLink(
          target: AppDeepLinkTarget.contestFeed,
          contestId: contestId,
          submissionId: submissionId,
          raw: uri,
        );
      }
    }

    if (head == 'contest' || head == 'contests') {
      return _parseContestPath(
        path: path,
        queryContestId: queryContestId,
        querySubmissionId: querySubmissionId,
        raw: uri,
      );
    }

    final module = _parseModule(
      head,
      path,
      queryContestId,
      querySubmissionId,
      queryDesignId,
    );
    if (module != null) return module.copyWithRaw(uri);

    // Fallback: query-only contest / submission deep links on any path.
    if (querySubmissionId != null) {
      return AppDeepLink(
        target: AppDeepLinkTarget.contestFeed,
        contestId: queryContestId,
        submissionId: querySubmissionId,
        raw: uri,
      );
    }
    if (queryContestId != null) {
      return AppDeepLink(
        target: AppDeepLinkTarget.contestDetail,
        contestId: queryContestId,
        raw: uri,
      );
    }
    if (queryDesignId != null) {
      return AppDeepLink(
        target: AppDeepLinkTarget.openDesign,
        designId: queryDesignId,
        raw: uri,
      );
    }
    return null;
  }

  AppDeepLink? _parseContestPath({
    required List<String> path,
    required int? queryContestId,
    required int? querySubmissionId,
    required Uri raw,
  }) {
    if (path.length == 1) {
      return AppDeepLink(
        target: AppDeepLinkTarget.contestList,
        contestId: queryContestId,
        submissionId: querySubmissionId,
        raw: raw,
      );
    }

    final second = path[1];
    if (second == 'feed') {
      return AppDeepLink(
        target: AppDeepLinkTarget.contestFeed,
        contestId: queryContestId,
        submissionId: querySubmissionId,
        raw: raw,
      );
    }

    final contestId = int.tryParse(second) ?? queryContestId;
    if (contestId == null || contestId <= 0) {
      return AppDeepLink(target: AppDeepLinkTarget.contestList, raw: raw);
    }

    if (path.length >= 3) {
      final action = path[2];
      if (action == 'feed') {
        final submissionId = path.length > 3
            ? int.tryParse(path[3])
            : querySubmissionId;
        return AppDeepLink(
          target: AppDeepLinkTarget.contestFeed,
          contestId: contestId,
          submissionId: submissionId,
          raw: raw,
        );
      }
      if (action == 'gallery' || action == 'submissions') {
        return AppDeepLink(
          target: AppDeepLinkTarget.contestGallery,
          contestId: contestId,
          raw: raw,
        );
      }
      if (action == 'winners' || action == 'winner') {
        return AppDeepLink(
          target: AppDeepLinkTarget.contestWinners,
          contestId: contestId,
          raw: raw,
        );
      }
      if (action == 'mine' || action == 'my' || action == 'my-submissions') {
        return AppDeepLink(
          target: AppDeepLinkTarget.contestMySubmissions,
          contestId: contestId,
          raw: raw,
        );
      }
      if (action == 'submission' || action == 'share') {
        final submissionId = path.length > 3
            ? int.tryParse(path[3])
            : querySubmissionId;
        return AppDeepLink(
          target: AppDeepLinkTarget.contestFeed,
          contestId: contestId,
          submissionId: submissionId,
          raw: raw,
        );
      }
    }

    return AppDeepLink(
      target: AppDeepLinkTarget.contestDetail,
      contestId: contestId,
      submissionId: querySubmissionId,
      raw: raw,
    );
  }

  AppDeepLink? _parseModule(
    String head,
    List<String> path,
    int? queryContestId,
    int? querySubmissionId,
    int? queryDesignId,
  ) {
    switch (head) {
      case 'home':
        return const AppDeepLink(target: AppDeepLinkTarget.home);
      case 'about':
      case 'help':
      case 'support':
        return const AppDeepLink(target: AppDeepLinkTarget.about);
      case 'feed':
        return AppDeepLink(
          target: AppDeepLinkTarget.contestFeed,
          contestId: queryContestId,
          submissionId: querySubmissionId,
        );
      case 'online-designs':
      case 'online_designs':
      case 'templates':
        return const AppDeepLink(target: AppDeepLinkTarget.onlineDesigns);
      case 'my-designs':
      case 'my_designs':
      case 'designs':
        return const AppDeepLink(target: AppDeepLinkTarget.myDesigns);
      case 'design':
        final designId = path.length > 1
            ? int.tryParse(path[1])
            : queryDesignId;
        if (designId != null && designId > 0) {
          return AppDeepLink(
            target: AppDeepLinkTarget.openDesign,
            designId: designId,
          );
        }
        return const AppDeepLink(target: AppDeepLinkTarget.myDesigns);
      case 'new':
      case 'new-design':
      case 'new_design':
      case 'editor':
        return const AppDeepLink(target: AppDeepLinkTarget.newDesign);
      case 'remove-background':
      case 'remove_background':
      case 'bg-remove':
        return const AppDeepLink(target: AppDeepLinkTarget.removeBackground);
      case 'qr':
      case 'qr-code':
      case 'qr_code':
        return const AppDeepLink(target: AppDeepLinkTarget.qrGenerator);
      case 'subscription':
      case 'premium':
      case 'upgrade':
        return const AppDeepLink(target: AppDeepLinkTarget.subscription);
      case 'play':
      case 'store':
      case 'install':
        return const AppDeepLink(target: AppDeepLinkTarget.playStore);
      default:
        // Nested module under /open/{module}
        if (path.length > 1) {
          return _parseModule(
            path[1],
            path.sublist(1),
            queryContestId,
            querySubmissionId,
            queryDesignId,
          );
        }
        return null;
    }
  }

  Uri? _normalize(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    if (scheme == AppLinkConfig.customScheme) {
      // musamimuk://contest/12 → path /contest/12
      if (uri.host.isNotEmpty) {
        final rebuiltPath = [
          uri.host,
          ...uri.pathSegments.where((s) => s.isNotEmpty),
        ].join('/');
        return uri.replace(
          scheme: AppLinkConfig.customScheme,
          host: '',
          path: '/$rebuiltPath',
        );
      }
      return uri;
    }
    if (scheme != 'https' && scheme != 'http') return null;
    final host = uri.host.toLowerCase();
    if (!AppLinkConfig.httpsHosts.contains(host)) return null;
    return uri;
  }

  int? _idFromQuery(Uri uri, List<String> keys) {
    for (final key in keys) {
      final raw = uri.queryParameters[key];
      final id = int.tryParse(raw ?? '');
      if (id != null && id > 0) return id;
    }
    return null;
  }
}

extension on AppDeepLink {
  AppDeepLink copyWithRaw(Uri raw) {
    return AppDeepLink(
      target: target,
      contestId: contestId,
      submissionId: submissionId,
      designId: designId,
      raw: raw,
    );
  }
}
