package com.maxo99.sportsstack.notification.service;

import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.mail.MailException;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.mail.javamail.MimeMessagePreparator;
import org.springframework.stereotype.Service;

import com.maxo99.sportsstack.order.event.OrderPlacedEvent;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Service
@RequiredArgsConstructor
@Slf4j
public class NotificationService {
    private final JavaMailSender javaMailSender;

    @KafkaListener(topics = "order-placed")
    public void listen(OrderPlacedEvent event) {
        log.info("Received orderPlacedEvent: {}", event);
        MimeMessagePreparator messagePreparator = mimeMessage -> {
            MimeMessageHelper messageHelper = new MimeMessageHelper(mimeMessage);
            messageHelper.setFrom("springshop@email.com");
            messageHelper.setTo(event.getEmail().toString());
            messageHelper.setSubject(
                    String.format("Your Order with OrderNumber %s is placed successfully", event.getOrderNumber()));
            messageHelper.setText(String.format("""
                    Hi %s %s,

                    Your order with order number %s is now placed successfully.

                    Best Regards
                    Spring Shop
                    """,
                    event.getFirstName().toString(),
                    event.getLastName().toString(),
                    event.getOrderNumber()));
        };
        try {
            javaMailSender.send(messagePreparator);
            log.info("Order Notifcation email sent!!");
        } catch (MailException e) {
            log.error("Exception occurred when sending mail", e);
            throw new RuntimeException("Exception occurred when sending mail to springshop@email.com", e);
        }
    }
}
