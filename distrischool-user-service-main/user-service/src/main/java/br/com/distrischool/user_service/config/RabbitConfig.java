package br.com.distrischool.user_service.config;

import org.springframework.amqp.core.ExchangeBuilder;
import org.springframework.amqp.core.TopicExchange;
import org.springframework.amqp.rabbit.connection.ConnectionFactory;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.amqp.support.converter.Jackson2JsonMessageConverter;
import org.springframework.amqp.support.converter.MessageConverter;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class RabbitConfig {

    public static final String EXCHANGE = "users.exchange";

    // 1. Configura a Exchange (Ponto de Roteamento)
    @Bean
    public TopicExchange usersExchange() {
        return ExchangeBuilder.topicExchange(EXCHANGE).durable(true).build();
    }

    // 2. Define o Conversor de Mensagens (JSON)
    // O erro 500 acontece porque este conversor estava faltando.
    @Bean
    public MessageConverter jsonMessageConverter() {
        return new Jackson2JsonMessageConverter();
    }

    // 3. Configura o RabbitTemplate para usar o conversor JSON
    // O Spring usa este Bean para injetar o RabbitTemplate com o JSON Converter
    @Bean
    public RabbitTemplate rabbitTemplate(ConnectionFactory connectionFactory, MessageConverter jsonMessageConverter) {
        final RabbitTemplate rabbitTemplate = new RabbitTemplate(connectionFactory);
        rabbitTemplate.setMessageConverter(jsonMessageConverter);
        return rabbitTemplate;
    }
}
