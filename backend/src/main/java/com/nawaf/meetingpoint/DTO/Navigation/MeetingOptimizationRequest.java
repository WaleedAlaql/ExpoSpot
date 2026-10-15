package com.nawaf.meetingpoint.DTO.Navigation;

public record MeetingOptimizationRequest(@jakarta.validation.constraints.Positive Integer groupId, @jakarta.validation.constraints.NotEmpty @jakarta.validation.constraints.Size(max=100) java.util.List<@jakarta.validation.Valid ParticipantLocationDTO> participants) {}
