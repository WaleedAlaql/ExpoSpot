package com.nawaf.meetingpoint.Demo;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.web.bind.annotation.*;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api/v1/demo/navigation/simulations")
@ConditionalOnProperty(name = "app.simulator.enabled", havingValue = "true")
public class DemoNavigationController {
    private final DemoSimulationService simulations;
    @PostMapping
    @ResponseStatus(org.springframework.http.HttpStatus.CREATED)
    public DemoDtos.State create() { return simulations.create(); }
    @GetMapping("/{simulationId}")
    public DemoDtos.State get(@PathVariable String simulationId) { return simulations.get(simulationId); }
    @PostMapping("/{simulationId}/commands")
    public DemoDtos.State command(@PathVariable String simulationId, @Valid @RequestBody DemoDtos.Command command) {
        return simulations.command(simulationId, command);
    }
}
