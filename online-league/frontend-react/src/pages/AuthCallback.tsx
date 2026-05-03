import { useEffect } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { Spinner } from 'react-bootstrap';
import { setToken } from '../api';
import { useSession } from '../SessionContext';

export default function AuthCallback() {
  const [params] = useSearchParams();
  const navigate = useNavigate();
  const { reload } = useSession();

  useEffect(() => {
    const token = params.get('token');
    if (token) {
      setToken(token);
      reload().then(() => navigate('/', { replace: true }));
    } else {
      navigate('/', { replace: true });
    }
  }, []);

  return (
    <div className="d-flex flex-column align-items-center justify-content-center" style={{ minHeight: '100vh' }}>
      <Spinner animation="border" variant="primary" style={{ width: '3rem', height: '3rem' }} />
      <p className="mt-3 fw-bold purple-text">Accesso in corso…</p>
    </div>
  );
}
