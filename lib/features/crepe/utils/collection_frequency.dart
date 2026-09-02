/// A preset collection-frequency choice offered to researchers.
class CollectionFrequencyOption {
  final String label;

  /// Minimum seconds between captures. `0` means "collect every time".
  final int seconds;

  const CollectionFrequencyOption(this.label, this.seconds);
}

/// Presets shown in the collector create/edit frequency picker.
const List<CollectionFrequencyOption> kCollectionFrequencyOptions = [
  CollectionFrequencyOption('Every time', 0),
  CollectionFrequencyOption('Once per minute', 60),
  CollectionFrequencyOption('Once per 5 minutes', 300),
  CollectionFrequencyOption('Once per hour', 3600),
  CollectionFrequencyOption('Once per day', 86400),
];

/// Human-readable label for a stored interval, used on collector tiles.
/// `null`/`0` renders as "Every time".
String collectionFrequencyLabel(int? seconds) {
  final s = seconds ?? 0;
  for (final opt in kCollectionFrequencyOptions) {
    if (opt.seconds == s) return opt.label;
  }
  if (s % 86400 == 0) return 'Once per ${s ~/ 86400} days';
  if (s % 3600 == 0) return 'Once per ${s ~/ 3600} hours';
  if (s % 60 == 0) return 'Once per ${s ~/ 60} minutes';
  return 'Once per $s seconds';
}
