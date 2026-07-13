import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _username = '';
  DateTime? _createdAt;
  bool _emailVerified = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('username, email_verified_at, created_at')
          .eq('id', user.id)
          .single();
      if (!mounted) return;
      setState(() {
        _username = profile['username'] as String;
        _emailVerified = profile['email_verified_at'] != null;
        _createdAt = DateTime.tryParse(profile['created_at'] as String);
      });
    } catch (_) {
      if (mounted) {
        setState(() => _username = user.email?.split('@').first ?? 'Player');
      }
    }
  }

  bool get _showVerificationBanner {
    if (_emailVerified) return false;
    if (_createdAt == null) return false;
    return DateTime.now().difference(_createdAt!).inDays >= 3;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final user = Supabase.instance.client.auth.currentUser;
    final displayName =
        _username.isNotEmpty ? _username : (user?.email?.split('@').first ?? 'Player');

    return Scaffold(
      appBar: AppBar(
        title: const Text('CourtFlow'),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: PopupMenuButton<String>(
              offset: const Offset(0, 48),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: colorScheme.primary.withValues(alpha: 0.2),
                    child: Text(
                      displayName[0].toUpperCase(),
                      style: TextStyle(color: colorScheme.primary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(displayName),
                  const Icon(Icons.arrow_drop_down),
                  const SizedBox(width: 8),
                ],
              ),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: const [
                      Icon(Icons.logout),
                      SizedBox(width: 8),
                      Text('Sign Out'),
                    ],
                  ),
                ),
              ],
              onSelected: (value) async {
                if (value == 'logout') {
                  await AuthService().signOut();
                }
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Email verification banner — shown only after 3 days if unverified
          if (_showVerificationBanner)
            MaterialBanner(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              content: Text(
                'Please verify your email address (${user?.email ?? ''}) to keep your account secure.',
                style: const TextStyle(fontSize: 13),
              ),
              leading: const Icon(Icons.mark_email_unread_outlined),
              backgroundColor: Colors.orange.shade900.withValues(alpha: 0.3),
              actions: [
                TextButton(
                  onPressed: () async {
                    await AuthService().queueConfirmationEmail();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Verification email queued — you\'ll receive it shortly.')),
                    );
                  },
                  child: const Text('Resend'),
                ),
                TextButton(
                  onPressed: () => setState(() => _emailVerified = true),
                  child: const Text('Dismiss'),
                ),
              ],
            ),

          // Main dashboard content
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back, $displayName 👋',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'What would you like to do today?',
                        style: TextStyle(
                            color:
                                colorScheme.onSurface.withValues(alpha: 0.6)),
                      ),
                      const SizedBox(height: 32),
                      Expanded(
                        child: GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.4,
                          children: [
                            _DashboardCard(
                              icon: Icons.group,
                              label: 'Players',
                              description: 'Manage your player roster',
                              onTap: () =>
                                  Navigator.pushNamed(context, '/players'),
                            ),
                            _DashboardCard(
                              icon: Icons.emoji_events_outlined,
                              label: 'Tournaments',
                              description: 'Create & run tournaments',
                              comingSoon: true,
                              onTap: () {},
                            ),
                            _DashboardCard(
                              icon: Icons.leaderboard_outlined,
                              label: 'Standings',
                              description: 'View player rankings',
                              comingSoon: true,
                              onTap: () {},
                            ),
                            _DashboardCard(
                              icon: Icons.star_outline,
                              label: 'Ratings',
                              description: 'Skill level tracking',
                              comingSoon: true,
                              onTap: () {},
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;
  final bool comingSoon;

  const _DashboardCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
    this.comingSoon = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: comingSoon ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon,
                      color: comingSoon
                          ? colorScheme.onSurface.withValues(alpha: 0.3)
                          : colorScheme.primary,
                      size: 28),
                  const Spacer(),
                  if (comingSoon)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: colorScheme.onSurface.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Soon',
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                ],
              ),
              const Spacer(),
              Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: comingSoon
                          ? colorScheme.onSurface.withValues(alpha: 0.4)
                          : null,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
