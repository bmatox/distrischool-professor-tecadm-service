package br.com.distrischool.professortecadm.event;

import java.time.LocalDateTime;

public record ProfessorDeletedEvent(
        Long id,
        LocalDateTime eventTimestamp
) {
}
