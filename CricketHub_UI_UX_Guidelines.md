# UI/UX Guidelines & Wireframe Specifications: CricketHub

## Document Info
| Attribute | Details |
| :--- | :--- |
| **Project Name** | CricketHub |
| **Document Version** | 1.0.0 |
| **Author** | Lead Product Manager / UX Lead |
| **Date** | October 24, 2023 |
| **Target Audience** | UI/UX Designers, Frontend Developers |

---

## 1. UX Core Principles
1. **Designed for the Outdoors:** Scorers and players will use this app in bright sunlight. High contrast is mandatory. 
2. **One-Handed Operation (Thumb Zone):** The Scoring Dashboard must allow a scorer to hold the phone in one hand and record balls with their thumb, without looking down for too long.
3. **Speed & Forgiveness:** Cricket is fast. Tapping a run must be instantaneous. Mistakes happen, so the "Undo" action must be prominent and frictionless.
4. **Data-Dense but Readable:** Fans want to see lots of numbers (Runs, Balls, Strike Rate, Overs) at a glance. Tabular, monospaced numerals should be used for stats to prevent text shifting.

---

## 2. Design System & Branding (UI Foundation)

### A. Color Palette
* **Theme Preference:** Default to **Dark Mode** (saves battery at the ground, reduces glare). Support Light Mode as a toggle.
* **Primary Color:** `#00BFA5` (Teal/Turquoise) - Represents the turf, feels fresh and modern.
* **Secondary/Accent:** `#FF6D00` (Vibrant Orange) - Used for primary actions, live indicators, and wickets (resembles a leather ball).
* **Background (Dark Mode):** `#121212` (Deep Charcoal) - Not pure black.
* **Card/Surface Color:** `#1E1E1E` (Slightly lighter charcoal to create depth).
* **Text Colors:**
  * Primary Text: `#FFFFFF` (100% white)
  * Secondary Text: `#A0A0A0` (Light grey for labels)
  * Danger/Error: `#FF5252` (Red - used for Out/Wickets)

### B. Typography
* **Font Family:** `Inter` or `Roboto` (Clean, highly legible sans-serif).
* **Numbers/Scores:** Must use **Tabular Lining** (so numbers align vertically in tables and don't jitter when the live score updates).
* **Hierarchy:**
  * **H1 (Main Score):** 48px, Bold (e.g., **145/4**)
  * **H2 (Screen Titles):** 24px, Semi-Bold
  * **Body (Player names, commentary):** 16px, Regular
  * **Caption (Labels, sub-text):** 12px, Medium

### C. UI Components
* **Bottom Sheets:** Prefer bottom sheets over new screens for secondary actions (e.g., picking a new batsman) to keep the user in the context of the match.
* **Touch Targets:** Minimum `48x48 pt` for all interactive elements to prevent mis-taps.
* **Cards:** Use softly rounded corners (`8px` or `12px` radius) with subtle drop shadows to separate match blocks.

---

## 3. Screen-by-Screen Wireframe Layouts

### Screen 1: Home Screen (Fan & Player View)
* **App Bar (Top):** Logo left, Profile Avatar right. Notification bell icon.
* **Carousel (Top 30%):** "Live Now" cards. 
  * Card UI: Team A vs Team B flags, Current Score, Overs, "LIVE" red pulsing dot.
* **Section 2 (Middle):** "My Upcoming Matches" (List view).
* **Section 3 (Bottom):** "Trending Tournaments" (Horizontal scroll).
* **Floating Action Button (FAB):** Large Primary Color FAB at bottom-right with a `+` icon (Expands to "Start Match" or "Create Team").
* **Bottom Nav:** Home | My Cricket | Tournaments | Menu.

### Screen 2: The Scoring Dashboard (The most critical screen)
* **Layout Rule:** Split screen into Context (Top 45%) and Actions (Bottom 55%).
* **Top App Bar:** Match title (e.g., "MI vs CSK"), "Undo" button positioned at top right.
* **Top Section (Context Block):**
  * Massive centralized Score: **145 / 4** 
  * Underneath: Overs: **15.2** | CRR: **9.45**
  * Batsmen Table (2 rows): Name, Runs, Balls, SR. *Highlight striker in Primary Color.*
  * Bowler Row: Name, Overs, Maidens, Runs, Wickets.
* **Bottom Section (Action Pad - Grid Layout):**
  * **Row 1 (Runs):** Huge square buttons for `0`, `1`, `2`, `3`
  * **Row 2 (Boundaries/Extras):** `4`, `6`, `Wide (WD)`, `No Ball (NB)`
  * **Row 3 (Others):** `Bye (B)`, `Leg Bye (LB)`, `Wicket` (Red Button)
* *Ergonomic note:* The `0` and `1` buttons should be closest to the natural thumb resting position, as they are the most tapped buttons.

### Screen 3: Live Viewer / Match Center (For Fans)
* **Header:** Sticky Header containing Team Names, Toss Info, and the Main Score.
* **TabBar:** Sticky beneath the header. Tabs: `Summary` | `Scorecard` | `Commentary` | `Info`.
* **Tab 1: Summary**
  * Current Partnership circle graph.
  * Recent Balls horizontal list: `[1] [0] [W] [4] [1] [6]`
  * Required Run Rate (if 2nd Innings).
* **Tab 2: Scorecard**
  * Classic table layout. 
  * Headers: Batsman | R | B | 4s | 6s | SR
  * "Did not bat" section at the bottom.
  * Fall of Wickets (FOW) timeline.
* **Tab 3: Commentary**
  * Vertical timeline.
  * Left side: Over/Ball number (e.g., **15.3**).
  * Right side: Bold text for event (e.g., **FOUR runs!**), normal text for description.

### Screen 4: Player Profile (Career Stats)
* **Header:** Cover photo (like Twitter), overlapping Circular Profile Avatar.
* **Bio Section:** Player Name, Role (Right-hand Batsman, Leg-break bowler), Team Badges.
* **Stats Grid (2 columns):**
  * Card 1: Matches Played
  * Card 2: Total Runs (Batting icon)
  * Card 3: Total Wickets (Ball icon)
  * Card 4: High Score / Best Bowling
* **Tabs at bottom:** `Recent Form` (List of last 5 matches) | `Teams` | `Gallery`.

---

## 4. Micro-Interactions & Animation Requirements

1. **Scoring a Boundary (4 or 6):** 
   * Trigger a subtle haptic feedback (vibration).
   * Brief burst/confetti animation originating from the tapped button.
2. **Fall of a Wicket:**
   * Heavy haptic feedback.
   * Screen flashes a subtle red tint.
   * "WICKET" slides in from the bottom, freezing the score screen until the scorer selects the dismissal type and new batsman.
3. **Live Viewer Syncing:**
   * When a fan is staring at the Live Score screen and the score updates via Firebase, the new run/ball should gently highlight briefly in yellow/orange to draw the eye to what just changed.
4. **Pull to Refresh:**
   * Standard loading indicator replaced with a spinning cricket ball.

---

## 5. Empty States & Error Handling

* **No Matches Live (Home Screen):** 
  * Illustration of a cricket pitch with stumps. Text: "No live action right now. Start a match or browse past games!"
* **Offline Mode (Scoring Screen):** 
  * A persistent, non-intrusive banner at the very top: *"You are offline. Scoring will sync automatically when the connection returns."* Icon: Cloud with a slash.
* **Empty Team Roster:** 
  * Text: "Your squad is empty." Large prominent button: "Invite Players via WhatsApp".

---
*End of Document*