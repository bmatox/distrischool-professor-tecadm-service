import { useState, useEffect } from 'react';
import './ProfessorList.css';

const API_BASE_URL = 'http://localhost:8888';

function ProfessorList() {
  const [professores, setProfessores] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    fetchProfessores();
  }, []);

  const fetchProfessores = async () => {
    try {
      setLoading(true);
      setError(null);
      const response = await fetch(`${API_BASE_URL}/api/v1/professores`);
      
      if (!response.ok) {
        throw new Error(`Erro ao carregar professores: ${response.status}`);
      }
      
      const data = await response.json();
      // A resposta é paginada, então pegamos o conteúdo
      setProfessores(data.content || []);
    } catch (err) {
      setError(err.message);
      console.error('Erro ao buscar professores:', err);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return <div className="loading">Carregando professores...</div>;
  }

  if (error) {
    return (
      <div className="error">
        <h3>Erro ao carregar dados</h3>
        <p>{error}</p>
        <button onClick={fetchProfessores}>Tentar novamente</button>
      </div>
    );
  }

  return (
    <div className="professor-list-container">
      <h1>Lista de Professores</h1>
      <p className="subtitle">DistriSchool - Sistema de Gestão Escolar</p>
      
      {professores.length === 0 ? (
        <div className="empty-state">
          <p>Nenhum professor cadastrado ainda.</p>
        </div>
      ) : (
        <ul className="professor-list">
          {professores.map((professor) => (
            <li key={professor.id} className="professor-item">
              <div className="professor-info">
                <h3>{professor.nome}</h3>
                <p className="email">{professor.email}</p>
                {professor.especialidade && (
                  <p className="especialidade">Especialidade: {professor.especialidade}</p>
                )}
                {professor.dataContratacao && (
                  <p className="data">Contratado em: {new Date(professor.dataContratacao).toLocaleDateString('pt-BR')}</p>
                )}
              </div>
            </li>
          ))}
        </ul>
      )}
      
      <div className="info-box">
        <p>📋 Total de professores: <strong>{professores.length}</strong></p>
        <p>🔄 Dados carregados através do API Gateway (porta 8888)</p>
      </div>
    </div>
  );
}

export default ProfessorList;
