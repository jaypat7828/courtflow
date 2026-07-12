import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/player.dart';

class DatabaseService {
  final _client = Supabase.instance.client;
  static const _table = 'players';

  Future<List<Player>> getPlayers() async {
    final response = await _client
        .from(_table)
        .select()
        .order('created_at', ascending: true);
    return response.map(Player.fromJson).toList();
  }

  Future<Player> createPlayer(String name) async {
    final response = await _client
        .from(_table)
        .insert({'name': name.trim()})
        .select()
        .single();
    return Player.fromJson(response);
  }

  Future<void> deletePlayer(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }
}
