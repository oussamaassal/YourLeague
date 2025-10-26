# Matches Feature - Tournament Management

## Overview
This feature provides complete CRUD operations for managing tournament matches, match events, and leaderboards.

## Architecture
Following Clean Architecture pattern with three layers:
- **Domain**: Entities and Repository interfaces
- **Data**: Firebase implementation
- **Presentation**: UI pages and state management (BLoC/Cubit)

## Firebase Collections
1. `matches` - Tournament matches
2. `match_events` - Events within a match (goals, cards, etc.)
3. `leaderboards` - Tournament standings

## Entities Created

### Match Entity (`lib/User/features/matches/domain/entities/match.dart`)
- Match information between two teams
- Fields: id, tournamentId, team1/team2, scores, status, dates, referee, location
- Status: 'scheduled', 'ongoing', 'completed', 'cancelled'

### Match Event Entity (`lib/User/features/matches/domain/entities/match_event.dart`)
- Events during a match
- Types: 'goal', 'yellow_card', 'red_card', 'substitution', 'other'
- Tracks player, minute, team, and description

### Leaderboard Entity (`lib/User/features/matches/domain/entities/leaderboard.dart`)
- Tournament standings
- Tracks: matches played, wins/draws/losses, goals, points, goal difference
- Automatically sorted by points and goal difference

## CRUD Operations Implemented

### Matches CRUD
- ✅ Create Match
- ✅ Read Match (single/all/by tournament)
- ✅ Update Match (scores, status)
- ✅ Delete Match

### Match Events CRUD
- ✅ Create Event
- ✅ Read Events (by match)
- ✅ Update Event
- ✅ Delete Event

### Leaderboards CRUD
- ✅ Create Entry
- ✅ Read Leaderboards (by tournament)
- ✅ Update Entry
- ✅ Delete Entry

## Pages Created

### Matches Page (`matches_page.dart`)
- List all matches
- Add/Edit/Delete matches
- View match details (teams, scores, status, date)
- Filter by tournament (in code)

### Match Events Page (`match_events_page.dart`)
- View events for a specific match
- Add events (goals, cards, etc.)
- Delete events
- Icon-coded event types

### Leaderboards Page (`leaderboards_page.dart`)
- Display tournament standings in table format
- Shows: Rank, Team, MP, W, D, L, GF, GA, GD, Pts
- Auto-sorted by points and goal difference

## Integration
- Added `MatchesCubit` to `main.dart` BLoC providers
- Matches navigation added to home page (Page 1)
- Uses Firebase Firestore for data persistence

## Usage

### Access Matches
1. Open the app and login
2. Navigate to "Page 1" in the home page
3. Click "View Matches" button
4. Use the "+" icon to add new matches

### Add Match Events
1. Open a match (from matches list)
2. Click the "+" icon
3. Select event type (goal, card, etc.)
4. Enter player name, minute, description
5. Save

### View Leaderboards
1. Navigate to a tournament leaderboard
2. View standings with rankings
3. Points calculated as: wins * 3 + draws

## Dependencies Added
- `intl: ^0.19.0` - For date formatting

## Firebase Structure

```
matches/
  - id: match123
  - tournamentId: "tournament1"
  - team1Name: "Team A"
  - team2Name: "Team B"
  - score1: 2
  - score2: 1
  - status: "completed"
  - matchDate: Timestamp
  - ...

match_events/
  - id: event123
  - matchId: "match123"
  - type: "goal"
  - playerName: "Player Name"
  - minute: 45
  - ...

leaderboards/
  - id: leaderboard123
  - tournamentId: "tournament1"
  - teamName: "Team A"
  - points: 9
  - goalDifference: 5
  - ...
```

## Notes
- All timestamps use Firebase Timestamp
- Match IDs are auto-generated using timestamp
- Leaderboard ranking is auto-calculated by Firebase queries
- Event icons are color-coded (yellow/red cards, goal icon, etc.)

