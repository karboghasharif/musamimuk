/// Whether [tier] from the design API should show the premium badge asset.
bool isPremiumDesignTier(String? tier) {
  if (tier == null || tier.trim().isEmpty) return false;
  final normalized = tier.trim().toLowerCase().replaceAll('-', '_');
  if (normalized == 'premium') return true;
  return normalized.startsWith('premium_');
}
