package com.apweb.backend.config;

import org.springframework.jdbc.datasource.DelegatingDataSource;

import javax.sql.DataSource;
import java.lang.reflect.Proxy;
import java.sql.Connection;
import java.sql.SQLException;

public class RoleSettingDataSource extends DelegatingDataSource {

    public RoleSettingDataSource(DataSource targetDataSource) {
        super(targetDataSource);
    }

    @Override
    @org.springframework.lang.NonNull
    public Connection getConnection() throws SQLException {
        Connection connection = super.getConnection();
        return wrapConnection(connection);
    }

    @Override
    @org.springframework.lang.NonNull
    public Connection getConnection(String username, String password) throws SQLException {
        Connection connection = super.getConnection(username, password);
        return wrapConnection(connection);
    }

    @org.springframework.lang.NonNull
    private Connection wrapConnection(Connection connection) {
        return (Connection) Proxy.newProxyInstance(
                Connection.class.getClassLoader(),
                new Class[] { Connection.class },
                new ConnectionInvocationHandler(connection));
    }
}
