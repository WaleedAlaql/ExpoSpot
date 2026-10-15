package com.nawaf.meetingpoint.DTO.Group;

import java.time.LocalDateTime;

public record GroupResponse(
        Integer id,
        String name,
        String inviteCode,
        Integer ownerId,
        LocalDateTime createdAt
) {}