# EazySave App – Handoff Notes

## What changed in this branch
- Material 3 theme applied globally (orange seed color).
- Bottom navigation updated to Material 3 `NavigationBar`.
- Compare Stores screen redesigned (premium summary header, highlighted cheapest card).
- Micro-interactions on Compare Stores:
  - light haptic on expansion
  - totals animate/count-up
- Create List quantity display is numeric-only (e.g. `1`).

## Local setup on the next laptop
1. Pull latest changes
   - `git pull`
2. Install dependencies
   - `flutter pub get`
3. Create local environment file (NOT committed)
   - Create a file named `.env` in the project root (same folder as `pubspec.yaml`)
   - Add:
     - `SUPABASE_URL=...`
     - `SUPABASE_ANON_KEY=...`

Notes:
- `.env` is gitignored on purpose.

## Where to look in code
- Global theme: `lib/main.dart`
- Navigation: `lib/nav_bar.dart`
- Compare Stores UI: `lib/compare_stores_page.dart`
- Create List UI: `lib/create_list_page.dart`

## Next suggested steps
- Apply the same “premium card + spacing” system to:
  - Home (`lib/home_page.dart`)
  - Create List (`lib/create_list_page.dart`)
  - My Lists (`lib/my_lists_page.dart`)
- Consider moving shared UI patterns into small reusable widgets.
