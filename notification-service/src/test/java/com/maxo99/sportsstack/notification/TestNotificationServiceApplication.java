package com.maxo99.sportsstack.notification;

import org.springframework.boot.SpringApplication;

import com.maxo99.sportsstack.notification.NotificationServiceApplication;

public class TestNotificationServiceApplication {

	public static void main(String[] args) {
		SpringApplication.from(NotificationServiceApplication::main).with(TestcontainersConfiguration.class).run(args);
	}

}
