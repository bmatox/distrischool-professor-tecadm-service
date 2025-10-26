package br.com.distrischool.professortecadm.event;

import java.time.LocalDate;
import java.time.LocalDateTime;

public record ProfessorUpdatedEvent(
        Long id,
        String nome,
        String email,
        String especialidade,
        LocalDate dataContratacao,
        LocalDateTime eventTimestamp
) {
}
