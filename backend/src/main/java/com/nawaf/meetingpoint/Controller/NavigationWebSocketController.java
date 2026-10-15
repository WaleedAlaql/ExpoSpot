package com.nawaf.meetingpoint.Controller;
import com.nawaf.meetingpoint.Api.*;
import com.nawaf.meetingpoint.DTO.Location.LocationUpdateRequest;
import com.nawaf.meetingpoint.DTO.Navigation.*;
import com.nawaf.meetingpoint.Service.*;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.messaging.handler.annotation.*;
import org.springframework.messaging.simp.annotation.SendToUser;
import org.springframework.stereotype.Controller;
@Controller
@RequiredArgsConstructor
public class NavigationWebSocketController {
    private final LocationService locations;
    private final NavigationService navigation;
    @MessageMapping("/groups/{groupId}/location")
    public void location(@DestinationVariable Integer groupId,@Valid @Payload LocationUpdateRequest request) {
        if (!groupId.equals(request.groupId())) throw new NavigationException(400,"groupId does not match destination");
        locations.update(request);
    }
    @MessageMapping("/groups/{groupId}/recommendation")
    public void recommendation(@DestinationVariable Integer groupId,@Valid @Payload MeetingOptimizationRequest request) { navigation.recommend(groupId,request); }
    @MessageMapping("/groups/{groupId}/routes")
    public void routes(@DestinationVariable Integer groupId,@Valid @Payload NavigationUpdateRequest request) { navigation.recalculate(groupId,request); }
    @MessageExceptionHandler({ApiException.class,org.springframework.messaging.handler.annotation.support.MethodArgumentNotValidException.class,
        org.springframework.messaging.converter.MessageConversionException.class})
    @SendToUser(value="/topic/errors",broadcast=false)
    public ApiResponse error(Exception e) { return new ApiResponse(e instanceof ApiException ? e.getMessage() : "Invalid message payload"); }
}
