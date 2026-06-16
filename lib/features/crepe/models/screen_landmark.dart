/// A static text label selected by the researcher to scope a collector
/// to a specific screen. Maps to the plugin's `SCREEN_HAS_TEXT` relation.
class ScreenLandmark {
  final int entityId;
  final String text;

  const ScreenLandmark({required this.entityId, required this.text});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScreenLandmark && other.text == text;

  @override
  int get hashCode => text.hashCode;

  @override
  String toString() => 'ScreenLandmark(entityId: $entityId, text: "$text")';
}
