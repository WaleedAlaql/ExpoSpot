package com.nawaf.meetingpoint.Repository;

import com.nawaf.meetingpoint.Model.GroupMember;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface GroupMemberRepository extends JpaRepository<GroupMember, Integer> {
    // Explicit SQL keeps row locking compatible with both MySQL and MariaDB.
    // Call inside LocationService.update's transaction so the lock spans read and write.
    @org.springframework.data.jpa.repository.Query(value = """
        SELECT gm.* FROM group_members gm
        WHERE gm.group_id = :groupId AND gm.user_id = :userId
        FOR UPDATE
        """, nativeQuery = true)
    java.util.Optional<GroupMember> findForLocationUpdate(@org.springframework.data.repository.query.Param("groupId") Integer groupId,
        @org.springframework.data.repository.query.Param("userId") Integer userId);

    boolean existsByGroup_IdAndUser_Id(Integer groupId, Integer userId);

    @org.springframework.data.jpa.repository.EntityGraph(attributePaths = {"user", "group"})
    java.util.List<GroupMember> findByGroup_IdOrderByUser_Id(Integer groupId);

    @org.springframework.data.jpa.repository.Query("select distinct m.group.id from GroupMember m where m.locationSharingEnabled = true")
    java.util.List<Integer> findSharingGroupIds();

    List<GroupMember> findByGroup_Id(Integer groupId);

    Optional<GroupMember> findByGroup_IdAndUser_Id(
            Integer groupId,
            Integer userId
    );
}
