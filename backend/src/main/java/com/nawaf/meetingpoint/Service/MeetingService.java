package com.nawaf.meetingpoint.Service;

import com.nawaf.meetingpoint.Api.ApiException;
import com.nawaf.meetingpoint.DTO.Navigation.MeetingOptimizationRequest;
import com.nawaf.meetingpoint.DTO.Navigation.MeetingOptimizationResponse;
import com.nawaf.meetingpoint.DTO.Navigation.ParticipantLocationDTO;
import com.nawaf.meetingpoint.Model.Enum.MeetingStatus;
import com.nawaf.meetingpoint.Model.Enum.MemberStatus;
import com.nawaf.meetingpoint.Model.Group;
import com.nawaf.meetingpoint.Model.GroupMember;
import com.nawaf.meetingpoint.Model.Meeting;
import com.nawaf.meetingpoint.Model.User;
import com.nawaf.meetingpoint.Repository.GroupMemberRepository;
import com.nawaf.meetingpoint.Repository.GroupRepository;
import com.nawaf.meetingpoint.Repository.MeetingRepository;
import com.nawaf.meetingpoint.Repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class MeetingService {

    private final MeetingRepository meetingRepository;
    private final GroupRepository groupRepository;
    private final UserRepository userRepository;
    private final GroupMemberRepository groupMemberRepository;
    private final MeetingOptimizerService meetingOptimizerService;

    // 1. Fetch All Meetings
    public List<Meeting> getMeetings() {
        return meetingRepository.findAll();
    }

    // 2. Fetch Single Meeting
    public Meeting getMeeting(Integer meetingId) {
        return meetingRepository.findById(meetingId)
                .orElseThrow(() -> new ApiException("Meeting not found"));
    }

    // 3. Create Meeting
    @Transactional
    public Meeting createMeeting(Integer groupId, Integer userId) {
        Group group = groupRepository.findById(groupId)
                .orElseThrow(() -> new ApiException("Group not found"));

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ApiException("User not found"));

        boolean isMember = groupMemberRepository.existsByGroup_IdAndUser_Id(groupId, userId);
        if (!isMember) {
            throw new ApiException("User is not a member of this group");
        }

        Meeting meeting = new Meeting();
        meeting.setGroup(group);
        meeting.setCreatedBy(user);
        meeting.setStatus(MeetingStatus.CREATED);

        return meetingRepository.save(meeting);
    }

    // 4. Start Locating Phase & Reset Member Arrival Statuses
    @Transactional
    public void startLocating(Integer meetingId, Integer userId) {
        Meeting meeting = getMeeting(meetingId);
        validateUserPermission(meeting, userId);

        if (meeting.getStatus() != MeetingStatus.CREATED) {
            throw new ApiException("Meeting must be in CREATED status to start locating");
        }

        meeting.setStatus(MeetingStatus.LOCATING);

        // Reset arrival status for active group members for this meeting session
        List<GroupMember> activeMembers = groupMemberRepository
                .findByGroup_IdAndLocationSharingEnabledTrue(meeting.getGroup().getId());

        for (GroupMember member : activeMembers) {
            member.setStatus(MemberStatus.PENDING);
        }
        groupMemberRepository.saveAll(activeMembers);

        meetingRepository.save(meeting);
    }

    // 5. Calculate and Save Optimal Meeting Point via Optimizer Service
    @Transactional
    public Meeting calculateAndSaveMeetingPoint(Integer meetingId, Integer userId) {
        Meeting meeting = getMeeting(meetingId);
        validateUserPermission(meeting, userId);

        if (meeting.getStatus() != MeetingStatus.LOCATING) {
            throw new ApiException("Meeting must be in LOCATING status to calculate meeting point");
        }

        List<GroupMember> activeMembers = groupMemberRepository
                .findByGroup_IdAndLocationSharingEnabledTrue(meeting.getGroup().getId());

        if (activeMembers.isEmpty()) {
            throw new ApiException("No members are currently sharing location");
        }

        // Map active group members to optimization DTOs
        List<ParticipantLocationDTO> participants = activeMembers.stream()
                .map(member -> new ParticipantLocationDTO(
                        member.getUser().getId(),
                        member.getLatitude(),
                        member.getLongitude(),
                        java.time.Instant.now() // <--- Added the 4th argument here
                ))
                .toList();

        MeetingOptimizationRequest request = new MeetingOptimizationRequest(
                meeting.getGroup().getId(),
                participants
        );

        // Run calculation
        MeetingOptimizationResponse response = meetingOptimizerService.optimize(request);

        // Update meeting details
        meeting.setMeetingLatitude(response.meetingPoint().latitude());
        meeting.setMeetingLongitude(response.meetingPoint().longitude());
        meeting.setMeetingPointName(response.meetingPoint().name());
        meeting.setMaxEtaSeconds(response.maxEtaSeconds());

        return meetingRepository.save(meeting);
    }

    // 6. Recalculate Meeting Point During Active Meeting
    @Transactional
    public Meeting recalculateMeetingPoint(Integer meetingId, Integer userId) {
        Meeting meeting = getMeeting(meetingId);
        validateUserPermission(meeting, userId);

        if (meeting.getStatus() != MeetingStatus.LOCATING && meeting.getStatus() != MeetingStatus.NAVIGATING) {
            throw new ApiException("Cannot recalculate meeting point for inactive meetings");
        }

        return calculateAndSaveMeetingPoint(meetingId, userId);
    }

    // 7. Manually Set Custom Meeting Point
    @Transactional
    public Meeting setMeetingPoint(Integer meetingId, String pointName, Double lat, Double lng, Double maxEta, Integer userId) {
        Meeting meeting = getMeeting(meetingId);
        validateUserPermission(meeting, userId);

        meeting.setMeetingPointName(pointName);
        meeting.setMeetingLatitude(lat);
        meeting.setMeetingLongitude(lng);
        meeting.setMaxEtaSeconds(maxEta);

        return meetingRepository.save(meeting);
    }

    // 8. Start Navigation Phase
    @Transactional
    public void startNavigation(Integer meetingId, Integer userId) {
        Meeting meeting = getMeeting(meetingId);
        validateUserPermission(meeting, userId);

        if (meeting.getStatus() != MeetingStatus.LOCATING) {
            throw new ApiException("Meeting must be in LOCATING status to start navigation");
        }

        if (meeting.getMeetingLatitude() == null || meeting.getMeetingLongitude() == null) {
            throw new ApiException("Meeting point has not been calculated or set yet");
        }

        meeting.setStatus(MeetingStatus.NAVIGATING);
        meetingRepository.save(meeting);
    }

    // 9. Confirm Individual Member Arrival
    @Transactional
    public void confirmArrival(Integer groupId, Integer userId) {
        GroupMember member = groupMemberRepository.findByGroup_IdAndUser_Id(groupId, userId)
                .orElseThrow(() -> new ApiException("Group member record not found"));

        member.setStatus(MemberStatus.ARRIVED);
        groupMemberRepository.save(member);
    }

    // 10. Complete Meeting (Validates that participants have arrived)
    @Transactional
    public void completeMeeting(Integer meetingId, Integer userId) {
        Meeting meeting = getMeeting(meetingId);
        validateUserPermission(meeting, userId);

        if (meeting.getStatus() != MeetingStatus.NAVIGATING) {
            throw new ApiException("Meeting must be in NAVIGATING status to complete");
        }

        // Optional Arrival Check: Verify all active participants reached destination
        List<GroupMember> activeMembers = groupMemberRepository
                .findByGroup_IdAndLocationSharingEnabledTrue(meeting.getGroup().getId());

        boolean allArrived = activeMembers.stream()
                .allMatch(m -> m.getStatus() == MemberStatus.ARRIVED);

        if (!allArrived) {
            throw new ApiException("Cannot complete meeting: Not all active participants have arrived");
        }

        meeting.setStatus(MeetingStatus.COMPLETED);
        meeting.setCompletedAt(LocalDateTime.now());

        meetingRepository.save(meeting);
    }

    // 11. Cancel Meeting
    @Transactional
    public void cancelMeeting(Integer meetingId, Integer userId) {
        Meeting meeting = getMeeting(meetingId);
        validateUserPermission(meeting, userId);

        if (meeting.getStatus() == MeetingStatus.COMPLETED || meeting.getStatus() == MeetingStatus.CANCELLED) {
            throw new ApiException("Completed or already cancelled meetings cannot be cancelled");
        }

        meeting.setStatus(MeetingStatus.CANCELLED);
        meetingRepository.save(meeting);
    }

    // Helper Authorization Method
    private void validateUserPermission(Meeting meeting, Integer userId) {
        boolean isCreator = meeting.getCreatedBy().getId().equals(userId);
        boolean isGroupOwner = meeting.getGroup().getOwner().getId().equals(userId);

        if (!isCreator && !isGroupOwner) {
            throw new ApiException("Only the meeting creator or group owner can perform this action");
        }
    }
}