package com.redsunset.jabrery;

import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.BeforeEach;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.utility.DockerImageName;

import javax.sql.DataSource;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.stream.Collectors;

// One container for all tests
@Testcontainers
public class AbstractIntegrationTest {
    @Container
    protected static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>(DockerImageName.parse("postgres:16"))
            .withDatabaseName("test_library")
            .withUsername("test_user")
            .withPassword("test_pass")
            .withInitScript("db/testcontainers/test-postgres-init.sql")
            .withReuse(true);

    protected static DataSource dataSource;

    @BeforeAll
    static void setupDataSource() {
        HikariConfig config = new HikariConfig();
        config.setJdbcUrl(postgres.getJdbcUrl());
        config.setUsername(postgres.getUsername());
        config.setPassword(postgres.getPassword());
        config.setDriverClassName(postgres.getDriverClassName());
        config.setMaximumPoolSize(5);

        dataSource = new HikariDataSource(config);
    }

    protected void executeSqlScript(String scriptPath) {
        try(Connection conn = dataSource.getConnection();
            Statement stmt = conn.createStatement()) {

            String sql = new BufferedReader(
                    new InputStreamReader(getClass().getClassLoader().getResourceAsStream(scriptPath)))
                    .lines().collect(Collectors.joining("\n"));
            stmt.execute(sql);
                    } catch (SQLException e) {
            throw new RuntimeException(e);
        }
    }

    @AfterAll
    static void closedDataSource() {
        if(dataSource instanceof HikariDataSource) {
            ((HikariDataSource) dataSource).close();
        }
    }
}


