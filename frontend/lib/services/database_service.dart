import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/player.dart';

class DatabaseService {
  final _client = Supabase.instance.client;
  static const _table = 'players';

  String get _userId => _client.auth.currentUser!.id;

  Future<List<Player>> getPlayers() async {
    final response = await _client
        .from(_table)
        .select()
        .eq('user_id', _userId)
        .order('created_at', ascending: true);
    return response.map(Player.fromJson).toList();
  }

  Future<Player> createPlayer(String name) async {
    final response = await _client
        .from(_table)
        .insert({'name': name.trim(), 'user_id': _userId})
        .select()
        .single();
    return Player.fromJson(response);
  }

  Future<void> deletePlayer(String id) async {
    await _client.from(_table).delete().eq('id', id).eq('user_id', _userId);
  }
}
