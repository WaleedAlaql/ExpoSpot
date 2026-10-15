package com.nawaf.meetingpoint.Controller;
import com.nawaf.meetingpoint.Api.NavigationException;
import com.nawaf.meetingpoint.DTO.Location.*;
import com.nawaf.meetingpoint.Service.LocationService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;
import java.util.List;
@RestController
@RequestMapping("/api/v1/group/{groupId}/locations")
@RequiredArgsConstructor
public class LocationController {
    private final LocationService locations;
    @GetMapping
    public List<MemberLocationResponse> get(@PathVariable Integer groupId) { return locations.getGroupLocations(groupId); }
    @PutMapping
    public MemberLocationResponse update(@PathVariable Integer groupId,@Valid @RequestBody LocationUpdateRequest request) {
        if (!groupId.equals(request.groupId())) throw new NavigationException(400,"groupId does not match path");
        return locations.update(request);
    }
}
