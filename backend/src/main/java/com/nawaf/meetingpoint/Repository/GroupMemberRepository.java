package com.nawaf.meetingpoint.Repository;

import com.nawaf.meetingpoint.Model.GroupMember;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface GroupMemberRepository extends JpaRepository<GroupMember, Integer> {

    List<GroupMember> findByGroup_Id(Integer groupId);

    Optional<GroupMember> findByGroup_IdAndUser_Id(
            Integer groupId,
            Integer userId
    );

    boolean existsByGroup_IdAndUser_Id(
            Integer groupId,
            Integer userId
    );
}