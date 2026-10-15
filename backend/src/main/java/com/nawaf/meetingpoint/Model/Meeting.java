
package com.nawaf.meetingpoint.Model;

import com.nawaf.meetingpoint.Model.Enum.MeetingStatus;
import jakarta.persistence.*;
import jakarta.validation.constraints.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "meetings")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class Meeting {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @NotNull(message = "Group is required")
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "group_id", nullable = false)
    private Group group;

    @NotNull(message = "Meeting creator is required")
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "created_by", nullable = false)
    private User createdBy;

    @NotNull
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private MeetingStatus status = MeetingStatus.CREATED;

    @Size(max = 100)
    @Column(length = 100)
    private String meetingPointName;

    @DecimalMin("-90.0")
    @DecimalMax("90.0")
    private Double meetingLatitude;

    @DecimalMin("-180.0")
    @DecimalMax("180.0")
    private Double meetingLongitude;

    @PositiveOrZero
    private Double maxEtaSeconds;

    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    private LocalDateTime completedAt;

    @PrePersist
    public void onCreate() {
        createdAt = LocalDateTime.now();
        if (status == null) {
            status = MeetingStatus.CREATED;
        }
    }

    @AssertTrue(message =
            "Meeting point coordinates must be provided together")
    @Transient
    public boolean isMeetingPointValid() {
        return (meetingLatitude == null)
                == (meetingLongitude == null);
    }
}
