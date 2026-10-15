package com.nawaf.meetingpoint.DTO.Navigation;

public record GpsRouteResponse(MapMatchResponse start, MapMatchResponse destination, RouteResponse route) {}
