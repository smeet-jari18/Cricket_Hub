<!-- # UI/UX Guidelines & Wireframe Specifications: CricketHub

## Document Info
| Attribute | Details |
| :--- | :--- |
| **Project Name** | CricketHub |
| **Document Version** | 1.0.0 |
| **Author** | Smeet Jariwala , Aman Sinha |
| **Date** | September 21, 2026 |
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
*End of Document* -->
















# UI/UX Specifications Document: CricketHub

## Document Info
| Attribute | Details |
| :--- | :--- |
| **Project Name** | CricketHub |
| **Document Version** | 2.0 (Visuals-Aligned) |
| **Design Style** | Light Theme, Card-based, High-Contrast |
| **Primary Audience** | Frontend Developers (Flutter), UI Designers |

---

## 1. Design System & Brand Identity

Based on the application screenshots, the UI employs a clean, modern, and daylight-optimized light theme, relying heavily on card-based layouts with soft shadows and rounded corners.

### A. Color Palette
* **Primary Brand (Teal):** Used for branding, active states, and primary navigation (e.g., "Send OTP" button, header gradients, active tabs).
* **Primary Action (Orange):** Used for major Call-to-Action (CTA) buttons at the bottom of forms (e.g., "Get Started", "Save Team & Continue", "Confirm Wicket").
* **Danger / Alert (Red):** Exclusively reserved for "LIVE" indicators and the "OUT / WICKET" action button.
* **Backgrounds:** 
  * App Background: Very light grey/off-white (`#F8F9FA` or similar).
  * Card Surfaces: Pure White (`#FFFFFF`) with subtle drop shadows.
* **Scoring Pad Tints (Crucial for UX):**
  * `4` (Four): Light Green background.
  * `6` (Six): Light Purple/Indigo background.
  * `WD` & `NB` (Extras): Light Yellow/Gold background.
  * Dot/Singles: White background.

### B. Typography & Iconography
* **Font Style:** Clean, modern Sans-Serif (e.g., Inter, Roboto, or SF Pro).
* **Data Presentation:** Tabular numbers are heavily used on the scoring pad and scorecards to ensure columns (R, B, 4s, 6s, SR) align perfectly.
* **Icons:** Outlined, minimalist icons (e.g., the teal circle + orange dot app logo).

### C. UI Components
* **Buttons:** 
  * Primary CTAs are large, full-width, pill-shaped (fully rounded edges) or heavily rounded rectangles.
  * Action buttons on the scorer pad have slight border radii (~8px).
* **Cards:** Used to group information (e.g., Matches, Tournaments). Feature `12px` to `16px` border radii.
* **Badges:** Pill-shaped tags are used extensively for roles (e.g., `CAPTAIN`, `PRO`, `LIVE`, `BATSMAN`, `BOWL`).

---

## 2. Screen-by-Screen Breakdown

### Screen 1: Splash / Landing Screen
* **Visuals:** Minimalist white background.
* **Elements:** 
  * Centered Logo (Teal circular seam with an orange dot).
  * Title: **CricketHub** (Bold, dark text).
  * Subtitle: "Local Cricket, Reimagined. Live scores, stats & community."
  * Feature Chips (Row of 3): "Ball by Ball", "Live Stats", "Club Feed".
* **Actions:** Large Orange "Get Started ->" button. "Log in" text link below.
* **Footer:** Sun icon with "DAYLIGHT-OPTIMIZED SCORER".

### Screen 2: Login / Onboarding
* **Header Image:** A faded image of a grassy cricket pitch with a "GRASSROOTS & CLUB HUB" pill badge.
* **Greeting:** "Welcome to CricketHub / Enter your mobile number to get an instant login OTP".
* **Form:**
  * Mobile Number input with Country Code dropdown (`IN +91`).
  * Full-width Teal CTA: "Send OTP ->".
  * "OR CONTINUE WITH" divider.
  * "Sign in with Google" outlined button.
* **Trust Badge:** "Official Grassroots Scorer Verified" with a green shield.
* **Bottom Floating Card:** "42 Live Matches - Scored live by local clubs today [EXPLORE >]".

### Screen 3: Home Dashboard (Player View)
* **App Bar:** Logo top left, Search icon, Notification bell (with red badge), Profile avatar top right.
* **Greeting Area:** "Hello, Rahul" with a "Playing Today" teal status pill.
* **Section 1: Live Matches (Carousel)**
  * Card shows League Name + format (e.g., T20). Red "LIVE" badge.
  * Team names with abbreviations (e.g., RS, KX) inside colored circles.
  * Highlights current striker stats and Current Run Rate (CRR).
  * Teal CTA inside card: "Full Scorecard".
* **Section 2: My Upcoming Match**
  * Date/Time, Opponent Name, Ground Location.
  * Overlapping player avatars + "11 Playing".
  * Button: "View Lineup".
* **Section 3: Trending Tournaments**
  * List view of cards (e.g., "Mumbai Monsoon Cup 2025" with Prize pool and team count). Status badges: `OPEN`, `CLOSING`.
* **Bottom Navigation:** Home, Matches, Tournaments, Profile. (Teal highlights active tab).

