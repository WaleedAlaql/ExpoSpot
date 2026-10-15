package com.nawaf.meetingpoint.DTO.Navigation;

public record GraphResponse(java.util.List<com.nawaf.meetingpoint.Navigation.Graph.GraphNode> nodes, java.util.List<com.nawaf.meetingpoint.Navigation.Graph.GraphEdge> edges, java.util.List<com.nawaf.meetingpoint.DTO.Meeting.MeetingPointResponse> meetingPoints) {}
