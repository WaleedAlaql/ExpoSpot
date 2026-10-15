
package com.nawaf.meetingpoint.Repository;

import com.nawaf.meetingpoint.Model.Group;
import com.nawaf.meetingpoint.Model.Meeting;
import com.nawaf.meetingpoint.Model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface MeetingRepository extends JpaRepository<Meeting, Integer> {

    List<Meeting> findByGroupId(Integer groupId);

    boolean existsByGroup_IdAndUser_Id(Integer groupId, Integer userId);
}
