package com.apweb.backend.config;

import com.apweb.backend.security.jwt.CustomUserDetails;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;

import java.lang.reflect.InvocationHandler;
import java.lang.reflect.Method;
import java.sql.Connection;
import java.sql.Statement;

public class ConnectionInvocationHandler implements InvocationHandler {
    private final Connection target;
    private boolean roleSet = false;

    public ConnectionInvocationHandler(Connection target) {
        this.target = target;
    }

    @Override
    public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
        String methodName = method.getName();

        if (!roleSet && isExecutionMethod(methodName)) {
            Authentication auth = SecurityContextHolder.getContext().getAuthentication();
            if (auth != null && auth.getPrincipal() instanceof CustomUserDetails) {
                CustomUserDetails userDetails = (CustomUserDetails) auth.getPrincipal();
                String dbRole = userDetails.getDbUsername();
                if (dbRole != null && !dbRole.isEmpty()) {
                    try (Statement stmt = target.createStatement()) {
                        stmt.execute("SET ROLE '" + dbRole + "'");
                        roleSet = true;
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                }
            }
        }

        if ("close".equals(methodName)) {
            if (roleSet) {
                try (Statement stmt = target.createStatement()) {
                    stmt.execute("RESET ROLE");
                } catch (Exception e) {
                    // Ignore on connection close
                }
                roleSet = false;
            }
        }

        return method.invoke(target, args);
    }

    private boolean isExecutionMethod(String methodName) {
        return "prepareStatement".equals(methodName) ||
                "createStatement".equals(methodName) ||
                "prepareCall".equals(methodName);
    }
}
