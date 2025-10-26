package br.com.distrischool.professortecadm.event;

import br.com.distrischool.professortecadm.config.RabbitMQConfig;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.stereotype.Service;

@Service
public class ProfessorEventPublisher {

    private static final Logger log = LoggerFactory.getLogger(ProfessorEventPublisher.class);
    private final RabbitTemplate rabbitTemplate;

    public ProfessorEventPublisher(RabbitTemplate rabbitTemplate) {
        this.rabbitTemplate = rabbitTemplate;
    }

    public void publishProfessorCreated(ProfessorCreatedEvent event) {
        log.info("Publishing professor created event: {}", event);
        rabbitTemplate.convertAndSend(
                RabbitMQConfig.PROFESSOR_EXCHANGE,
                RabbitMQConfig.PROFESSOR_CREATED_ROUTING_KEY,
                event
        );
    }

    public void publishProfessorUpdated(ProfessorUpdatedEvent event) {
        log.info("Publishing professor updated event: {}", event);
        rabbitTemplate.convertAndSend(
                RabbitMQConfig.PROFESSOR_EXCHANGE,
                RabbitMQConfig.PROFESSOR_UPDATED_ROUTING_KEY,
                event
        );
    }

    public void publishProfessorDeleted(ProfessorDeletedEvent event) {
        log.info("Publishing professor deleted event: {}", event);
        rabbitTemplate.convertAndSend(
                RabbitMQConfig.PROFESSOR_EXCHANGE,
                RabbitMQConfig.PROFESSOR_DELETED_ROUTING_KEY,
                event
        );
    }
}
