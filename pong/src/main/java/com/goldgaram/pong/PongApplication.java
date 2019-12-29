package com.goldgaram.pong;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.builder.SpringApplicationBuilder;
import org.springframework.boot.web.servlet.support.SpringBootServletInitializer;

@SpringBootApplication
public class PongApplication extends SpringBootServletInitializer {

  protected SpringApplicationBuilder configure(SpringApplicationBuilder application) {
    return application.sources(PongApplication.class);
}

	public static void main(String[] args) {
    System.out.println("Hello Spring Boot");
		SpringApplication.run(PongApplication.class, args);
	}

}
