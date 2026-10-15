package com.nawaf.meetingpoint.Model;

import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.persistence.*;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
@Entity
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @NotEmpty(message = "Name required")
    @Size(max = 50, message = "Name cannot be more than 50 characters")
    @Column(nullable = false, length = 50)
    private String name;

    @NotEmpty(message = "Password required")
    @Size(max = 100, message = "Password cannot be more than 100 characters")
    @JsonProperty(access = JsonProperty.Access.WRITE_ONLY)
    @Column(nullable = false, length = 100)
    private String password;

    @NotEmpty(message = "Email required")
    @Email(message = "Enter valid email")
    @Column(nullable = false, unique = true)
    private String email;
}
