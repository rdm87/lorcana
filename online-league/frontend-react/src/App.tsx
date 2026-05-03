import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import Home from './pages/Home';
import TournamentDetail from './pages/TournamentDetail';
import Availability from './pages/Availability';
import CreateTournament from './pages/CreateTournament';
import BotConfig from './pages/BotConfig';
import AuthCallback from './pages/AuthCallback';
import Wiki from './pages/Wiki';

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Home />} />
        <Route path="/tournaments/:id" element={<TournamentDetail />} />
        <Route path="/tournaments/:id/availability" element={<Availability />} />
        <Route path="/auth/callback" element={<AuthCallback />} />
        <Route path="/wiki" element={<Wiki />} />
        <Route path="/admin/tournaments/new" element={<CreateTournament />} />
        <Route path="/admin/tournaments/:id/edit" element={<CreateTournament />} />
        <Route path="/admin/bot-config" element={<BotConfig />} />
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </BrowserRouter>
  );
}
