package com.nawaf.meetingpoint.Controller;

import com.nawaf.meetingpoint.Api.ApiResponse;
import com.nawaf.meetingpoint.DTO.Group.GroupMemberResponse;
import com.nawaf.meetingpoint.Model.GroupMember;
import com.nawaf.meetingpoint.Service.GroupMemberService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/group-member")
@RequiredArgsConstructor
public class GroupMemberController {

    private final GroupMemberService groupMemberService;

    @PostMapping("/join/{inviteCode}/{userId}")
    public ResponseEntity<GroupMemberResponse> joinGroup(
            @PathVariable String inviteCode,
            @PathVariable Integer userId
    ) {
        GroupMember member =
                groupMemberService.joinGroup(inviteCode, userId);

        return ResponseEntity.status(201).body(toResponse(member));
    }

    @DeleteMapping("/leave/{groupId}/{userId}")
    public ResponseEntity<ApiResponse> leaveGroup(
            @PathVariable Integer groupId,
            @PathVariable Integer userId
    ) {
        groupMemberService.leaveGroup(groupId, userId);

        return ResponseEntity.ok(
                new ApiResponse("Left group successfully")
        );
    }

    @GetMapping("/get/{groupId}/{requesterId}")
    public ResponseEntity<List<GroupMemberResponse>> getGroupMembers(
            @PathVariable Integer groupId,
            @PathVariable Integer requesterId
    ) {
        List<GroupMemberResponse> members =
                groupMemberService.getGroupMembers(groupId, requesterId)
                        .stream()
                        .map(this::toResponse)
                        .toList();

        return ResponseEntity.ok(members);
    }

    @DeleteMapping("/remove/{groupId}/{ownerId}/{memberUserId}")
    public ResponseEntity<ApiResponse> removeMember(
            @PathVariable Integer groupId,
            @PathVariable Integer ownerId,
            @PathVariable Integer memberUserId
    ) {
        groupMemberService.removeMember(
                groupId, ownerId, memberUserId
        );

        return ResponseEntity.ok(
                new ApiResponse("Member removed successfully")
        );
    }

    @GetMapping("/check/{groupId}/{userId}")
    public ResponseEntity<Boolean> checkMembership(
            @PathVariable Integer groupId,
            @PathVariable Integer userId
    ) {
        return ResponseEntity.ok(
                groupMemberService.isMember(groupId, userId)
        );
    }

    private GroupMemberResponse toResponse(GroupMember member) {
        return new GroupMemberResponse(
                member.getId(),
                member.getUser().getId(),
                member.getStatus().name(),
                member.getLocationSharingEnabled(),
                member.getJoinedAt()
        );
    }
}