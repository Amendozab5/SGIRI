package com.apweb.backend;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.scheduling.annotation.EnableAsync;

@SpringBootApplication
@EnableAsync
public class BackendApplication {

	@Autowired
	private JdbcTemplate jdbcTemplate;

	@jakarta.annotation.PostConstruct
	public void fixDatabase() {
		try {
			jdbcTemplate.execute("ALTER TABLE usuarios.persona ADD COLUMN IF NOT EXISTS ruta_foto TEXT");
			System.out.println("BackendApplication: Column 'ruta_foto' added/verified manually.");
		} catch (Exception e) {
			System.out.println("BackendApplication: Manual fix failed (maybe it's already there): " + e.getMessage());
		}
	}

	public static void main(String[] args) {
		SpringApplication.run(BackendApplication.class, args);
	}

}
