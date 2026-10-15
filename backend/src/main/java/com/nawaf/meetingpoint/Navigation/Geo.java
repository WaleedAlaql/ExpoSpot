package com.nawaf.meetingpoint.Navigation;

import com.nawaf.meetingpoint.Api.NavigationException;
public final class Geo {
    private Geo() {}
    public static void validate(Double lat, Double lon) {
        if (lat == null || lon == null || !Double.isFinite(lat) || !Double.isFinite(lon)
                || Math.abs(lat) > 90 || Math.abs(lon) > 180)
            throw new NavigationException(400, "Invalid GPS coordinates");
    }
    public static double meters(double lat1, double lon1, double lat2, double lon2) {
        double a = Math.pow(Math.sin(Math.toRadians(lat2-lat1)/2),2)
            + Math.cos(Math.toRadians(lat1))*Math.cos(Math.toRadians(lat2))
            * Math.pow(Math.sin(Math.toRadians(lon2-lon1)/2),2);
        return 12742000 * Math.asin(Math.sqrt(Math.min(1, a)));
    }
}
