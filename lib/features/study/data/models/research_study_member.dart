/// Represents the membership of a user to a particular research group
class ResearchStudyMember {
  final int membershipId;
  final int userId;
  final String firstName;
  final String lastName;
  final String role; // "researcher" | "participant"
  final DateTime enrolledAt;
  final DateTime? unenrolledAt; // null if the participant is active
  final String retentionPref; // "delete_all" | "keep_collected"

  const ResearchStudyMember({
    required this.membershipId,
    required this.userId,
    required this.role,
    required this.enrolledAt,
    required this.firstName,
    required this.lastName,
    this.unenrolledAt,
    required this.retentionPref,
  });

  bool get isActive => unenrolledAt == null;

  String get fullName => '$firstName $lastName';

  bool get isResearcher => role == 'researcher';

  factory ResearchStudyMember.fromJson(Map<String, dynamic> j) =>
      ResearchStudyMember(
        membershipId: j['membership_id'] as int,
        userId: j['user_id'] as int,
        firstName: (j['first_name'] ?? '') as String,
        lastName: (j['last_name'] ?? '') as String,
        role: j['role'] as String,
        enrolledAt: DateTime.parse(j['enrolled_at'] as String),
        unenrolledAt: j['unenrolled_at'] != null
            ? DateTime.parse(j['unenrolled_at'])
            : null,
        retentionPref: j['retention_pref_on_unenroll'] as String,
      );

  ResearchStudyMember copyWith({
    int? membershipId,
    int? userId,
    String? firstName,
    String? lastName,
    String? role,
    DateTime? enrolledAt,
    DateTime? unenrolledAt,
    String? retentionPref,
  }) {
    return ResearchStudyMember(
      membershipId: membershipId ?? this.membershipId,
      userId: userId ?? this.userId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      role: role ?? this.role,
      enrolledAt: enrolledAt ?? this.enrolledAt,
      unenrolledAt: unenrolledAt ?? this.unenrolledAt,
      retentionPref: retentionPref ?? this.retentionPref,
    );
  }
}
