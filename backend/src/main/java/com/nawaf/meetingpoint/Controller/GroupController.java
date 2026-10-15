package com.nawaf.meetingpoint.Controller;

import com.nawaf.meetingpoint.DTO.Group.CreateGroupRequest;
import com.nawaf.meetingpoint.DTO.Group.GroupResponse;
import com.nawaf.meetingpoint.Model.Group;
import com.nawaf.meetingpoint.Service.GroupService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/group")
@RequiredArgsConstructor
public class GroupController {

    private final GroupService groupService;

    @PostMapping("/add/{ownerId}")
    public ResponseEntity<GroupResponse> createGroup(
            @PathVariable Integer ownerId,
            @Valid @RequestBody CreateGroupRequest request
    ) {
        Group group = groupService.createGroup(request.name(), ownerId);

        return ResponseEntity.status(201).body(toResponse(group));
    }

    @GetMapping("/get/{groupId}")
    public ResponseEntity<GroupResponse> getGroup(
            @PathVariable Integer groupId
    ) {
        return ResponseEntity.ok(toResponse(groupService.getGroup(groupId)));
    }

    @GetMapping("/invite/{inviteCode}")
    public ResponseEntity<GroupResponse> getGroupByInviteCode(
            @PathVariable String inviteCode
    ) {
        return ResponseEntity.ok(
                toResponse(groupService.getGroupByInviteCode(inviteCode))
        );
    }

    private GroupResponse toResponse(Group group) {
        return new GroupResponse(
                group.getId(),
                group.getName(),
                group.getInviteCode(),
                group.getOwner().getId(),
                group.getCreatedAt()
        );
    }
}