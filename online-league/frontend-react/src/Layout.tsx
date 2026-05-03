import { Navbar, Nav, Container, Dropdown, Button } from 'react-bootstrap';
import { Link, useNavigate } from 'react-router-dom';
import { useSession } from './SessionContext';

export default function Layout({ children }: { children: React.ReactNode }) {
  const { user, isAdmin, effectiveIsAdmin, login, logout, toggleAdminView } = useSession();
  const navigate = useNavigate();

  return (
    <>
      <Navbar expand="md" className="navbar-lorcana">
        <Container fluid="xl">
          <Navbar.Brand as={Link} to="/" className="d-flex align-items-center gap-2">
            🎴 <span>Lorcana League</span>
          </Navbar.Brand>
          <Navbar.Toggle aria-controls="main-nav" />
          <Navbar.Collapse id="main-nav">
            <Nav className="me-auto">
              <Nav.Link as={Link} to="/">Home</Nav.Link>
              <Nav.Link as={Link} to="/wiki">📖 Guida</Nav.Link>
            </Nav>
            <Nav className="align-items-center gap-2 mt-2 mt-md-0">
              {effectiveIsAdmin && (
                <Dropdown align="end">
                  <Dropdown.Toggle variant="outline-light" size="sm" className="fw-bold">
                    ⚙️ Admin
                  </Dropdown.Toggle>
                  <Dropdown.Menu>
                    <Dropdown.Item onClick={() => navigate('/admin/tournaments/new')}>
                      ➕ Nuovo torneo
                    </Dropdown.Item>
                    <Dropdown.Item onClick={() => navigate('/admin/bot-config')}>
                      🤖 Bot Config
                    </Dropdown.Item>
                    <Dropdown.Divider />
                    <Dropdown.Item onClick={toggleAdminView}>
                      👤 Passa a vista giocatore
                    </Dropdown.Item>
                  </Dropdown.Menu>
                </Dropdown>
              )}
              {isAdmin && !effectiveIsAdmin && (
                <Button variant="outline-warning" size="sm" className="fw-bold" onClick={toggleAdminView}>
                  ⚙️ Vista admin
                </Button>
              )}
              {user ? (
                <Dropdown align="end">
                  <Dropdown.Toggle as="div" style={{ cursor: 'pointer' }} className="d-flex align-items-center gap-2">
                    {user.avatar_url
                      ? <img src={user.avatar_url} alt="" className="user-avatar" />
                      : <span className="text-warning fw-bold small">{user.username}</span>
                    }
                  </Dropdown.Toggle>
                  <Dropdown.Menu>
                    <Dropdown.ItemText className="text-muted small fw-bold">{user.username}</Dropdown.ItemText>
                    <Dropdown.Divider />
                    <Dropdown.Item onClick={logout}>🚪 Logout</Dropdown.Item>
                  </Dropdown.Menu>
                </Dropdown>
              ) : (
                <Button variant="warning" size="sm" className="fw-bold px-3" onClick={login}>
                  🎮 Login Discord
                </Button>
              )}
            </Nav>
          </Navbar.Collapse>
        </Container>
      </Navbar>
      {children}
    </>
  );
}
