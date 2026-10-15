package com.nawaf.meetingpoint.Service;

import com.nawaf.meetingpoint.DTO.Location.MemberLocationResponse;
import com.nawaf.meetingpoint.DTO.Meeting.MeetingStatusResponse;
import com.nawaf.meetingpoint.DTO.Navigation.*;
import lombok.RequiredArgsConstructor;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import java.time.Instant;
import java.util.List;

@Service
@RequiredArgsConstructor
public class RealtimeEventPublisher {
    private final SimpMessagingTemplate messaging;
    public void publishLocation(MemberLocationResponse location) {
        send("/topic/groups/"+location.groupId()+"/locations","LOCATION_UPDATED",location.groupId(),null,location);
    }
    public void publishLocations(Integer groupId,List<MemberLocationResponse> locations) {
        send("/topic/groups/"+groupId+"/locations","LOCATIONS_CHANGED",groupId,null,locations);
    }
    public void publishRecommendation(Integer groupId,Integer meetingId,MeetingOptimizationResponse recommendation) {
        navigation("MEETING_POINT_RECOMMENDED",groupId,meetingId,recommendation);
    }
    public void publishRoutes(Integer groupId,Integer meetingId,List<ParticipantRouteResponse> routes) {
        navigation("NAVIGATION_UPDATED",groupId,meetingId,routes);
    }
    public void publishMeetingStatus(Integer groupId,MeetingStatusResponse status) {
        send("/topic/meetings/"+status.meetingId()+"/updates","MEETING_STATUS_UPDATED",groupId,status.meetingId(),status);
    }
    private <T> void navigation(String event,Integer groupId,Integer meetingId,T data) {
        if (groupId==null && meetingId==null) throw new IllegalArgumentException("Navigation event requires a context");
        if (groupId!=null) send("/topic/groups/"+groupId+"/navigation",event,groupId,meetingId,data);
        if (meetingId!=null) send("/topic/meetings/"+meetingId+"/navigation",event,groupId,meetingId,data);
    }
    private <T> void send(String topic,String event,Integer groupId,Integer meetingId,T data) {
        messaging.convertAndSend(topic,new RealtimeEventDTO<>(event,groupId,meetingId,Instant.now(),data));
    }
}
