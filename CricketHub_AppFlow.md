# App Flow Document: CricketHub

## Document Info
| Attribute | Details |
| :--- | :--- |
| **Project Name** | CricketHub |
| **Document Version** | 1.0.0 |
| **Author** | Smeet Jariwala , Aman Sinha |
| **Date** | September 21, 2026 |
| **Associated Docs** | PRD v1.0, TRD v1.0 |

---

## Guide to Reading this Document
* **[Screen Name]** represents a distinct UI screen or bottom-sheet in the app.
* **{Action}** represents a user interaction (button tap, form submit).
* **<Decision / Condition>** represents a system check or user choice.
* **->** represents navigation to the next step.

---

## 1. Global App Architecture (Bottom Navigation Map)
Once logged in, the user accesses features via a persistent Bottom Navigation Bar:
1. **[Home]:** Live matches, start match button, trending tournaments.
2. **[My Cricket]:** User's personal teams, past matches, career statistics.
3. **[Tournaments]:** Explore tournaments, points tables, leaderboards.
4. **[Menu/Profile]:** Settings, Ground Booking, Umpire Booking, Edit Profile.

---

## 2. Core User Journeys

### Flow 1: Authentication & Onboarding (All Users)
**Goal:** Authenticate the user and set up their basic player profile.

1. **[Splash Screen]** -> System initializes Firebase & Local DB.
2. <Is User Logged In?>
   * *Yes:* -> **[Home Screen]**
   * *No:* -> **[Login/Signup Screen]**
3. **[Login/Signup Screen]** -> {Enter Phone Number} -> {Tap Send OTP}
4. **[OTP Verification Screen]** -> {Enter OTP} -> {Verify}
5. <Is New User?>
   * *No:* -> **[Home Screen]**
   * *Yes:* -> **[Profile Setup Screen]**
6. **[Profile Setup Screen]** 
   * {Upload Avatar}
   * {Enter Name}
   * {Select Role: Batsman, Bowler, All-Rounder}
   * {Tap Save} -> **[Home Screen]**

---

### Flow 2: Team Creation & Roster Management (Organizer / Player)
**Goal:** Create a team to play in matches.

1. **[Home Screen]** -> {Tap 'My Cricket' Tab} -> **[My Cricket Screen]**
2. **[My Cricket Screen]** -> {Tap 'Teams' sub-tab} -> {Tap '+ Create Team' FAB}
3. **[Create Team Form]** 
   * {Enter Team Name, City}
   * {Upload Team Logo} 
   * {Tap Create} -> **[Team Dashboard]**
4. **[Team Dashboard]** -> {Tap 'Add Players'}
5. **[Add Players Modal]**
   * <Choose Method>
     * *Method A (Search):* {Search by phone/name} -> {Tap Add}
     * *Method B (Invite Link):* {Generate Link} -> {Share via WhatsApp}
6. {Player Accepts Invite} -> Roster Updated -> **[Team Dashboard]**

---

### Flow 3: Pre-Match Setup & Toss (Organizer / Scorer)
**Goal:** Configure match settings before the first ball is bowled.

1. **[Home Screen]** -> {Tap '+ Start Match' FAB} -> **[Select Teams Screen]**
2. **[Select Teams Screen]** -> {Select Team A} -> {Select Team B} -> {Next}
3. **[Match Settings Screen]**
   * {Enter Total Overs (e.g., 20)}
   * {Select Ball Type (Tennis/Leather)}
   * {Select Scorer (Assign self or other user)} -> {Tap Next}
4. **[Toss Screen]**
   * {Select who won the toss: Team A or Team B}
   * {Select what they chose: Bat or Bowl} -> {Tap Start Match}
5. **[Playing XI / Openers Screen]**
   * {Select Striker}
   * {Select Non-Striker}
   * {Select Opening Bowler} -> {Tap Let's Play} -> **[Scoring Dashboard]**

---

### Flow 4: Ball-by-Ball Scoring Loop (Scorer) - *Critical Path*
**Goal:** Record the events of the match offline or online.

1. **[Scoring Dashboard]** -> {Match is Live}
2. **User Input Phase:**
   * *If Run:* {Tap 0, 1, 2, 3, 4, 6} -> <System records ball>
   * *If Extra:* {Tap Wide, No Ball, Bye, Leg Bye} -> <System prompts for extra runs> -> {Confirm}
   * *If Wicket:* {Tap Wicket} -> **[Wicket Modal]** -> {Select Dismissal Type (Caught, Bowled, etc.)} -> {Select Fielder if applicable} -> {Select New Batsman} -> {Confirm}
   * *If Mistake:* {Tap Undo} -> <System rolls back last ball>
3. **System Evaluation Phase (Automatic):**
   * <Did runs scored result in odd number (1,3,5)?> -> *Yes:* {Auto-rotate strike}
   * <Is the over complete (6 legal deliveries)?> 
     * *Yes:* -> **[End of Over Modal]** -> {Auto-rotate strike} -> {Select New Bowler} -> Return to Step 2.
     * *No:* -> Continue to next ball.
   * <Is the innings complete (All out or target reached/overs finished)?>
     * *Yes:* -> **[Innings Break Screen]** -> {Select 2nd Innings Openers} -> Start 2nd Innings.
   * <Is the match complete?>
     * *Yes:* -> **[Match Summary / Post-Match Screen]** -> {End Match} -> <Triggers cloud sync and stats aggregation>.
4. **Background Process:** Every action taken in Step 2 is saved to the Local DB (Isar). If online, silently pushes to Firestore.

---

### Flow 5: Live Fan Viewing & Engagement (Fan)
**Goal:** Track a match in real-time.

1. **[Home Screen]** -> {Scroll to 'Live Matches' section} -> {Tap a specific match}
2. **[Live Match Dashboard]** -> Default view is *Summary Tab*.
   * <System listens to Firestore Snapshot stream - Updates every ball>
3. <User explores tabs:>
   * {Tap 'Scorecard'} -> **[Full Scorecard View]** (Batting, Bowling, Fall of Wickets)
   * {Tap 'Commentary'} -> **[Ball-by-Ball Text View]**
4. {Tap 'Follow' Bell Icon at top right} -> <System subscribes user to FCM topic>
5. *App is sent to background* -> Match event happens (e.g., Wicket) -> {User receives Push Notification} -> {Taps Notification} -> Deep-links back to **[Live Match Dashboard]**.

---

### Flow 6: Tournament Creation & Points Table (Phase 2)
**Goal:** Manage a group of teams in a league format.

1. **[Tournaments Tab]** -> {Tap '+ Create Tournament'}
2. **[Tournament Setup Screen]**
   * {Enter Name, Location, Dates}
   * {Select Format: Round-Robin, Knockout}
   * {Set Points System: Win=2, Tie=1, Loss=0} -> {Tap Create}
3. **[Tournament Dashboard - Admin View]** -> {Tap 'Add Teams'} -> {Select teams from app}
4. {Tap 'Generate Fixtures'} -> <System maps out matches based on Round-Robin logic>
5. As matches are completed via *Flow 4*, <System automatically updates> -> **[Points Table Tab]** (Calculates NRR automatically).

---
*End of Document*