### Screen 4: Live Scorer (Main Action Pad)
* **Header:** Back arrow, Title (Live Scorer + Match details), "Undo" button (top right), Settings gear.
* **Match Context Block:**
  * "LIVE" badge + Team A vs Team B.
  * Massive Score: **145-4** | Overs: (16.3/20).
  * Target Info: Flag icon, Target 182, "Need 37 runs in 21 balls".
  * "THIS OVER" timeline: Circle indicators for recent balls (e.g., 1, 4, dot, W, 6, 1wd).
* **Stats Tables:** 
  * Batters: Striker highlighted with a green dot and `*`. Columns for R, B, 4s, 6s, SR.
  * Bowler: Name, O, M, R, W, ECON.
* **Action Pad (The Thumb Zone):**
  * **Row 1:** 0 (DOT), 1 (SINGLE), 2 (TWO), 3 (THREE). (White cards).
  * **Row 2:** 4 (FOUR - Green tint), 6 (SIX - Purple tint), WD (WIDE - Yellow tint), NB (NO BALL - Yellow tint).
  * **Row 3:** LB (LEG BYE), B (BYE), Massive Red **OUT / WICKET** button spanning two columns.
* **Footer Actions:** Swap Strike, Retire, Extras / End.

### Screen 5: Fall of Wicket Modal (Scorer Flow)
* **Header:** "Fall of Wicket" with current score context (145/4). Close `X` top right.
* **Step 1: Select Dismissed Batsman:** Two cards showing current batters. Active selection has a teal border and green radio button.
* **Step 2: Dismissal Method (Grid):**
  * Options: Caught, Bowled, Run Out, LBW, Stumped, Hit Wicket.
  * *UX Detail:* Subtitles under methods explain credit (e.g., Caught -> "Bowler credit", Run Out -> "Team credit").
  * Active selection turns solid Orange.
* **Step 3: Caught By Fielder:** Chip-based selection of fielders (e.g., Jaspreet S., Aman V.).
* **Step 4: Legal Delivery Toggle:** Green switch to count towards over completion.
* **Step 5: Next Batsman In:** Dropdown selector showing batting order.
* **Action:** Full-width Orange CTA "Confirm Wicket & Continue".

### Screen 6: Live Viewer / Scorecard (Fan Flow)
* **App Bar:** "MY CRICKET" subtitle. Bell icon to subscribe to notifications.
* **Sticky Header:**
  * Venue & Live Status.
  * Bold Scores: Royal Strikers CC (186/6) vs Kings XI CC (145/4).
  * Equation: "Need 42 runs in 21 balls", Toss info.
* **Tabs:** Summary, **Scorecard** (Active - underlined in teal), Commentary.
* **Innings Toggle:** Pills to switch between 1st Inn and 2nd Inn.
* **Scorecard Content:**
  * Clean table for Batters. Out status in grey ("c Samson b Jaspreet"), Not out in Teal ("not out").
  * Extras row and Total row.
  * "Fall of Wickets" block showing score-wicket (batsman, over).
  * "Bowling Attack" table.
* **Footer:** "Cheer for your team" interactive buttons (Clap, Fire icons with counters). "AUTO-REFRESHING EVERY 15S" text.
* **Bottom Navigation:** Home, My Cricket, Tournaments, Menu.

### Screen 7: Create Team (Organizer Flow)
* **Header:** "Create Team" with progress bar (STEP 1 OF 2: Basic Details & Squad).
* **Team Identity Section:**
  * Circular Avatar upload button.
  * Text fields: Team Name, City/Locality, Home Ground/Pitch.
  * "Team Jersey Shade" color picker (Teal, Navy, Red, Dark Green).
* **Team Roster Section:**
  * Counter badge: `6/11` players.
  * Search bar with "+ Add" button.
  * "Invite players via WhatsApp" teal banner/button.
  * Draggable/Removable List of Players. Shows Avatar, Name, Role Badge (Purple for All-Rounder/Bowler, Orange for Captain).
  * Info box: "Add at least 5 more players..."
* **Action:** Sticky Orange bottom button "Save Team & Continue ->".

### Screen 8: Player Profile
* **Header:** Large Teal gradient banner with a faint cricket pitch watermark.
* **Profile Header:** Overlapping circular avatar with a green verified checkmark. "Share" button on the right.
* **Bio:** Name ("Rahul Sharma"), "PRO" badge. Subtitle with batting/bowling style and city. Affiliation badges ("Captain @ Royal Strikers CC", "Division 1").
* **Career Statistics Block:** 
  * Toggle between "All Time" and "2025 Season".
  * 4 Grid Cards: 
    * Matches (48, 82% Win Rate).
    * Total Runs (1,640, Avg 38.5).
    * Total Wickets (34).
    * High Score (104* CENTURY - includes opponent info).
* **Club & Account Hub (Settings List):**
  * Menu items with distinct left-side icons and subtitles: Edit Profile & Kit, Ground Booking (Orange "COMING SOON" badge), App Settings (with dark mode toggle), Help & Rulebook, Logout (Red text).
* **Footer:** App Version number.

---
*End of UI/UX Specifications*