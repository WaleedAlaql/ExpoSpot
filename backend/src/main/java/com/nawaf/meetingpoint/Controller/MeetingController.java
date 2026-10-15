package com.nawaf.meetingpoint.Controller;

import com.nawaf.meetingpoint.Model.Meeting;
import com.nawaf.meetingpoint.Service.MeetingService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/meetings")
@RequiredArgsConstructor
public class MeetingController {

    private final MeetingService meetingService;

    // 1. Fetch All Meetings
    @GetMapping("/get")
    public ResponseEntity<List<Meeting>> getMeetings() {
        return ResponseEntity.ok(meetingService.getMeetings());
    }

    // 2. Fetch Single Meeting
    @GetMapping("/get/{meetingId}")
    public ResponseEntity<Meeting> getMeeting(@PathVariable Integer meetingId) {
        return ResponseEntity.ok(meetingService.getMeeting(meetingId));
    }

    // 3. Create Meeting
    @PostMapping("/create/{groupId}/{userId}")
    public ResponseEntity<Meeting> createMeeting(
            @PathVariable Integer groupId,
            @PathVariable Integer userId) {
        Meeting meeting = meetingService.createMeeting(groupId, userId);
        return ResponseEntity.status(HttpStatus.CREATED).body(meeting);
    }

    // 4. Start Locating Phase
    @PutMapping("/start-locating/{meetingId}/{userId}")
    public ResponseEntity<String> startLocating(
            @PathVariable Integer meetingId,
            @PathVariable Integer userId) {
        meetingService.startLocating(meetingId, userId);
        return ResponseEntity.ok("Meeting status updated to LOCATING");
    }

    // 5. Calculate & Save Optimal Meeting Point
    @PutMapping("/calculate-point/{meetingId}/{userId}")
    public ResponseEntity<Meeting> calculateMeetingPoint(
            @PathVariable Integer meetingId,
            @PathVariable Integer userId) {
        return ResponseEntity.ok(meetingService.calculateAndSaveMeetingPoint(meetingId, userId));
    }

    // 6. Recalculate Meeting Point
    @PutMapping("/recalculate-point/{meetingId}/{userId}")
    public ResponseEntity<Meeting> recalculateMeetingPoint(
            @PathVariable Integer meetingId,
            @PathVariable Integer userId) {
        return ResponseEntity.ok(meetingService.recalculateMeetingPoint(meetingId, userId));
    }

    // 7. Manually Set Custom Meeting Point
    @PutMapping("/set-point/{meetingId}/{userId}")
    public ResponseEntity<Meeting> setMeetingPoint(
            @PathVariable Integer meetingId,
            @PathVariable Integer userId,
            @RequestParam String pointName,
            @RequestParam Double lat,
            @RequestParam Double lng,
            @RequestParam Double maxEta) {
        return ResponseEntity.ok(meetingService.setMeetingPoint(meetingId, pointName, lat, lng, maxEta, userId));
    }

    // 8. Start Navigation Phase
    @PutMapping("/start-navigation/{meetingId}/{userId}")
    public ResponseEntity<String> startNavigation(
            @PathVariable Integer meetingId,
            @PathVariable Integer userId) {
        meetingService.startNavigation(meetingId, userId);
        return ResponseEntity.ok("Meeting status updated to NAVIGATING");
    }

    // 9. Confirm Arrival
    @PostMapping("/confirm-arrival/{groupId}/{userId}")
    public ResponseEntity<String> confirmArrival(
            @PathVariable Integer groupId,
            @PathVariable Integer userId) {
        meetingService.confirmArrival(groupId, userId);
        return ResponseEntity.ok("Participant arrival confirmed");
    }

    // 10. Complete Meeting
    @PutMapping("/complete/{meetingId}/{userId}")
    public ResponseEntity<String> completeMeeting(
            @PathVariable Integer meetingId,
            @PathVariable Integer userId) {
        meetingService.completeMeeting(meetingId, userId);
        return ResponseEntity.ok("Meeting marked as COMPLETED");
    }

    // 11. Cancel Meeting
    @PutMapping("/cancel/{meetingId}/{userId}")
    public ResponseEntity<String> cancelMeeting(
            @PathVariable Integer meetingId,
            @PathVariable Integer userId) {
        meetingService.cancelMeeting(meetingId, userId);
        return ResponseEntity.ok("Meeting status updated to CANCELLED");
    }
}