/// Mirrors `com.nawaf.meetingpoint.Model.Enum.MeetingStatus`.
enum MeetingStatus {
  created,
  locating,
  navigating,
  completed,
  cancelled;

  static MeetingStatus fromJson(dynamic value) {
    return MeetingStatus.values.firstWhere(
      (e) => e.name.toUpperCase() == value.toString().toUpperCase(),
      orElse: () => MeetingStatus.created,
    );
  }

  String toJson() => name.toUpperCase();
}
