
package com.nawaf.meetingpoint.Service;

import com.nawaf.meetingpoint.Api.ApiException;
import com.nawaf.meetingpoint.Model.Group;
import com.nawaf.meetingpoint.Model.Meeting;
import com.nawaf.meetingpoint.Model.User;
import com.nawaf.meetingpoint.Model.Enum.MeetingStatus;
import com.nawaf.meetingpoint.Repository.GroupRepository;
import com.nawaf.meetingpoint.Repository.MeetingRepository;
import com.nawaf.meetingpoint.Repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class MeetingService {

    private final MeetingRepository meetingRepository;
    private final GroupRepository groupRepository;
    private final UserRepository userRepository;

    public List<Meeting> getMeetings() {
        return meetingRepository.findAll();
    }

    public Meeting getMeeting(Integer meetingId) {
        return meetingRepository.findById(meetingId)
                .orElseThrow(() ->
                        new ApiException("Meeting not found"));
    }

    public Meeting createMeeting(Integer groupId, Integer userId) {
        Group group = groupRepository.findById(groupId)
                .orElseThrow(() ->
                        new ApiException("Group not found"));

        User user = userRepository.findById(userId)
                .orElseThrow(() ->
                        new ApiException("User not found"));

        Meeting meeting = new Meeting();
        meeting.setGroup(group);
        meeting.setCreatedBy(user);
        meeting.setStatus(MeetingStatus.CREATED);

        return meetingRepository.save(meeting);
    }

    public void startLocating(Integer meetingId) {
        Meeting meeting = getMeeting(meetingId);

        if (meeting.getStatus() != MeetingStatus.CREATED) {
            throw new ApiException("Meeting must be CREATED");
        }

        meeting.setStatus(MeetingStatus.LOCATING);
        meetingRepository.save(meeting);
    }

    public void startNavigation(Integer meetingId) {
        Meeting meeting = getMeeting(meetingId);

        if (meeting.getStatus() != MeetingStatus.LOCATING) {
            throw new ApiException("Meeting must be LOCATING");
        }

        if (meeting.getMeetingLatitude() == null ||
                meeting.getMeetingLongitude() == null) {
            throw new ApiException("Meeting point not selected");
        }

        meeting.setStatus(MeetingStatus.NAVIGATING);
        meetingRepository.save(meeting);
    }

    public void completeMeeting(Integer meetingId) {
        Meeting meeting = getMeeting(meetingId);

        if (meeting.getStatus() != MeetingStatus.NAVIGATING) {
            throw new ApiException("Meeting must be NAVIGATING");
        }

        meeting.setStatus(MeetingStatus.COMPLETED);
        meeting.setCompletedAt(LocalDateTime.now());

        meetingRepository.save(meeting);
    }

    public void cancelMeeting(Integer meetingId) {
        Meeting meeting = getMeeting(meetingId);

        if (meeting.getStatus() == MeetingStatus.COMPLETED ||
                meeting.getStatus() == MeetingStatus.CANCELLED) {
            throw new ApiException("Meeting cannot be cancelled");
        }

        meeting.setStatus(MeetingStatus.CANCELLED);
        meetingRepository.save(meeting);
    }
}
