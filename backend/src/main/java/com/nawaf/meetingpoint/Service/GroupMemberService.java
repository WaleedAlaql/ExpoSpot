package com.nawaf.meetingpoint.Service;

import com.nawaf.meetingpoint.Api.ApiException;
import com.nawaf.meetingpoint.Model.Enum.MemberStatus;
import com.nawaf.meetingpoint.Model.Group;
import com.nawaf.meetingpoint.Model.GroupMember;
import com.nawaf.meetingpoint.Model.User;
import com.nawaf.meetingpoint.Repository.GroupMemberRepository;
import com.nawaf.meetingpoint.Repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Locale;

@Service
@RequiredArgsConstructor
public class GroupMemberService {

    private final GroupMemberRepository groupMemberRepository;
    private final UserRepository userRepository;
    private final GroupService groupService;

    @Transactional
    public GroupMember joinGroup(String inviteCode, Integer userId) {
        if (inviteCode == null || inviteCode.isBlank()) {
            throw new ApiException("Invite code is required");
        }

        Group group = groupService.getGroupByInviteCode(
                inviteCode.trim().toUpperCase(Locale.ROOT)
        );

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ApiException("User not found"));

        if (groupMemberRepository.existsByGroup_IdAndUser_Id(
                group.getId(), userId
        )) {
            throw new ApiException("User is already a group member");
        }

        GroupMember member = new GroupMember();
        member.setGroup(group);
        member.setUser(user);
        member.setLocationSharingEnabled(false);
        member.setStatus(MemberStatus.IDLE);

        return groupMemberRepository.save(member);
    }

    @Transactional
    public void leaveGroup(Integer groupId, Integer userId) {
        Group group = groupService.getGroup(groupId);

        if (group.getOwner().getId().equals(userId)) {
            throw new ApiException("Group owner cannot leave the group");
        }

        GroupMember member = findMember(groupId, userId);
        groupMemberRepository.delete(member);
    }

    @Transactional(readOnly = true)
    public List<GroupMember> getGroupMembers(
            Integer groupId,
            Integer requesterId
    ) {
        groupService.getGroup(groupId);
        ensureMember(groupId, requesterId);

        return groupMemberRepository.findByGroup_Id(groupId);
    }

    @Transactional
    public void removeMember(
            Integer groupId,
            Integer ownerId,
            Integer memberUserId
    ) {
        Group group = groupService.getGroup(groupId);
        ensureOwner(group, ownerId);

        if (ownerId.equals(memberUserId)) {
            throw new ApiException("Group owner cannot remove themselves");
        }

        GroupMember member = findMember(groupId, memberUserId);
        groupMemberRepository.delete(member);
    }

    @Transactional(readOnly = true)
    public boolean isMember(Integer groupId, Integer userId) {
        groupService.getGroup(groupId);

        return groupMemberRepository.existsByGroup_IdAndUser_Id(
                groupId, userId
        );
    }

    private GroupMember findMember(Integer groupId, Integer userId) {
        return groupMemberRepository
                .findByGroup_IdAndUser_Id(groupId, userId)
                .orElseThrow(() -> new ApiException("User is not a group member"));
    }

    private void ensureMember(Integer groupId, Integer userId) {
        if (!groupMemberRepository.existsByGroup_IdAndUser_Id(
                groupId, userId
        )) {
            throw new ApiException("User is not a group member");
        }
    }

    private void ensureOwner(Group group, Integer userId) {
        if (!group.getOwner().getId().equals(userId)) {
            throw new ApiException("Only the group owner can do this");
        }
    }
}