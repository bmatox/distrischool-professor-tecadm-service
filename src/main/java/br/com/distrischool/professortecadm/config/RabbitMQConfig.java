package br.com.distrischool.professortecadm.config;

import org.springframework.amqp.core.*;
import org.springframework.amqp.rabbit.connection.ConnectionFactory;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.amqp.support.converter.Jackson2JsonMessageConverter;
import org.springframework.amqp.support.converter.MessageConverter;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class RabbitMQConfig {

    public static final String PROFESSOR_EXCHANGE = "distrischool.professor.exchange";
    public static final String PROFESSOR_CREATED_QUEUE = "professor.created.queue";
    public static final String PROFESSOR_UPDATED_QUEUE = "professor.updated.queue";
    public static final String PROFESSOR_DELETED_QUEUE = "professor.deleted.queue";
    public static final String PROFESSOR_CREATED_ROUTING_KEY = "professor.created";
    public static final String PROFESSOR_UPDATED_ROUTING_KEY = "professor.updated";
    public static final String PROFESSOR_DELETED_ROUTING_KEY = "professor.deleted";

    @Bean
    public TopicExchange professorExchange() {
        return new TopicExchange(PROFESSOR_EXCHANGE);
    }

    @Bean
    public Queue professorCreatedQueue() {
        return new Queue(PROFESSOR_CREATED_QUEUE, true);
    }

    @Bean
    public Queue professorUpdatedQueue() {
        return new Queue(PROFESSOR_UPDATED_QUEUE, true);
    }

    @Bean
    public Queue professorDeletedQueue() {
        return new Queue(PROFESSOR_DELETED_QUEUE, true);
    }

    @Bean
    public Binding professorCreatedBinding() {
        return BindingBuilder
                .bind(professorCreatedQueue())
                .to(professorExchange())
                .with(PROFESSOR_CREATED_ROUTING_KEY);
    }

    @Bean
    public Binding professorUpdatedBinding() {
        return BindingBuilder
                .bind(professorUpdatedQueue())
                .to(professorExchange())
                .with(PROFESSOR_UPDATED_ROUTING_KEY);
    }

    @Bean
    public Binding professorDeletedBinding() {
        return BindingBuilder
                .bind(professorDeletedQueue())
                .to(professorExchange())
                .with(PROFESSOR_DELETED_ROUTING_KEY);
    }

    @Bean
    public MessageConverter messageConverter() {
        return new Jackson2JsonMessageConverter();
    }

    @Bean
    public RabbitTemplate rabbitTemplate(ConnectionFactory connectionFactory) {
        RabbitTemplate rabbitTemplate = new RabbitTemplate(connectionFactory);
        rabbitTemplate.setMessageConverter(messageConverter());
        return rabbitTemplate;
    }
}
