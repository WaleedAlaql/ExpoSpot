
package com.nawaf.meetingpoint.Repository;

import com.nawaf.meetingpoint.Model.Meeting;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface MeetingRepository extends JpaRepository<Meeting, Integer> {

    List<Meeting> findByGroupId(Integer groupId);

}
