/// Auth gate for contest feed like/share actions.
enum ContestFeedSocialAccess { allowed, loginRequired, upgradeRequired }

/// Resolves whether a user can like/share on the contest feed.
///
/// Anonymous users must sign in; guest accounts must upgrade.
ContestFeedSocialAccess resolveContestFeedSocialAccess({
  required bool isLoggedIn,
  required bool isGuestAccount,
}) {
  if (!isLoggedIn) return ContestFeedSocialAccess.loginRequired;
  if (isGuestAccount) return ContestFeedSocialAccess.upgradeRequired;
  return ContestFeedSocialAccess.allowed;
}
