package br.com.distrischool.professortecadm.service;

import br.com.distrischool.professortecadm.dto.*;
import br.com.distrischool.professortecadm.event.ProfessorCreatedEvent;
import br.com.distrischool.professortecadm.event.ProfessorDeletedEvent;
import br.com.distrischool.professortecadm.event.ProfessorEventPublisher;
import br.com.distrischool.professortecadm.event.ProfessorUpdatedEvent;
import br.com.distrischool.professortecadm.exception.*;
import br.com.distrischool.professortecadm.model.Professor;
import br.com.distrischool.professortecadm.repository.ProfessorRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

@Service
public class ProfessorService {

    private final ProfessorRepository professorRepository;
    private final ProfessorEventPublisher eventPublisher;

    public ProfessorService(ProfessorRepository professorRepository, ProfessorEventPublisher eventPublisher) {
        this.professorRepository = professorRepository;
        this.eventPublisher = eventPublisher;
    }

    @Transactional
    public ProfessorResponse create(CreateProfessorRequest request) {
        if (professorRepository.existsByEmail(request.email())) {
            throw new EmailAlreadyUsedException("Email já está em uso: " + request.email());
        }
        Professor professor = new Professor();
        professor.setNome(request.nome());
        professor.setEmail(request.email());
        professor.setEspecialidade(request.especialidade());
        professor.setDataContratacao(request.dataContratacao());
        Professor saved = professorRepository.save(professor);
        
        // Publish event
        eventPublisher.publishProfessorCreated(new ProfessorCreatedEvent(
                saved.getId(),
                saved.getNome(),
                saved.getEmail(),
                saved.getEspecialidade(),
                saved.getDataContratacao(),
                LocalDateTime.now()
        ));
        
        return toResponse(saved);
    }

    @Transactional(readOnly = true)
    public Page<ProfessorResponse> list(Pageable pageable) {
        return professorRepository.findAll(pageable).map(this::toResponse);
    }

    @Transactional(readOnly = true)
    public ProfessorResponse getById(Long id) {
        return professorRepository.findById(id)
                .map(this::toResponse)
                .orElseThrow(() -> new ResourceNotFoundException("Professor não encontrado: id=" + id));
    }

    @Transactional
    public ProfessorResponse update(Long id, UpdateProfessorRequest request) {
        Professor professor = professorRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Professor não encontrado: id=" + id));

        if (!request.email().equalsIgnoreCase(professor.getEmail()) && professorRepository.existsByEmail(request.email())) {
            throw new EmailAlreadyUsedException("Email já está em uso: " + request.email());
        }
        professor.setNome(request.nome());
        professor.setEmail(request.email());
        professor.setEspecialidade(request.especialidade());
        professor.setDataContratacao(request.dataContratacao());
        Professor saved = professorRepository.save(professor);
        
        // Publish event
        eventPublisher.publishProfessorUpdated(new ProfessorUpdatedEvent(
                saved.getId(),
                saved.getNome(),
                saved.getEmail(),
                saved.getEspecialidade(),
                saved.getDataContratacao(),
                LocalDateTime.now()
        ));
        
        return toResponse(saved);
    }

    @Transactional
    public void delete(Long id) {
        if (!professorRepository.existsById(id)) {
            throw new ResourceNotFoundException("Professor não encontrado: id=" + id);
        }
        professorRepository.deleteById(id);
        
        // Publish event
        eventPublisher.publishProfessorDeleted(new ProfessorDeletedEvent(
                id,
                LocalDateTime.now()
        ));
    }

    private ProfessorResponse toResponse(Professor professor) {
        return new ProfessorResponse(
                professor.getId(),
                professor.getNome(),
                professor.getEmail(),
                professor.getEspecialidade(),
                professor.getDataContratacao()
        );
    }
}