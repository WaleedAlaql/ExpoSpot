package com.nawaf.meetingpoint.DTO.Navigation;
import java.time.Instant;
public record RealtimeEventDTO<T>(String event, Integer groupId, Integer meetingId, Instant occurredAt, T data) {}
