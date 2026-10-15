package com.nawaf.meetingpoint.Api;

import lombok.Getter;
@Getter
public class NavigationException extends ApiException {
    private final int status;
    public NavigationException(int status, String message) { super(message); this.status = status; }
}
