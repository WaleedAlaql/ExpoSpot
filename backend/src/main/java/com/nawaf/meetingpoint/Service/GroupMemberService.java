package com.nawaf.meetingpoint.Service;

import com.nawaf.meetingpoint.Repository.GroupMemberRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class GroupMemberService {

    private final GroupMemberRepository groupMember;
}
