package com.nawaf.meetingpoint.Service;

import com.nawaf.meetingpoint.Api.ApiException;
import com.nawaf.meetingpoint.Model.Group;
import com.nawaf.meetingpoint.Model.GroupMember;
import com.nawaf.meetingpoint.Model.User;
import com.nawaf.meetingpoint.Model.Enum.MemberStatus;
import com.nawaf.meetingpoint.Repository.GroupMemberRepository;
import com.nawaf.meetingpoint.Repository.GroupRepository;
import com.nawaf.meetingpoint.Repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Locale;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class GroupService {

    private final GroupRepository groupRepository;
    private final GroupMemberRepository groupMemberRepository;
    private final UserRepository userRepository;

    @Transactional
    public Group createGroup(String name, Integer ownerId) {
        if (name == null || name.isBlank()) {
            throw new ApiException("Group name is required");
        }

        User owner = userRepository.findById(ownerId)
                .orElseThrow(() -> new ApiException("User not found"));

        Group group = new Group();
        group.setName(name.trim());
        group.setInviteCode(generateInviteCode());
        group.setOwner(owner);

        Group savedGroup = groupRepository.save(group);

        GroupMember ownerMember = new GroupMember();
        ownerMember.setGroup(savedGroup);
        ownerMember.setUser(owner);
        ownerMember.setLocationSharingEnabled(false);
        ownerMember.setStatus(MemberStatus.IDLE);

        groupMemberRepository.save(ownerMember);

        return savedGroup;
    }

    public Group getGroup(Integer groupId) {
        return groupRepository.findById(groupId)
                .orElseThrow(() -> new ApiException("Group not found"));
    }

    public Group getGroupByInviteCode(String inviteCode) {
        if (inviteCode == null || inviteCode.isBlank()) {
            throw new ApiException("Invite code is required");
        }

        String code = inviteCode.trim().toUpperCase(Locale.ROOT);

        return groupRepository.findByInviteCode(code)
                .orElseThrow(() -> new ApiException("Invalid invite code"));
    }

    private String generateInviteCode() {
        String code;

        do {
            code = UUID.randomUUID()
                    .toString()
                    .replace("-", "")
                    .substring(0, 8)
                    .toUpperCase(Locale.ROOT);
        } while (groupRepository.existsByInviteCode(code));

        return code;
    }
}