package com.nawaf.meetingpoint.Service;

import com.nawaf.meetingpoint.Api.NavigationException;
import com.nawaf.meetingpoint.DTO.Location.MemberLocationResponse;
import com.nawaf.meetingpoint.Navigation.Geo;
import com.nawaf.meetingpoint.Repository.GroupMemberRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.event.TransactionalEventListener;

import java.util.*;

@Service
@RequiredArgsConstructor
@Slf4j
public class LocationBroadcastService {
    private final LocationService locations;
    private final RealtimeEventPublisher publisher;
    private final GroupMemberRepository members;
    private final Map<Integer, Map<Integer, MemberLocationResponse>> published = new HashMap<>();
    private final Map<Integer, Map<Integer, String>> availability = new HashMap<>();

    @TransactionalEventListener
    public synchronized void updated(LocationService.LocationChanged event) {
        // Do not acquire another database connection while the committing transaction
        // still owns its connection. Availability snapshots are handled by polling.
        try {
            publishIfChanged(event.location());
        } catch (RuntimeException e) {
            log.warn("Location saved but broadcast failed for group {}", event.location().groupId(), e);
        }
    }

    @Scheduled(fixedDelayString = "${navigation.location-broadcast-interval-ms:10000}")
    public void refreshAvailability() {
        Set<Integer> ids = new HashSet<>(members.findSharingGroupIds());
        synchronized (this) {
            ids.addAll(published.keySet());
            ids.addAll(availability.keySet());
        }
        for (Integer id : ids) {
            try {
                refresh(id);
            } catch (NavigationException e) {
                synchronized (this) {
                    published.remove(id);
                    availability.remove(id);
                }
            } catch (RuntimeException e) {
                log.warn("Location availability broadcast failed for group {}", id, e);
            }
        }
    }

    private void refresh(Integer groupId) {
        List<MemberLocationResponse> current = locations.getGroupLocations(groupId);
        publishSnapshot(groupId, current);
    }

    private synchronized void publishSnapshot(Integer groupId, List<MemberLocationResponse> snapshot) {
        // A newer commit may have published while the database snapshot was read.
        Map<Integer, MemberLocationResponse> latest = published.getOrDefault(groupId, Map.of());
        List<MemberLocationResponse> current = snapshot.stream().map(location -> {
            MemberLocationResponse known = latest.get(location.userId());
            return known != null && known.updatedAt() != null && location.updatedAt() != null
                    && known.updatedAt().isAfter(location.updatedAt()) ? known : location;
        }).toList();
        Map<Integer, String> statuses = new HashMap<>();
        for (MemberLocationResponse location : current) {
            publishIfChanged(location);
            statuses.put(location.userId(), location.status());
        }
        if (!statuses.equals(availability.get(groupId))) {
            publisher.publishLocations(groupId, current);
            availability.put(groupId, Map.copyOf(statuses));
        }
        Map<Integer, MemberLocationResponse> previous = published.get(groupId);
        if (previous != null) previous.keySet().retainAll(statuses.keySet());
        if (current.stream().allMatch(p -> p.status().equals("MISSING"))) {
            published.remove(groupId);
            availability.remove(groupId);
        }
    }

    private void publishIfChanged(MemberLocationResponse location) {
        Map<Integer, MemberLocationResponse> group = published.computeIfAbsent(location.groupId(), id -> new HashMap<>());
        MemberLocationResponse previous = group.get(location.userId());
        // After-commit callbacks from concurrent transactions may arrive out of order.
        if (previous != null && previous.updatedAt() != null && location.updatedAt() != null
                && location.updatedAt().isBefore(previous.updatedAt())) return;
        if (material(previous, location)) {
            publisher.publishLocation(location);
            group.put(location.userId(), location);
        }
    }

    private boolean material(MemberLocationResponse a, MemberLocationResponse b) {
        if (a == null || !a.status().equals(b.status())) return true;
        if (!b.status().equals("ACTIVE")) return false;
        return Geo.meters(a.latitude(), a.longitude(), b.latitude(), b.longitude()) >= 1
                || !Objects.equals(a.accuracyMeters(), b.accuracyMeters())
                || b.updatedAt().isAfter(a.updatedAt().plusSeconds(30));
    }
}
