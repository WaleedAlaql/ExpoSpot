
package com.nawaf.meetingpoint.Controller;

import com.nawaf.meetingpoint.Api.ApiResponse;
import com.nawaf.meetingpoint.Model.Meeting;
import com.nawaf.meetingpoint.Service.MeetingService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/meeting")
@RequiredArgsConstructor
public class MeetingController {

    private final MeetingService meetingService;

    @GetMapping("/get-all")
    public ResponseEntity<List<Meeting>> getMeetings() {
        return ResponseEntity.ok(meetingService.getMeetings());
    }

    @GetMapping("/get/{id}")
    public ResponseEntity<Meeting> getMeeting(
            @PathVariable Integer id) {

        return ResponseEntity.ok(meetingService.getMeeting(id));
    }

    @PostMapping("/create/{groupId}/{userId}")
    public ResponseEntity<Meeting> createMeeting(
            @PathVariable Integer groupId,
            @PathVariable Integer userId) {

        return ResponseEntity.status(201)
                .body(meetingService.createMeeting(groupId, userId));
    }

    @PutMapping("/{meetingId}/start-locating")
    public ResponseEntity<ApiResponse> startLocating(
            @PathVariable Integer meetingId) {

        meetingService.startLocating(meetingId);

        return ResponseEntity.ok(
                new ApiResponse("Location sharing started successfully")
        );
    }

    @PutMapping("/{meetingId}/start-navigation")
    public ResponseEntity<ApiResponse> startNavigation(
            @PathVariable Integer meetingId) {

        meetingService.startNavigation(meetingId);

        return ResponseEntity.ok(
                new ApiResponse("Navigation started successfully")
        );
    }

    @PutMapping("/{meetingId}/complete")
    public ResponseEntity<ApiResponse> completeMeeting(
            @PathVariable Integer meetingId) {

        meetingService.completeMeeting(meetingId);

        return ResponseEntity.ok(
                new ApiResponse("Meeting completed successfully")
        );
    }

    @PutMapping("/{meetingId}/cancel")
    public ResponseEntity<ApiResponse> cancelMeeting(
            @PathVariable Integer meetingId) {

        meetingService.cancelMeeting(meetingId);

        return ResponseEntity.ok(
                new ApiResponse("Meeting cancelled successfully")
        );
    }
}
