import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_client.dart';

class BotConfigScreen extends StatefulWidget {
  final ApiClient api;
  const BotConfigScreen({super.key, required this.api});

  @override
  State<BotConfigScreen> createState() => _BotConfigScreenState();
}

class _BotConfigScreenState extends State<BotConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _guildId = TextEditingController();
  final _channelId = TextEditingController();
  final _inviteUrl = TextEditingController();
  final _botToken = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _generating = false;
  bool _addingBot = false;
  bool _hasToken = false;
  bool _showToken = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _guildId.dispose();
    _channelId.dispose();
    _inviteUrl.dispose();
    _botToken.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final cfg = await widget.api.getBotConfig();
      setState(() {
        _guildId.text = cfg['guild_id'] ?? '';
        _channelId.text = cfg['invite_channel_id'] ?? '';
        _inviteUrl.text = cfg['invite_url'] ?? '';
        _hasToken = cfg['has_token'] == true;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$e'), backgroundColor: Colors.red.shade700));
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final payload = <String, dynamic>{
        'guild_id': _guildId.text.trim(),
        'invite_channel_id': _channelId.text.trim(),
        'invite_url': _inviteUrl.text.trim(),
      };
      if (_botToken.text.trim().isNotEmpty) {
        payload['bot_token'] = _botToken.text.trim();
      }
      final cfg = await widget.api.saveBotConfig(payload);
      setState(() {
        _hasToken = cfg['has_token'] == true;
        _botToken.clear();
      });
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Configurazione salvata!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$e'), backgroundColor: Colors.red.shade700));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _addBotToServer() async {
    setState(() => _addingBot = true);
    try {
      final url = await widget.api.getBotOAuthUrl();
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$e'), backgroundColor: Colors.red.shade700));
      }
    } finally {
      if (mounted) setState(() => _addingBot = false);
    }
  }

  Future<void> _generateInvite() async {
    setState(() => _generating = true);
    try {
      final url = await widget.api.generateDiscordInvite();
      setState(() => _inviteUrl.text = url);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Link di invito generato!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$e'), backgroundColor: Colors.red.shade700));
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.home_outlined),
        ),
        title: const Text('Configurazione Bot Discord'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF3EEFF), Color(0xFFFFF8E7)],
          ),
        ),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionCard(
                              title: 'Server Discord',
                              icon: Icons.discord,
                              iconColor: const Color(0xFF5865F2),
                              children: [
                                _field(
                                  controller: _guildId,
                                  label: 'ID Server (Guild ID)',
                                  hint: 'Es. 123456789012345678',
                                  helper: 'Apri Discord → Impostazioni server → Widget → ID server',
                                  icon: Icons.tag,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _SectionCard(
                              title: 'Bot',
                              icon: Icons.smart_toy_outlined,
                              iconColor: const Color(0xFF5D2EA6),
                              children: [
                                _field(
                                  controller: _botToken,
                                  label: _hasToken
                                      ? 'Token bot (lascia vuoto per non modificare)'
                                      : 'Token bot Discord',
                                  hint: 'Bot token dal Discord Developer Portal',
                                  icon: Icons.vpn_key_outlined,
                                  obscure: !_showToken,
                                  suffix: IconButton(
                                    icon: Icon(_showToken
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                        size: 18),
                                    onPressed: () =>
                                        setState(() => _showToken = !_showToken),
                                  ),
                                ),
                                if (_hasToken)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Row(children: [
                                      Icon(Icons.check_circle_outline,
                                          size: 14, color: Colors.green.shade600),
                                      const SizedBox(width: 4),
                                      Text('Token configurato',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.green.shade700)),
                                    ]),
                                  ),
                                const SizedBox(height: 12),
                                if (_hasToken)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: OutlinedButton.icon(
                                      onPressed: _addingBot ? null : _addBotToServer,
                                      icon: _addingBot
                                          ? const SizedBox(
                                              width: 14,
                                              height: 14,
                                              child: CircularProgressIndicator(strokeWidth: 2))
                                          : const Icon(Icons.add_moderator_outlined, size: 16),
                                      label: const Text('Aggiungi bot al server'),
                                      style: OutlinedButton.styleFrom(
                                          visualDensity: VisualDensity.compact,
                                          foregroundColor: const Color(0xFF5865F2),
                                          side: const BorderSide(color: Color(0xFF5865F2))),
                                    ),
                                  ),
                                _field(
                                  controller: _channelId,
                                  label: 'ID canale per gli inviti',
                                  hint: 'Es. 987654321098765432',
                                  helper:
                                      'ID del canale testuale da cui generare il link di invito',
                                  icon: Icons.tag,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _SectionCard(
                              title: 'Link di invito',
                              icon: Icons.link,
                              iconColor: Colors.teal,
                              children: [
                                _field(
                                  controller: _inviteUrl,
                                  label: 'URL invito Discord',
                                  hint: 'https://discord.gg/xxxxx',
                                  helper:
                                      'Inserisci manualmente oppure genera automaticamente tramite il bot',
                                  icon: Icons.insert_link_outlined,
                                ),
                                const SizedBox(height: 10),
                                OutlinedButton.icon(
                                  onPressed: _generating ? null : _generateInvite,
                                  icon: _generating
                                      ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2))
                                      : const Icon(Icons.auto_fix_high_outlined,
                                          size: 16),
                                  label: Text(_generating
                                      ? 'Generazione...'
                                      : 'Genera automaticamente'),
                                  style: OutlinedButton.styleFrom(
                                      visualDensity: VisualDensity.compact),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    'Richiede token bot e ID canale configurati sopra.',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: _saving ? null : _save,
                                icon: _saving
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white))
                                    : const Icon(Icons.save_outlined),
                                label: Text(_saving ? 'Salvataggio...' : 'Salva configurazione'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? helper,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helper,
        helperMaxLines: 2,
        prefixIcon: Icon(icon, size: 18),
        suffixIcon: suffix,
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final List<Widget> children;
  const _SectionCard(
      {required this.title,
      required this.icon,
      required this.iconColor,
      required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white.withValues(alpha: .95),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 8),
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 16),
          ...children,
        ]),
      ),
    );
  }
}
