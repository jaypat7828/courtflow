# CourtFlow

CourtFlow is an open-source app for organizing doubles sports like pickleball, tennis, badminton, and padel. Generate fair round-robin matches, track scores, and view live standings.

## Status

**Phase 1 (in progress)** — Flutter Web MVP: welcome screen + player management backed by Supabase.

## Stack

| Layer    | Tech                        |
|----------|-----------------------------|
| Frontend | Flutter Web (via FVM)       |
| Database | Supabase (PostgreSQL)       |
| Hosting  | Cloudflare Pages (planned)  |

## Getting Started

### Prerequisites

```bash
brew install fvm   # Flutter Version Manager
```

### Run locally

```bash
# 1. Clone and enter the repo
cd courtflow

# 2. Install the pinned Flutter version
fvm install

# 3. Configure Supabase credentials in frontend/lib/main.dart
#    Replace _supabaseUrl and _supabaseAnonKey with your project values.
#    Create a free project at https://supabase.com

# 4. Apply the database schema
#    Paste database/schema.sql into the Supabase SQL Editor and run it.

# 5. Start the app
cd frontend
fvm flutter run -d chrome
```

## Project Structure

```
courtflow/
├── frontend/          # Flutter Web application
│   └── lib/
│       ├── main.dart
│       ├── screens/
│       │   ├── home_screen.dart
│       │   └── players_screen.dart
│       ├── models/
│       │   └── player.dart
│       └── services/
│           └── database_service.dart
├── database/
│   └── schema.sql     # Supabase table definitions
├── backend/           # Future: Edge Functions
└── docs/              # Future: architecture notes
```

## Roadmap

- [x] Welcome screen
- [x] Add / list / delete players (Supabase)
- [ ] Deploy to Cloudflare Pages
- [ ] Player profiles (skill level, email)
- [ ] Game sessions
- [ ] Round-robin generator
- [ ] Score tracking
- [ ] Leaderboard
