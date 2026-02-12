package com.redsunset.jabrery;

import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.Test;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

public class ConnectionTest {
    public Connection getConnection () throws SQLException {
        return  DriverManager.getConnection(
                "jdbc:postgresql://localhost:5432/library",
                "library_admin",
                "securepass123");
    }

    @Test
    public void validConnection() throws SQLException {
        try(Connection con = getConnection()) {
            assertTrue(con.isValid(1));
            assertFalse(con.isClosed());
        } catch (SQLException e) {
            throw new SQLException(e);
        }
    }

    @Test
    public void showCurrentTime() {

    }
}
