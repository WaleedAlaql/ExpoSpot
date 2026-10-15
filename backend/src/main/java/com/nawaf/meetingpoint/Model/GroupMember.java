
package com.nawaf.meetingpoint.Model;

import com.nawaf.meetingpoint.Model.Enum.MemberStatus;
import jakarta.persistence.*;
import jakarta.validation.constraints.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(
        name = "group_members",
        uniqueConstraints = @UniqueConstraint(
                columnNames = {"group_id", "user_id"}
        )
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class GroupMember {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @NotNull(message = "Group is required")
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "group_id", nullable = false)
    private Group group;

    @NotNull(message = "User is required")
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @DecimalMin(value = "-90.0")
    @DecimalMax(value = "90.0")
    private Double latitude;

    @DecimalMin(value = "-180.0")
    @DecimalMax(value = "180.0")
    private Double longitude;

    @DecimalMin(value = "0.0")
    private Double accuracyMeters;

    @Column(nullable = false)
    private Boolean locationSharingEnabled = false;

    @NotNull
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private MemberStatus status = MemberStatus.IDLE;

    private LocalDateTime lastLocationAt;

    @Column(nullable = false, updatable = false)
    private LocalDateTime joinedAt;

    @PrePersist
    public void onCreate() {
        joinedAt = LocalDateTime.now();
        if (status == null) status = MemberStatus.IDLE;
        if (locationSharingEnabled == null) {
            locationSharingEnabled = false;
        }
    }

    @AssertTrue(message =
            "Latitude and longitude must both be provided or both be null")
    @Transient
    public boolean isLocationPairValid() {
        return (latitude == null) == (longitude == null);
    }
}
