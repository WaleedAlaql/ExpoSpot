package com.nawaf.meetingpoint.Demo;

import lombok.RequiredArgsConstructor;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import java.time.Instant;

@Service
@RequiredArgsConstructor
@ConditionalOnProperty(name = "app.simulator.enabled", havingValue = "true")
public class DemoRealtimePublisher {
    private final SimpMessagingTemplate messaging;
    public void publish(String channel, String event, DemoDtos.State state) {
        messaging.convertAndSend("/topic/demo/" + state.simulationId() + "/" + channel,
                new DemoDtos.Event(event, Instant.now(), state));
    }
}
