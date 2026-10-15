import 'package:expo_spot/features/group/data/mock_expo_data.dart';
import 'package:expo_spot/features/group/models/group_model.dart';
import 'package:expo_spot/features/meeting/models/meeting_model.dart';
import 'package:expo_spot/features/meeting/models/meeting_status.dart';
import 'package:expo_spot/features/meeting/models/reunification_point_model.dart';
import 'package:expo_spot/features/user/models/user_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// In-memory session shaped like future API responses (no HTTP yet).
class MockGroupRepository {
  GroupModel? _activeGroup;
  MeetingModel? _activeMeeting;
  ReunificationPointModel? _selectedPoint;

  UserModel get currentUser => MockExpoData.currentUser;

  GroupModel? get activeGroup => _activeGroup;

  MeetingModel? get activeMeeting => _activeMeeting;

  ReunificationPointModel? get selectedReunificationPoint => _selectedPoint;

  List<ReunificationPointModel> get venuePoints =>
      MockExpoData.reunificationPoints;

  void resetToSolo() {
    _activeGroup = null;
    _activeMeeting = null;
    _selectedPoint = null;
  }

  /// Full capstone demo: host + 4 friends (matches join sheet code `EXPO-7K2M`).
  void loadDemoPreviewGroup() {
    _activeGroup = MockExpoData.demoGroup(inviteCode: 'EXPO-7K2M');
    _activeMeeting = _activeGroup!.meetings.isNotEmpty
        ? _activeGroup!.meetings.first
        : MeetingModel(
            id: 1,
            groupId: _activeGroup!.id,
            createdById: currentUser.id,
            status: MeetingStatus.created,
            createdAt: DateTime.now(),
          );
    _selectedPoint = null;
  }

  GroupModel createGroup({required String name, required String inviteCode}) {
    _activeGroup = MockExpoData.soloHostGroup(inviteCode: inviteCode).copyWith(
      name: name.isEmpty ? 'مجموعة إكسبو' : name,
    );
    _activeMeeting = MeetingModel(
      id: 1,
      groupId: _activeGroup!.id,
      createdById: currentUser.id,
      status: MeetingStatus.created,
      createdAt: DateTime.now(),
    );
    _selectedPoint = null;
    return _activeGroup!;
  }

  void addMemberFromMock(int stagedIndex) {
    final group = _activeGroup;
    if (group == null) return;

    final staged = MockExpoData.stagedJoins(group.id);
    if (stagedIndex < 0 || stagedIndex >= staged.length) return;

    final incoming = staged[stagedIndex];
    if (group.members.any((m) => m.userId == incoming.userId)) return;

    _activeGroup = group.copyWith(
      members: [...group.members, incoming],
    );
  }

  void applyReunificationPoint(ReunificationPointModel point) {
    _selectedPoint = point;
    final meeting = _activeMeeting;
    if (meeting == null) return;

    _activeMeeting = meeting.copyWith(
      status: MeetingStatus.navigating,
      meetingPointName: point.name,
      meetingLatitude: point.latitude,
      meetingLongitude: point.longitude,
      maxEtaSeconds: 900,
    );
  }

  void cycleReunificationPoint(int index) {
    final points = venuePoints;
    if (points.isEmpty) return;
    applyReunificationPoint(points[index % points.length]);
  }
}

final mockGroupRepositoryProvider = Provider<MockGroupRepository>((ref) {
  return MockGroupRepository();
});

final currentUserModelProvider = Provider<UserModel>((ref) {
  return ref.watch(mockGroupRepositoryProvider).currentUser;
});

final activeGroupModelProvider = Provider<GroupModel?>((ref) {
  return ref.watch(mockGroupRepositoryProvider).activeGroup;
});

final activeMeetingModelProvider = Provider<MeetingModel?>((ref) {
  return ref.watch(mockGroupRepositoryProvider).activeMeeting;
});
