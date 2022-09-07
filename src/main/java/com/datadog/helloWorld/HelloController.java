package com.datadog.helloWorld;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HelloController {
	
	@GetMapping("/")
	public String hello() {
		String greeting = getGreeting();
		return greeting;
	}

	public String getGreeting() {
		return "Hello World!";
	}
}
