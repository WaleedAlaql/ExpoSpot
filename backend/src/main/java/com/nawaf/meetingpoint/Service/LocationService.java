package com.nawaf.meetingpoint.Service;

import com.nawaf.meetingpoint.Api.NavigationException;
import com.nawaf.meetingpoint.DTO.Location.*;
import com.nawaf.meetingpoint.DTO.Navigation.ParticipantLocationDTO;
import com.nawaf.meetingpoint.Model.GroupMember;
import com.nawaf.meetingpoint.Navigation.Geo;
import com.nawaf.meetingpoint.Repository.*;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.*;
import java.time.temporal.ChronoUnit;
import java.util.List;

@Service
public class LocationService {
    private final GroupMemberRepository members;
    private final GroupRepository groups;
    private final ApplicationEventPublisher events;
    private final long freshnessSeconds;
    public LocationService(GroupMemberRepository members,GroupRepository groups,ApplicationEventPublisher events,
            @Value("${navigation.location-freshness-seconds:120}") long freshnessSeconds) {
        if (freshnessSeconds<=0) throw new IllegalArgumentException("Location freshness must be positive");
        this.members=members;this.groups=groups;this.events=events;this.freshnessSeconds=freshnessSeconds;
    }
    @Transactional
    public MemberLocationResponse update(LocationUpdateRequest request) {
        if (request==null) throw new NavigationException(400,"Location is required");
        validateIds(request.groupId(),request.userId()); Geo.validate(request.latitude(),request.longitude());
        if (request.accuracyMeters()!=null && (!Double.isFinite(request.accuracyMeters()) || request.accuracyMeters()<0))
            throw new NavigationException(400,"Invalid accuracyMeters");
        Instant now=Instant.now();
        Instant timestamp=(request.updatedAt()==null ? now : request.updatedAt()).truncatedTo(ChronoUnit.MICROS);
        validateTime(timestamp,now);
        GroupMember member=members.findForLocationUpdate(request.groupId(),request.userId())
            .orElseThrow(() -> new NavigationException(404,"Group membership not found"));
        if (member.getLastLocationAt()!=null && !timestamp.isAfter(member.getLastLocationAt().toInstant(ZoneOffset.UTC)))
            return response(member,now);
        member.setLatitude(request.latitude());member.setLongitude(request.longitude());member.setAccuracyMeters(request.accuracyMeters());
        member.setLastLocationAt(LocalDateTime.ofInstant(timestamp,ZoneOffset.UTC));member.setLocationSharingEnabled(true);
        members.save(member);
        MemberLocationResponse result=response(member,now);
        events.publishEvent(new LocationChanged(result));
        return result;
    }
    @Transactional(readOnly=true)
    public List<MemberLocationResponse> getGroupLocations(Integer groupId) {
        if (groupId==null || groupId<=0) throw new NavigationException(400,"Invalid group ID");
        if (!groups.existsById(groupId)) throw new NavigationException(404,"Group not found");
        Instant now=Instant.now();
        return members.findByGroup_IdOrderByUser_Id(groupId).stream().map(m -> response(m,now)).toList();
    }
    @Transactional(readOnly=true)
    public ParticipantLocationDTO resolve(Integer groupId, ParticipantLocationDTO input) {
        return resolveParticipants(groupId, List.of(input)).getFirst();
    }

    @Transactional(readOnly=true)
    public List<ParticipantLocationDTO> resolveParticipants(Integer groupId, List<ParticipantLocationDTO> inputs) {
        java.util.Map<Integer, MemberLocationResponse> stored = new java.util.HashMap<>();
        if (groupId != null) getGroupLocations(groupId).forEach(p -> stored.put(p.userId(), p));
        Instant now = Instant.now();
        return inputs.stream().map(input -> {
            if (groupId != null && !stored.containsKey(input.userId()))
                throw new NavigationException(404, "Group membership not found for participant " + input.userId());
            if (input.latitude() == null && input.longitude() == null) {
                if (groupId == null) throw new NavigationException(400, "groupId is required for stored locations");
                MemberLocationResponse found = stored.get(input.userId());
                if (!found.status().equals("ACTIVE"))
                    throw new NavigationException(409, found.status() + " location for participant " + input.userId());
                return new ParticipantLocationDTO(input.userId(), found.latitude(), found.longitude(), found.updatedAt());
            }
            Geo.validate(input.latitude(), input.longitude());
            if (input.updatedAt() == null)
                throw new NavigationException(400, "updatedAt is required for participant GPS coordinates");
            validateTime(input.updatedAt(), now);
            if (stale(input.updatedAt(), now))
                throw new NavigationException(409, "STALE location for participant " + input.userId());
            return input;
        }).toList();
    }
    public void requireMembership(Integer groupId,Integer userId) {
        validateIds(groupId,userId);
        if (!members.existsByGroup_IdAndUser_Id(groupId,userId)) throw new NavigationException(404,"Group membership not found");
    }
    private void validateIds(Integer groupId,Integer userId) {
        if (groupId==null || userId==null || groupId<=0 || userId<=0) throw new NavigationException(400,"Invalid group or user ID");
    }
    private void validateTime(Instant timestamp,Instant now) {
        if (timestamp.isAfter(now)) throw new NavigationException(400,"Location timestamp cannot be in the future");
    }
    private boolean stale(Instant timestamp,Instant now) { return timestamp.isBefore(now.minusSeconds(freshnessSeconds)); }
    private MemberLocationResponse response(GroupMember m,Instant now) {
        Instant time=m.getLastLocationAt()==null ? null : m.getLastLocationAt().toInstant(ZoneOffset.UTC);
        boolean missing=!Boolean.TRUE.equals(m.getLocationSharingEnabled()) || time==null || m.getLatitude()==null || m.getLongitude()==null;
        return new MemberLocationResponse(m.getGroup().getId(),m.getUser().getId(),missing?null:m.getLatitude(),missing?null:m.getLongitude(),
            missing?null:m.getAccuracyMeters(),missing?"MISSING":stale(time,now)?"STALE":"ACTIVE",missing?null:time);
    }
    public record LocationChanged(MemberLocationResponse location) {}
}
