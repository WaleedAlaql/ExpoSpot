/// Mirrors `com.nawaf.meetingpoint.Model.Enum.MemberStatus`.
enum MemberStatus {
  idle,
  navigating,
  arrived;

  static MemberStatus fromJson(dynamic value) {
    return MemberStatus.values.firstWhere(
      (e) => e.name.toUpperCase() == value.toString().toUpperCase(),
      orElse: () => MemberStatus.idle,
    );
  }

  String toJson() => name.toUpperCase();
}
