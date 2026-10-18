// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get retry => 'Retry';

  @override
  String get cancel => 'Cancel';

  @override
  String get create => 'Create';

  @override
  String get quickActionsTitle => 'Make it a match day';

  @override
  String get quickActionsBody => 'Pick what you want to set up.';

  @override
  String get quickStartMatch => 'Start a match';

  @override
  String get quickStartMatchSub => 'Choose teams, toss and start scoring';

  @override
  String get quickCreateTeam => 'Create a team';

  @override
  String get quickCreateTeamSub => 'Build a squad for your next game';

  @override
  String get navHome => 'Home';

  @override
  String get navMyCricket => 'My Cricket';

  @override
  String get navTours => 'Tours';

  @override
  String get navInternational => 'International';

  @override
  String get navMenu => 'Menu';

  @override
  String get menuProfileTitle => 'Your profile';

  @override
  String get menuSeason => 'Your season';

  @override
  String get menuCareerStats => 'Career stats';

  @override
  String get menuComingSoon => 'COMING SOON';

  @override
  String get menuRuns => 'RUNS';

  @override
  String get menuWickets => 'WICKETS';

  @override
  String get menuAverage => 'AVERAGE';

  @override
  String get menuCareerBody =>
      'Your match history and leaderboards will live here.';

  @override
  String get menuExplore => 'Explore';

  @override
  String get menuGroundBooking => 'Ground booking';

  @override
  String get menuGroundBookingSub => 'Find a place for your next game';

  @override
  String get menuUmpireBooking => 'Umpire booking';

  @override
  String get menuUmpireBookingSub => 'Bring an official to match day';

  @override
  String get menuMyBookings => 'My bookings';

  @override
  String get menuMyBookingsSub => 'Your slots and QR codes';

  @override
  String get menuInternational => 'International scores';

  @override
  String get menuInternationalSub => 'Follow the wider cricket world';

  @override
  String get menuForOwners => 'For owners';

  @override
  String get menuOwnerPanel => 'Ground owner panel';

  @override
  String get menuOwnerPanelSub => 'List grounds, manage days, see payouts';

  @override
  String get menuUmpireDashboard => 'Umpire dashboard';

  @override
  String get menuUmpireDashboardSub => 'Your listing, rates and availability';

  @override
  String get menuLanguage => 'Language';

  @override
  String get menuLanguageSub => 'English, हिन्दी, தமிழ்';

  @override
  String get menuLogout => 'Log out';

  @override
  String get menuLogoutTitle => 'Log out?';

  @override
  String get menuLogoutBody =>
      'You can sign back in anytime to return to your teams.';

  @override
  String get menuTagline => 'CricketHub  ·  Local cricket. Pro level.';

  @override
  String get menuStaff => 'Staff';

  @override
  String get menuVerificationQueue => 'Verification queue';

  @override
  String get menuVerificationQueueSub => 'Approve grounds and umpires';

  @override
  String get menuPlayer => 'Player';

  @override
  String get intlTitle => 'International';

  @override
  String get intlTabLive => 'Live';

  @override
  String get intlTabUpcoming => 'Upcoming';

  @override
  String get intlTabRecent => 'Recent';

  @override
  String get intlLiveNow => 'LIVE';

  @override
  String get intlCompleted => 'COMPLETED';

  @override
  String get intlUpcomingLabel => 'UPCOMING';

  @override
  String get intlEmptyLive => 'No matches are live right now.';

  @override
  String get intlEmptyUpcoming => 'No upcoming matches listed.';

  @override
  String get intlEmptyRecent => 'No recent results yet.';

  @override
  String get intlDemoBanner => 'Demo data — add a CricAPI key for live scores.';

  @override
  String get intlNoKeyTitle => 'Live scores need a CricAPI key';

  @override
  String get intlNoKeyBody =>
      'Start the app with --dart-define=CRICAPI_KEY=your_key to pull real international matches, or preview the screen with demo data.';

  @override
  String get intlLoadDemo => 'Show demo matches';

  @override
  String get intlErrNetwork =>
      'Could not reach CricAPI. Check your connection.';

  @override
  String get intlErrInvalidKey =>
      'CricAPI rejected the key. Check CRICAPI_KEY.';

  @override
  String get intlErrRateLimited =>
      'Daily CricAPI limit reached. Try again tomorrow.';

  @override
  String get intlErrGeneric => 'Something went wrong loading scores.';

  @override
  String get intlScorecard => 'Scorecard';

  @override
  String get intlBatting => 'Batting';

  @override
  String get intlBowling => 'Bowling';

  @override
  String get intlBatter => 'Batter';

  @override
  String get intlBowler => 'Bowler';

  @override
  String get intlRunsShort => 'R';

  @override
  String get intlBallsShort => 'B';

  @override
  String get intlFours => '4s';

  @override
  String get intlSixes => '6s';

  @override
  String get intlStrikeRate => 'SR';

  @override
  String get intlOversShort => 'O';

  @override
  String get intlMaidensShort => 'M';

  @override
  String get intlEconomy => 'Econ';

  @override
  String get intlWicketsShort => 'W';

  @override
  String get intlVenue => 'Venue';

  @override
  String get intlNoScorecard =>
      'The scorecard is not published for this match yet.';

  @override
  String get languageTitle => 'Language';

  @override
  String get languageSubtitle => 'Choose the language for the app.';

  @override
  String get languageSystem => 'Device language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageHindi => 'हिन्दी';

  @override
  String get languageTamil => 'தமிழ்';
}
