package com.nawaf.meetingpoint.Demo;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;
import java.io.IOException;

/** Feature gate only; no authentication or production request handling. */
@Component
public class DemoAccessFilter extends OncePerRequestFilter {
    private final boolean enabled;
    public DemoAccessFilter(@Value("${app.simulator.enabled:false}") boolean enabled) { this.enabled = enabled; }
    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain)
            throws ServletException, IOException {
        String path = request.getServletPath();
        if (!enabled && (path.equals("/navigation-simulator.html") || path.startsWith("/api/v1/demo/navigation/"))) {
            response.setStatus(404);
            response.setContentType("application/json");
            response.getWriter().write("{\"message\":\"Simulator disabled. Enable app.simulator.enabled=true to use it.\"}");
            return;
        }
        chain.doFilter(request, response);
    }
}
