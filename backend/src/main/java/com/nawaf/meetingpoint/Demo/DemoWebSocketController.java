package com.nawaf.meetingpoint.Demo;

import com.nawaf.meetingpoint.Api.ApiException;
import com.nawaf.meetingpoint.Api.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.messaging.handler.annotation.*;
import org.springframework.messaging.simp.annotation.SendToUser;
import org.springframework.stereotype.Controller;

@Controller
@RequiredArgsConstructor
@ConditionalOnProperty(name = "app.simulator.enabled", havingValue = "true")
public class DemoWebSocketController {
    private final DemoSimulationService simulations;
    @MessageMapping("/demo/{simulationId}/command")
    public void command(@DestinationVariable String simulationId, @Valid @Payload DemoDtos.Command command) {
        simulations.command(simulationId, command);
    }
    @MessageExceptionHandler({ApiException.class,
            org.springframework.messaging.handler.annotation.support.MethodArgumentNotValidException.class,
            org.springframework.messaging.converter.MessageConversionException.class})
    @SendToUser(value = "/topic/demo/errors", broadcast = false)
    public ApiResponse error(Exception error) {
        return new ApiResponse(error instanceof ApiException ? error.getMessage() : "Invalid simulator command");
    }
}
