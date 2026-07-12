import 'package:flutter/material.dart';
import '../models/player.dart';
import '../services/database_service.dart';

class PlayersScreen extends StatefulWidget {
  const PlayersScreen({super.key});

  @override
  State<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends State<PlayersScreen> {
  final _db = DatabaseService();
  final _nameController = TextEditingController();
  List<Player> _players = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadPlayers() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final players = await _db.getPlayers();
      setState(() => _players = players);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _addPlayer() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    try {
      final player = await _db.createPlayer(name);
      _nameController.clear();
      setState(() => _players.add(player));
    } catch (e) {
      _showError('Failed to add player: $e');
    }
  }

  Future<void> _deletePlayer(Player player) async {
    try {
      await _db.deletePlayer(player.id);
      setState(() => _players.removeWhere((p) => p.id == player.id));
    } catch (e) {
      _showError('Failed to remove player: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Players'),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Add player input
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          hintText: 'Player name',
                          border: OutlineInputBorder(),
                        ),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _addPlayer(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: _addPlayer,
                      icon: const Icon(Icons.person_add),
                      label: const Text('Add'),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Header
                Text(
                  'Players (${_players.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                ),
                const SizedBox(height: 12),

                // Player list
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Could not load players.\nCheck your Supabase connection.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: colorScheme.onSurface
                                            .withValues(alpha: 0.5)),
                                  ),
                                  const SizedBox(height: 16),
                                  OutlinedButton(
                                    onPressed: _loadPlayers,
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            )
                          : _players.isEmpty
                              ? Center(
                                  child: Text(
                                    'No players yet.\nAdd the first one above!',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: colorScheme.onSurface
                                            .withValues(alpha: 0.4)),
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: _players.length,
                                  separatorBuilder: (_, _) =>
                                      const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final player = _players[index];
                                    return ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: colorScheme.primary
                                            .withValues(alpha: 0.2),
                                        child: Text(
                                          '${index + 1}',
                                          style: TextStyle(
                                              color: colorScheme.primary),
                                      ),
                                      ),
                                      title: Text(player.name),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete_outline),
                                        color: Colors.red.shade400,
                                        onPressed: () =>
                                            _deletePlayer(player),
                                        tooltip: 'Remove player',
                                      ),
                                    );
                                  },
                                ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
