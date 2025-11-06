/// Represents the user's status with the current terms of use
class Terms {
  final int? currentTermsId;
  final bool hasAcceptedCurrentTerms;

  const Terms({
    required this.hasAcceptedCurrentTerms,
    this.currentTermsId,
  });
}
