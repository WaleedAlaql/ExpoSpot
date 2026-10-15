package com.nawaf.meetingpoint.DTO.Group;

import java.time.LocalDateTime;

public record GroupMemberResponse(
        Integer memberId,
        Integer userId,
        String status,
        Boolean locationSharingEnabled,
        LocalDateTime joinedAt
) {}