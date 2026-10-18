import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_ta.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('ta')
  ];

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @quickCreateTeam.
  ///
  /// In en, this message translates to:
  /// **'Create a team'**
  String get quickCreateTeam;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navMyCricket.
  ///
  /// In en, this message translates to:
  /// **'My Cricket'**
  String get navMyCricket;

  /// No description provided for @navTours.
  ///
  /// In en, this message translates to:
  /// **'Tours'**
  String get navTours;

  /// No description provided for @navInternational.
  ///
  /// In en, this message translates to:
  /// **'International'**
  String get navInternational;

  /// No description provided for @navMenu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get navMenu;

  /// No description provided for @menuProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Your profile'**
  String get menuProfileTitle;

  /// No description provided for @menuSeason.
  ///
  /// In en, this message translates to:
  /// **'Your season'**
  String get menuSeason;

  /// No description provided for @menuCareerStats.
  ///
  /// In en, this message translates to:
  /// **'Career stats'**
  String get menuCareerStats;

  /// No description provided for @menuComingSoon.
  ///
  /// In en, this message translates to:
  /// **'COMING SOON'**
  String get menuComingSoon;

  /// No description provided for @menuRuns.
  ///
  /// In en, this message translates to:
  /// **'RUNS'**
  String get menuRuns;

  /// No description provided for @menuWickets.
  ///
  /// In en, this message translates to:
  /// **'WICKETS'**
  String get menuWickets;

  /// No description provided for @menuAverage.
  ///
  /// In en, this message translates to:
  /// **'AVERAGE'**
  String get menuAverage;

  /// No description provided for @menuCareerBody.
  ///
  /// In en, this message translates to:
  /// **'Your match history and leaderboards will live here.'**
  String get menuCareerBody;

  /// No description provided for @menuExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get menuExplore;

  /// No description provided for @menuGroundBooking.
  ///
  /// In en, this message translates to:
  /// **'Ground booking'**
  String get menuGroundBooking;

  /// No description provided for @menuGroundBookingSub.
  ///
  /// In en, this message translates to:
  /// **'Find a place for your next game'**
  String get menuGroundBookingSub;

  /// No description provided for @menuUmpireBooking.
  ///
  /// In en, this message translates to:
  /// **'Umpire booking'**
  String get menuUmpireBooking;

  /// No description provided for @menuUmpireBookingSub.
  ///
  /// In en, this message translates to:
  /// **'Bring an official to match day'**
  String get menuUmpireBookingSub;

  /// No description provided for @menuMyBookings.
  ///
  /// In en, this message translates to:
  /// **'My bookings'**
  String get menuMyBookings;

  /// No description provided for @menuMyBookingsSub.
  ///
  /// In en, this message translates to:
  /// **'Your slots and QR codes'**
  String get menuMyBookingsSub;

  /// No description provided for @menuInternational.
  ///
  /// In en, this message translates to:
  /// **'International scores'**
  String get menuInternational;

  /// No description provided for @menuInternationalSub.
  ///
  /// In en, this message translates to:
  /// **'Follow the wider cricket world'**
  String get menuInternationalSub;

  /// No description provided for @menuForOwners.
  ///
  /// In en, this message translates to:
  /// **'For owners'**
  String get menuForOwners;

  /// No description provided for @menuOwnerPanel.
  ///
  /// In en, this message translates to:
  /// **'Ground owner panel'**
  String get menuOwnerPanel;

  /// No description provided for @menuOwnerPanelSub.
  ///
  /// In en, this message translates to:
  /// **'List grounds, manage days, see payouts'**
  String get menuOwnerPanelSub;

  /// No description provided for @menuUmpireDashboard.
  ///
  /// In en, this message translates to:
  /// **'Umpire dashboard'**
  String get menuUmpireDashboard;

  /// No description provided for @menuUmpireDashboardSub.
  ///
  /// In en, this message translates to:
  /// **'Your listing, rates and availability'**
  String get menuUmpireDashboardSub;

  /// No description provided for @menuLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get menuLanguage;

  /// No description provided for @menuLanguageSub.
  ///
  /// In en, this message translates to:
  /// **'English, हिन्दी, தமிழ்'**
  String get menuLanguageSub;

  /// No description provided for @menuLogout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get menuLogout;

  /// No description provided for @menuLogoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get menuLogoutTitle;

  /// No description provided for @menuLogoutBody.
  ///
  /// In en, this message translates to:
  /// **'You can sign back in anytime to return to your teams.'**
  String get menuLogoutBody;

  /// No description provided for @menuTagline.
  ///
  /// In en, this message translates to:
  /// **'CricketHub  ·  Local cricket. Pro level.'**
  String get menuTagline;

  /// No description provided for @menuStaff.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get menuStaff;

  /// No description provided for @menuVerificationQueue.
  ///
  /// In en, this message translates to:
  /// **'Verification queue'**
  String get menuVerificationQueue;

  /// No description provided for @menuVerificationQueueSub.
  ///
  /// In en, this message translates to:
  /// **'Approve grounds and umpires'**
  String get menuVerificationQueueSub;

  /// No description provided for @menuPlayer.
  ///
  /// In en, this message translates to:
  /// **'Player'**
  String get menuPlayer;

  /// No description provided for @intlTitle.
  ///
  /// In en, this message translates to:
  /// **'International'**
  String get intlTitle;

  /// No description provided for @intlTabLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get intlTabLive;

  /// No description provided for @intlTabUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get intlTabUpcoming;

  /// No description provided for @intlTabRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get intlTabRecent;

  /// No description provided for @intlLiveNow.
  ///
  /// In en, this message translates to:
  /// **'LIVE'**
  String get intlLiveNow;

  /// No description provided for @intlCompleted.
  ///
  /// In en, this message translates to:
  /// **'COMPLETED'**
  String get intlCompleted;

  /// No description provided for @intlUpcomingLabel.
  ///
  /// In en, this message translates to:
  /// **'UPCOMING'**
  String get intlUpcomingLabel;

  /// No description provided for @intlEmptyLive.
  ///
  /// In en, this message translates to:
  /// **'No matches are live right now.'**
  String get intlEmptyLive;

  /// No description provided for @intlEmptyUpcoming.
  ///
  /// In en, this message translates to:
  /// **'No upcoming matches listed.'**
  String get intlEmptyUpcoming;

  /// No description provided for @intlEmptyRecent.
  ///
  /// In en, this message translates to:
  /// **'No recent results yet.'**
  String get intlEmptyRecent;

  /// No description provided for @intlDemoBanner.
  ///
  /// In en, this message translates to:
  /// **'Demo data — add a CricAPI key for live scores.'**
  String get intlDemoBanner;

  /// No description provided for @intlNoKeyTitle.
  ///
  /// In en, this message translates to:
  /// **'Live scores need a CricAPI key'**
  String get intlNoKeyTitle;

  /// No description provided for @intlNoKeyBody.
  ///
  /// In en, this message translates to:
  /// **'Start the app with --dart-define=CRICAPI_KEY=your_key to pull real international matches, or preview the screen with demo data.'**
  String get intlNoKeyBody;

  /// No description provided for @intlLoadDemo.
  ///
  /// In en, this message translates to:
  /// **'Show demo matches'**
  String get intlLoadDemo;

  /// No description provided for @intlErrNetwork.
  ///
  /// In en, this message translates to:
  /// **'Could not reach CricAPI. Check your connection.'**
  String get intlErrNetwork;

  /// No description provided for @intlErrInvalidKey.
  ///
  /// In en, this message translates to:
  /// **'CricAPI rejected the key. Check CRICAPI_KEY.'**
  String get intlErrInvalidKey;

  /// No description provided for @intlErrRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Daily CricAPI limit reached. Try again tomorrow.'**
  String get intlErrRateLimited;

  /// No description provided for @intlErrGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong loading scores.'**
  String get intlErrGeneric;

  /// No description provided for @intlScorecard.
  ///
  /// In en, this message translates to:
  /// **'Scorecard'**
  String get intlScorecard;

  /// No description provided for @intlBatting.
  ///
  /// In en, this message translates to:
  /// **'Batting'**
  String get intlBatting;

  /// No description provided for @intlBowling.
  ///
  /// In en, this message translates to:
  /// **'Bowling'**
  String get intlBowling;

  /// No description provided for @intlBatter.
  ///
  /// In en, this message translates to:
  /// **'Batter'**
  String get intlBatter;

  /// No description provided for @intlBowler.
  ///
  /// In en, this message translates to:
  /// **'Bowler'**
  String get intlBowler;

  /// No description provided for @intlRunsShort.
  ///
  /// In en, this message translates to:
  /// **'R'**
  String get intlRunsShort;

  /// No description provided for @intlBallsShort.
  ///
  /// In en, this message translates to:
  /// **'B'**
  String get intlBallsShort;

  /// No description provided for @intlFours.
  ///
  /// In en, this message translates to:
  /// **'4s'**
  String get intlFours;

  /// No description provided for @intlSixes.
  ///
  /// In en, this message translates to:
  /// **'6s'**
  String get intlSixes;

  /// No description provided for @intlStrikeRate.
  ///
  /// In en, this message translates to:
  /// **'SR'**
  String get intlStrikeRate;

  /// No description provided for @intlOversShort.
  ///
  /// In en, this message translates to:
  /// **'O'**
  String get intlOversShort;

  /// No description provided for @intlMaidensShort.
  ///
  /// In en, this message translates to:
  /// **'M'**
  String get intlMaidensShort;

  /// No description provided for @intlEconomy.
  ///
  /// In en, this message translates to:
  /// **'Econ'**
  String get intlEconomy;

  /// No description provided for @intlWicketsShort.
  ///
  /// In en, this message translates to:
  /// **'W'**
  String get intlWicketsShort;

  /// No description provided for @intlVenue.
  ///
  /// In en, this message translates to:
  /// **'Venue'**
  String get intlVenue;

  /// No description provided for @intlNoScorecard.
  ///
  /// In en, this message translates to:
  /// **'The scorecard is not published for this match yet.'**
  String get intlNoScorecard;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// No description provided for @languageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the language for the app.'**
  String get languageSubtitle;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'Device language'**
  String get languageSystem;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageHindi.
  ///
  /// In en, this message translates to:
  /// **'हिन्दी'**
  String get languageHindi;

  /// No description provided for @languageTamil.
  ///
  /// In en, this message translates to:
  /// **'தமிழ்'**
  String get languageTamil;

  /// No description provided for @notificationActionOpen.
  ///
  /// In en, this message translates to:
  /// **'OPEN'**
  String get notificationActionOpen;

  /// No description provided for @offlineBanner.
  ///
  /// In en, this message translates to:
  /// **'Offline — scoring continues, syncs automatically'**
  String get offlineBanner;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'Local cricket. Pro level.'**
  String get splashTagline;

  /// No description provided for @commonPleaseSignIn.
  ///
  /// In en, this message translates to:
  /// **'Please sign in.'**
  String get commonPleaseSignIn;

  /// No description provided for @myBookingsErrLoad.
  ///
  /// In en, this message translates to:
  /// **'Could not load bookings'**
  String get myBookingsErrLoad;

  /// No description provided for @filtersTitle.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filtersTitle;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @umpiresTitle.
  ///
  /// In en, this message translates to:
  /// **'Umpires'**
  String get umpiresTitle;

  /// No description provided for @perHour.
  ///
  /// In en, this message translates to:
  /// **'per hour'**
  String get perHour;

  /// No description provided for @followLive.
  ///
  /// In en, this message translates to:
  /// **'Follow live'**
  String get followLive;

  /// No description provided for @liveNowBadge.
  ///
  /// In en, this message translates to:
  /// **'LIVE NOW'**
  String get liveNowBadge;

  /// No description provided for @confirmBooking.
  ///
  /// In en, this message translates to:
  /// **'Confirm booking'**
  String get confirmBooking;

  /// No description provided for @availabilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get availabilityTitle;

  /// No description provided for @noUmpireSelected.
  ///
  /// In en, this message translates to:
  /// **'No umpire selected.'**
  String get noUmpireSelected;

  /// No description provided for @myAvailability.
  ///
  /// In en, this message translates to:
  /// **'My availability'**
  String get myAvailability;

  /// No description provided for @chooseASlot.
  ///
  /// In en, this message translates to:
  /// **'Choose a slot'**
  String get chooseASlot;

  /// No description provided for @noGroundSelected.
  ///
  /// In en, this message translates to:
  /// **'No ground selected.'**
  String get noGroundSelected;

  /// No description provided for @closedOnThisDate.
  ///
  /// In en, this message translates to:
  /// **'Closed on this date'**
  String get closedOnThisDate;

  /// No description provided for @noSlotsConfigured.
  ///
  /// In en, this message translates to:
  /// **'No slots configured'**
  String get noSlotsConfigured;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @tournamentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Tournaments'**
  String get tournamentsTitle;

  /// No description provided for @createTournament.
  ///
  /// In en, this message translates to:
  /// **'Create tournament'**
  String get createTournament;

  /// No description provided for @tournamentsErrLoad.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load tournaments'**
  String get tournamentsErrLoad;

  /// No description provided for @checkConnection.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get checkConnection;

  /// No description provided for @tournamentsTagline.
  ///
  /// In en, this message translates to:
  /// **'Local cups, sorted.'**
  String get tournamentsTagline;

  /// No description provided for @tournamentsTaglineSub.
  ///
  /// In en, this message translates to:
  /// **'Follow fixtures, points and player leaders from one place.'**
  String get tournamentsTaglineSub;

  /// No description provided for @notificationFallbackTitle.
  ///
  /// In en, this message translates to:
  /// **'CricketHub update'**
  String get notificationFallbackTitle;

  /// No description provided for @notificationFallbackBody.
  ///
  /// In en, this message translates to:
  /// **'There is new match activity.'**
  String get notificationFallbackBody;

  /// No description provided for @homeAllCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'You’re all caught up.'**
  String get homeAllCaughtUp;

  /// No description provided for @homeHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Bring your cricket community together.'**
  String get homeHeroSubtitle;

  /// No description provided for @homeLiveOnPitch.
  ///
  /// In en, this message translates to:
  /// **'Live on the pitch'**
  String get homeLiveOnPitch;

  /// No description provided for @homeErrMatches.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load matches'**
  String get homeErrMatches;

  /// No description provided for @homeNoLive.
  ///
  /// In en, this message translates to:
  /// **'No live matches right now'**
  String get homeNoLive;

  /// No description provided for @homeNoLiveSub.
  ///
  /// In en, this message translates to:
  /// **'The next great innings could be yours.'**
  String get homeNoLiveSub;

  /// No description provided for @homeYourFixtures.
  ///
  /// In en, this message translates to:
  /// **'Your fixtures'**
  String get homeYourFixtures;

  /// No description provided for @homeNoFixtures.
  ///
  /// In en, this message translates to:
  /// **'No fixtures yet'**
  String get homeNoFixtures;

  /// No description provided for @homeNoFixturesSub.
  ///
  /// In en, this message translates to:
  /// **'Set up two teams and schedule your first game.'**
  String get homeNoFixturesSub;

  /// No description provided for @notificationsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTooltip;

  /// No description provided for @matchStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get matchStatusCompleted;

  /// No description provided for @matchStatusAbandoned.
  ///
  /// In en, this message translates to:
  /// **'Abandoned'**
  String get matchStatusAbandoned;

  /// No description provided for @matchStatusScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get matchStatusScheduled;

  /// No description provided for @myCricketErrLoad.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load your teams. Please try again.'**
  String get myCricketErrLoad;

  /// No description provided for @myCricketYourSquads.
  ///
  /// In en, this message translates to:
  /// **'Your squads'**
  String get myCricketYourSquads;

  /// No description provided for @myCricketSquadsSub.
  ///
  /// In en, this message translates to:
  /// **'Manage your teams and keep your playing group together.'**
  String get myCricketSquadsSub;

  /// No description provided for @myCricketEmptySquad.
  ///
  /// In en, this message translates to:
  /// **'Your squad is ready for its first player.'**
  String get myCricketEmptySquad;

  /// No description provided for @removePlayer.
  ///
  /// In en, this message translates to:
  /// **'Remove player'**
  String get removePlayer;

  /// No description provided for @myCricketStartTitle.
  ///
  /// In en, this message translates to:
  /// **'Start with your first team'**
  String get myCricketStartTitle;

  /// No description provided for @myCricketStartSub.
  ///
  /// In en, this message translates to:
  /// **'Add a team name and city, then invite your squad onto the field.'**
  String get myCricketStartSub;

  /// No description provided for @myCricketCreateFirst.
  ///
  /// In en, this message translates to:
  /// **'Create your first team'**
  String get myCricketCreateFirst;

  /// No description provided for @addPlayerHint.
  ///
  /// In en, this message translates to:
  /// **'Add a player'**
  String get addPlayerHint;

  /// No description provided for @addPlayerTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add player'**
  String get addPlayerTooltip;

  /// No description provided for @loginEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Welcome to CricketHub'**
  String get loginEyebrow;

  /// No description provided for @loginTagline.
  ///
  /// In en, this message translates to:
  /// **'Your team. Your ground. Your moment.'**
  String get loginTagline;

  /// No description provided for @loginErrMobile.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid 10-digit mobile number.'**
  String get loginErrMobile;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to play'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use your mobile number to get a one-time code.'**
  String get loginSubtitle;

  /// No description provided for @loginMobileLabel.
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get loginMobileLabel;

  /// No description provided for @loginOr.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get loginOr;

  /// No description provided for @loginGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get loginGoogle;

  /// No description provided for @loginTerms.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to our Terms of Service and Privacy Policy.'**
  String get loginTerms;

  /// No description provided for @otpHeadline.
  ///
  /// In en, this message translates to:
  /// **'Check your messages'**
  String get otpHeadline;

  /// No description provided for @otpTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify number'**
  String get otpTitle;

  /// No description provided for @otpErrCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code.'**
  String get otpErrCode;

  /// No description provided for @otpHint.
  ///
  /// In en, this message translates to:
  /// **'The code can take a few seconds to arrive. Keep this screen open.'**
  String get otpHint;

  /// No description provided for @profileErrName.
  ///
  /// In en, this message translates to:
  /// **'Add your name to continue.'**
  String get profileErrName;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Player profile'**
  String get profileTitle;

  /// No description provided for @profileHeadline.
  ///
  /// In en, this message translates to:
  /// **'Introduce yourself'**
  String get profileHeadline;

  /// No description provided for @profileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add a few details so your teammates know who’s at the crease.'**
  String get profileSubtitle;

  /// No description provided for @profileDetails.
  ///
  /// In en, this message translates to:
  /// **'Player details'**
  String get profileDetails;

  /// No description provided for @profileDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get profileDisplayName;

  /// No description provided for @profileNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Rahul Sharma'**
  String get profileNameHint;

  /// No description provided for @profileBattingStyle.
  ///
  /// In en, this message translates to:
  /// **'Batting style'**
  String get profileBattingStyle;

  /// No description provided for @profileBowlingStyle.
  ///
  /// In en, this message translates to:
  /// **'Bowling style'**
  String get profileBowlingStyle;

  /// No description provided for @oversCount.
  ///
  /// In en, this message translates to:
  /// **'{count} overs'**
  String oversCount(int count);

  /// No description provided for @homeHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Your ground.\nYour game.'**
  String get homeHeroTitle;

  /// No description provided for @loginHeadline.
  ///
  /// In en, this message translates to:
  /// **'Every match\nstarts here.'**
  String get loginHeadline;

  /// No description provided for @otpSentTo.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code we sent to {phone}.'**
  String otpSentTo(String phone);

  /// No description provided for @k_0_full_day_booking_not_offered.
  ///
  /// In en, this message translates to:
  /// **'0 = full-day booking not offered'**
  String get k_0_full_day_booking_not_offered;

  /// No description provided for @k_5_wicket_hauls.
  ///
  /// In en, this message translates to:
  /// **'5-WICKET HAULS'**
  String get k_5_wicket_hauls;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @about_you.
  ///
  /// In en, this message translates to:
  /// **'About you'**
  String get about_you;

  /// No description provided for @add_at_least_two_teams_before.
  ///
  /// In en, this message translates to:
  /// **'Add at least two teams before generating the schedule.'**
  String get add_at_least_two_teams_before;

  /// No description provided for @add_both_a_team_name_and.
  ///
  /// In en, this message translates to:
  /// **'Add both a team name and a city.'**
  String get add_both_a_team_name_and;

  /// No description provided for @add_ground.
  ///
  /// In en, this message translates to:
  /// **'Add ground'**
  String get add_ground;

  /// No description provided for @add_photo.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get add_photo;

  /// No description provided for @add_to_calendar.
  ///
  /// In en, this message translates to:
  /// **'Add to calendar'**
  String get add_to_calendar;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @admins_only.
  ///
  /// In en, this message translates to:
  /// **'Admins only'**
  String get admins_only;

  /// No description provided for @afternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get afternoon;

  /// No description provided for @ahmedabad.
  ///
  /// In en, this message translates to:
  /// **'Ahmedabad'**
  String get ahmedabad;

  /// No description provided for @amenities.
  ///
  /// In en, this message translates to:
  /// **'Amenities'**
  String get amenities;

  /// No description provided for @ask_the_organizer_to_regenerate_the.
  ///
  /// In en, this message translates to:
  /// **'Ask the organizer to regenerate the tournament schedule.'**
  String get ask_the_organizer_to_regenerate_the;

  /// No description provided for @batting_average.
  ///
  /// In en, this message translates to:
  /// **'BATTING AVERAGE'**
  String get batting_average;

  /// No description provided for @best_bowling.
  ///
  /// In en, this message translates to:
  /// **'BEST BOWLING'**
  String get best_bowling;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @back_to_home.
  ///
  /// In en, this message translates to:
  /// **'Back to home'**
  String get back_to_home;

  /// No description provided for @bat_first.
  ///
  /// In en, this message translates to:
  /// **'Bat first'**
  String get bat_first;

  /// No description provided for @batting_side_a.
  ///
  /// In en, this message translates to:
  /// **'Batting side A'**
  String get batting_side_a;

  /// No description provided for @become_an_umpire.
  ///
  /// In en, this message translates to:
  /// **'Become an umpire'**
  String get become_an_umpire;

  /// No description provided for @bengaluru.
  ///
  /// In en, this message translates to:
  /// **'Bengaluru'**
  String get bengaluru;

  /// No description provided for @bio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get bio;

  /// No description provided for @block_date.
  ///
  /// In en, this message translates to:
  /// **'Block date'**
  String get block_date;

  /// No description provided for @block_dates_you_cannot_officiate.
  ///
  /// In en, this message translates to:
  /// **'Block dates you cannot officiate'**
  String get block_dates_you_cannot_officiate;

  /// No description provided for @block_this_date.
  ///
  /// In en, this message translates to:
  /// **'Block this date?'**
  String get block_this_date;

  /// No description provided for @book_this_ground.
  ///
  /// In en, this message translates to:
  /// **'Book this ground'**
  String get book_this_ground;

  /// No description provided for @book_umpire.
  ///
  /// In en, this message translates to:
  /// **'Book umpire'**
  String get book_umpire;

  /// No description provided for @booking.
  ///
  /// In en, this message translates to:
  /// **'Booking'**
  String get booking;

  /// No description provided for @booking_confirmed.
  ///
  /// In en, this message translates to:
  /// **'Booking Confirmed'**
  String get booking_confirmed;

  /// No description provided for @booking_cancelled.
  ///
  /// In en, this message translates to:
  /// **'Booking cancelled.'**
  String get booking_cancelled;

  /// No description provided for @booking_confirmed_2.
  ///
  /// In en, this message translates to:
  /// **'Booking confirmed'**
  String get booking_confirmed_2;

  /// No description provided for @booking_details.
  ///
  /// In en, this message translates to:
  /// **'Booking details'**
  String get booking_details;

  /// No description provided for @booking_is_processing.
  ///
  /// In en, this message translates to:
  /// **'Booking is processing'**
  String get booking_is_processing;

  /// No description provided for @booking_requests.
  ///
  /// In en, this message translates to:
  /// **'Booking requests'**
  String get booking_requests;

  /// No description provided for @booking_verified.
  ///
  /// In en, this message translates to:
  /// **'Booking verified'**
  String get booking_verified;

  /// No description provided for @bowl_first.
  ///
  /// In en, this message translates to:
  /// **'Bowl first'**
  String get bowl_first;

  /// No description provided for @bowling_side_b.
  ///
  /// In en, this message translates to:
  /// **'Bowling side B'**
  String get bowling_side_b;

  /// No description provided for @bring_every_fixture_together.
  ///
  /// In en, this message translates to:
  /// **'Bring every fixture together'**
  String get bring_every_fixture_together;

  /// No description provided for @build_your_squad.
  ///
  /// In en, this message translates to:
  /// **'Build your squad'**
  String get build_your_squad;

  /// No description provided for @camera_scanning_runs_in_the_android.
  ///
  /// In en, this message translates to:
  /// **'Camera scanning runs in the Android and iOS app.'**
  String get camera_scanning_runs_in_the_android;

  /// No description provided for @cancel_booking.
  ///
  /// In en, this message translates to:
  /// **'Cancel booking'**
  String get cancel_booking;

  /// No description provided for @cancel_this_booking.
  ///
  /// In en, this message translates to:
  /// **'Cancel this booking?'**
  String get cancel_this_booking;

  /// No description provided for @cash_received_booking_confirmed.
  ///
  /// In en, this message translates to:
  /// **'Cash received — booking confirmed.'**
  String get cash_received_booking_confirmed;

  /// No description provided for @certifications.
  ///
  /// In en, this message translates to:
  /// **'Certifications'**
  String get certifications;

  /// No description provided for @choose_the_advancing_team.
  ///
  /// In en, this message translates to:
  /// **'Choose the advancing team'**
  String get choose_the_advancing_team;

  /// No description provided for @choose_the_sides.
  ///
  /// In en, this message translates to:
  /// **'Choose the sides'**
  String get choose_the_sides;

  /// No description provided for @choose_tournament_teams.
  ///
  /// In en, this message translates to:
  /// **'Choose tournament teams'**
  String get choose_tournament_teams;

  /// No description provided for @choose_your_teams_and_playing_format.
  ///
  /// In en, this message translates to:
  /// **'Choose your teams and playing format.'**
  String get choose_your_teams_and_playing_format;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @city_or_ground.
  ///
  /// In en, this message translates to:
  /// **'City or ground'**
  String get city_or_ground;

  /// No description provided for @clear_date.
  ///
  /// In en, this message translates to:
  /// **'Clear date'**
  String get clear_date;

  /// No description provided for @clear_search.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clear_search;

  /// No description provided for @closes.
  ///
  /// In en, this message translates to:
  /// **'Closes'**
  String get closes;

  /// No description provided for @competition_format.
  ///
  /// In en, this message translates to:
  /// **'Competition format'**
  String get competition_format;

  /// No description provided for @confirm_cash_you_received_from_organizers.
  ///
  /// In en, this message translates to:
  /// **'Confirm cash you received from organizers'**
  String get confirm_cash_you_received_from_organizers;

  /// No description provided for @confirm_the_toss_then_the_first.
  ///
  /// In en, this message translates to:
  /// **'Confirm the toss, then the first ball is yours.'**
  String get confirm_the_toss_then_the_first;

  /// No description provided for @confirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get confirmed;

  /// No description provided for @could_not_load_the_queue.
  ///
  /// In en, this message translates to:
  /// **'Could not load the queue'**
  String get could_not_load_the_queue;

  /// No description provided for @couldn_t_load_fixtures.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load fixtures'**
  String get couldn_t_load_fixtures;

  /// No description provided for @couldn_t_load_teams.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load teams.'**
  String get couldn_t_load_teams;

  /// No description provided for @couldn_t_load_teams_please_try.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load teams. Please try again.'**
  String get couldn_t_load_teams_please_try;

  /// No description provided for @couldn_t_load_the_match.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load the match.'**
  String get couldn_t_load_the_match;

  /// No description provided for @couldn_t_load_this_tournament.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load this tournament'**
  String get couldn_t_load_this_tournament;

  /// No description provided for @create_a_profile_and_get_verified.
  ///
  /// In en, this message translates to:
  /// **'Create a profile and get verified to start taking matches.'**
  String get create_a_profile_and_get_verified;

  /// No description provided for @create_a_team_before_building_your.
  ///
  /// In en, this message translates to:
  /// **'Create a team before building your tournament.'**
  String get create_a_team_before_building_your;

  /// No description provided for @create_at_least_two_teams_before.
  ///
  /// In en, this message translates to:
  /// **'Create at least two teams before scheduling a match.'**
  String get create_at_least_two_teams_before;

  /// No description provided for @create_team.
  ///
  /// In en, this message translates to:
  /// **'Create team'**
  String get create_team;

  /// No description provided for @create_your_first_ground.
  ///
  /// In en, this message translates to:
  /// **'Create your first ground'**
  String get create_your_first_ground;

  /// No description provided for @customize_the_default_awards_nrr_breaks.
  ///
  /// In en, this message translates to:
  /// **'Customize the default awards. NRR breaks points ties.'**
  String get customize_the_default_awards_nrr_breaks;

  /// No description provided for @day_rate.
  ///
  /// In en, this message translates to:
  /// **'Day rate (₹)'**
  String get day_rate;

  /// No description provided for @day.
  ///
  /// In en, this message translates to:
  /// **'Day ₹'**
  String get day;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @decline_this_request.
  ///
  /// In en, this message translates to:
  /// **'Decline this request?'**
  String get decline_this_request;

  /// No description provided for @directions.
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get directions;

  /// No description provided for @distance_city_centre.
  ///
  /// In en, this message translates to:
  /// **'Distance (city centre)'**
  String get distance_city_centre;

  /// No description provided for @economy.
  ///
  /// In en, this message translates to:
  /// **'ECONOMY'**
  String get economy;

  /// No description provided for @earnings.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get earnings;

  /// No description provided for @edit_ground.
  ///
  /// In en, this message translates to:
  /// **'Edit ground'**
  String get edit_ground;

  /// No description provided for @edit_profile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get edit_profile;

  /// No description provided for @end_date_must_be_after_the.
  ///
  /// In en, this message translates to:
  /// **'End date must be after the start date.'**
  String get end_date_must_be_after_the;

  /// No description provided for @ends_optional.
  ///
  /// In en, this message translates to:
  /// **'Ends (optional)'**
  String get ends_optional;

  /// No description provided for @equal_points_are_ranked_by_net.
  ///
  /// In en, this message translates to:
  /// **'Equal points are ranked by net run rate, then wins.'**
  String get equal_points_are_ranked_by_net;

  /// No description provided for @evening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get evening;

  /// No description provided for @experience.
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get experience;

  /// No description provided for @experience_years.
  ///
  /// In en, this message translates to:
  /// **'Experience (years)'**
  String get experience_years;

  /// No description provided for @extras.
  ///
  /// In en, this message translates to:
  /// **'Extras'**
  String get extras;

  /// No description provided for @fixtures.
  ///
  /// In en, this message translates to:
  /// **'FIXTURES'**
  String get fixtures;

  /// No description provided for @fall_of_wickets.
  ///
  /// In en, this message translates to:
  /// **'Fall of wickets'**
  String get fall_of_wickets;

  /// No description provided for @find_a_ground.
  ///
  /// In en, this message translates to:
  /// **'Find a Ground'**
  String get find_a_ground;

  /// No description provided for @fixtures_aren_t_ready_yet.
  ///
  /// In en, this message translates to:
  /// **'Fixtures aren’t ready yet'**
  String get fixtures_aren_t_ready_yet;

  /// No description provided for @follow_this_match_from_the_bell.
  ///
  /// In en, this message translates to:
  /// **'Follow this match from the bell above to get a push alert when play starts or a wicket falls.'**
  String get follow_this_match_from_the_bell;

  /// No description provided for @full_day.
  ///
  /// In en, this message translates to:
  /// **'Full day'**
  String get full_day;

  /// No description provided for @full_name.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get full_name;

  /// No description provided for @full_day_rate.
  ///
  /// In en, this message translates to:
  /// **'Full-day rate'**
  String get full_day_rate;

  /// No description provided for @full_day_rate_0_not_offered.
  ///
  /// In en, this message translates to:
  /// **'Full-day rate ₹ (0 = not offered)'**
  String get full_day_rate_0_not_offered;

  /// No description provided for @generate.
  ///
  /// In en, this message translates to:
  /// **'Generate'**
  String get generate;

  /// No description provided for @generate_fixture_schedule.
  ///
  /// In en, this message translates to:
  /// **'Generate fixture schedule?'**
  String get generate_fixture_schedule;

  /// No description provided for @get_directions.
  ///
  /// In en, this message translates to:
  /// **'Get directions'**
  String get get_directions;

  /// No description provided for @give_your_side_a_name_and.
  ///
  /// In en, this message translates to:
  /// **'Give your side a name and a home city. You can add players next.'**
  String get give_your_side_a_name_and;

  /// No description provided for @got_it.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get got_it;

  /// No description provided for @ground_name.
  ///
  /// In en, this message translates to:
  /// **'Ground name'**
  String get ground_name;

  /// No description provided for @ground_owner.
  ///
  /// In en, this message translates to:
  /// **'Ground owner'**
  String get ground_owner;

  /// No description provided for @high_score.
  ///
  /// In en, this message translates to:
  /// **'HIGH SCORE'**
  String get high_score;

  /// No description provided for @home_city.
  ///
  /// In en, this message translates to:
  /// **'Home city'**
  String get home_city;

  /// No description provided for @hourly_rate.
  ///
  /// In en, this message translates to:
  /// **'Hourly rate (₹)'**
  String get hourly_rate;

  /// No description provided for @hourly.
  ///
  /// In en, this message translates to:
  /// **'Hourly ₹'**
  String get hourly;

  /// No description provided for @how_long_will_you_play.
  ///
  /// In en, this message translates to:
  /// **'How long will you play?'**
  String get how_long_will_you_play;

  /// No description provided for @how_was_the_batter_out.
  ///
  /// In en, this message translates to:
  /// **'How was the batter out?'**
  String get how_was_the_batter_out;

  /// No description provided for @hyderabad.
  ///
  /// In en, this message translates to:
  /// **'Hyderabad'**
  String get hyderabad;

  /// No description provided for @innings_1.
  ///
  /// In en, this message translates to:
  /// **'INNINGS 1'**
  String get innings_1;

  /// No description provided for @innings_summary.
  ///
  /// In en, this message translates to:
  /// **'Innings summary'**
  String get innings_summary;

  /// No description provided for @it_may_have_been_removed_by.
  ///
  /// In en, this message translates to:
  /// **'It may have been removed by its organizer.'**
  String get it_may_have_been_removed_by;

  /// No description provided for @keep_it.
  ///
  /// In en, this message translates to:
  /// **'Keep it'**
  String get keep_it;

  /// No description provided for @knockout_2.
  ///
  /// In en, this message translates to:
  /// **'Knockout'**
  String get knockout_2;

  /// No description provided for @knockout_bracket.
  ///
  /// In en, this message translates to:
  /// **'Knockout bracket'**
  String get knockout_bracket;

  /// No description provided for @league_standings.
  ///
  /// In en, this message translates to:
  /// **'League standings'**
  String get league_standings;

  /// No description provided for @leagues_officiated_playing_background.
  ///
  /// In en, this message translates to:
  /// **'Leagues officiated, playing background…'**
  String get leagues_officiated_playing_background;

  /// No description provided for @leave_a_review.
  ///
  /// In en, this message translates to:
  /// **'Leave a review'**
  String get leave_a_review;

  /// No description provided for @list_your_ground.
  ///
  /// In en, this message translates to:
  /// **'List your ground'**
  String get list_your_ground;

  /// No description provided for @list_your_ground_and_start_taking.
  ///
  /// In en, this message translates to:
  /// **'List your ground and start taking bookings.'**
  String get list_your_ground_and_start_taking;

  /// No description provided for @list_yourself_so_organizers_can_book.
  ///
  /// In en, this message translates to:
  /// **'List yourself so organizers can book you for matches.'**
  String get list_yourself_so_organizers_can_book;

  /// No description provided for @live_totals_from_completed_fixtures.
  ///
  /// In en, this message translates to:
  /// **'Live totals from completed fixtures.'**
  String get live_totals_from_completed_fixtures;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @loss.
  ///
  /// In en, this message translates to:
  /// **'Loss'**
  String get loss;

  /// No description provided for @matches.
  ///
  /// In en, this message translates to:
  /// **'MATCHES'**
  String get matches;

  /// No description provided for @my_grounds.
  ///
  /// In en, this message translates to:
  /// **'MY GROUNDS'**
  String get my_grounds;

  /// No description provided for @maintenance_private_tournament.
  ///
  /// In en, this message translates to:
  /// **'Maintenance, private tournament…'**
  String get maintenance_private_tournament;

  /// No description provided for @match_center.
  ///
  /// In en, this message translates to:
  /// **'Match Center'**
  String get match_center;

  /// No description provided for @match_setup.
  ///
  /// In en, this message translates to:
  /// **'Match Setup'**
  String get match_setup;

  /// No description provided for @match_closed_the_player_can_rate.
  ///
  /// In en, this message translates to:
  /// **'Match closed. The player can rate you now.'**
  String get match_closed_the_player_can_rate;

  /// No description provided for @match_day_starts_here.
  ///
  /// In en, this message translates to:
  /// **'Match day starts here'**
  String get match_day_starts_here;

  /// No description provided for @match_format.
  ///
  /// In en, this message translates to:
  /// **'Match format'**
  String get match_format;

  /// No description provided for @match_not_found.
  ///
  /// In en, this message translates to:
  /// **'Match not found'**
  String get match_not_found;

  /// No description provided for @money.
  ///
  /// In en, this message translates to:
  /// **'Money'**
  String get money;

  /// No description provided for @morning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get morning;

  /// No description provided for @most_tournament_runs.
  ///
  /// In en, this message translates to:
  /// **'Most tournament runs'**
  String get most_tournament_runs;

  /// No description provided for @most_tournament_wickets.
  ///
  /// In en, this message translates to:
  /// **'Most tournament wickets'**
  String get most_tournament_wickets;

  /// No description provided for @mumbai.
  ///
  /// In en, this message translates to:
  /// **'Mumbai'**
  String get mumbai;

  /// No description provided for @nrr_uses_cumulative_runs_scored_and.
  ///
  /// In en, this message translates to:
  /// **'NRR uses cumulative runs scored and conceded divided by legal balls. A completed all-out innings counts the full overs quota.'**
  String get nrr_uses_cumulative_runs_scored_and;

  /// No description provided for @name_bio_experience_and_rates.
  ///
  /// In en, this message translates to:
  /// **'Name, bio, experience and rates'**
  String get name_bio_experience_and_rates;

  /// No description provided for @new_batter_name.
  ///
  /// In en, this message translates to:
  /// **'New batter name'**
  String get new_batter_name;

  /// No description provided for @no_amenities_listed.
  ///
  /// In en, this message translates to:
  /// **'No amenities listed'**
  String get no_amenities_listed;

  /// No description provided for @no_balls_recorded_yet.
  ///
  /// In en, this message translates to:
  /// **'No balls recorded yet.'**
  String get no_balls_recorded_yet;

  /// No description provided for @no_balls_yet_waiting_for_the.
  ///
  /// In en, this message translates to:
  /// **'No balls yet — waiting for the first over!'**
  String get no_balls_yet_waiting_for_the;

  /// No description provided for @no_booking_requests_yet.
  ///
  /// In en, this message translates to:
  /// **'No booking requests yet'**
  String get no_booking_requests_yet;

  /// No description provided for @no_booking_selected.
  ///
  /// In en, this message translates to:
  /// **'No booking selected.'**
  String get no_booking_selected;

  /// No description provided for @no_fixtures_found.
  ///
  /// In en, this message translates to:
  /// **'No fixtures found'**
  String get no_fixtures_found;

  /// No description provided for @no_grounds_match_your_filters.
  ///
  /// In en, this message translates to:
  /// **'No grounds match your filters'**
  String get no_grounds_match_your_filters;

  /// No description provided for @no_grounds_waiting.
  ///
  /// In en, this message translates to:
  /// **'No grounds waiting'**
  String get no_grounds_waiting;

  /// No description provided for @no_grounds_yet.
  ///
  /// In en, this message translates to:
  /// **'No grounds yet'**
  String get no_grounds_yet;

  /// No description provided for @no_player_stats_yet.
  ///
  /// In en, this message translates to:
  /// **'No player stats yet.'**
  String get no_player_stats_yet;

  /// No description provided for @no_result.
  ///
  /// In en, this message translates to:
  /// **'No result'**
  String get no_result;

  /// No description provided for @no_reviews_yet.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet'**
  String get no_reviews_yet;

  /// No description provided for @no_reviews_yet_2.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet.'**
  String get no_reviews_yet_2;

  /// No description provided for @no_teams_added_yet_choose_teams.
  ///
  /// In en, this message translates to:
  /// **'No teams added yet. Choose teams from your CricketHub team list to continue.'**
  String get no_teams_added_yet_choose_teams;

  /// No description provided for @no_umpire_profile_loaded.
  ///
  /// In en, this message translates to:
  /// **'No umpire profile loaded.'**
  String get no_umpire_profile_loaded;

  /// No description provided for @no_umpires_waiting.
  ///
  /// In en, this message translates to:
  /// **'No umpires waiting'**
  String get no_umpires_waiting;

  /// No description provided for @non_striker_name.
  ///
  /// In en, this message translates to:
  /// **'Non-striker name'**
  String get non_striker_name;

  /// No description provided for @none_listed_yet.
  ///
  /// In en, this message translates to:
  /// **'None listed yet.'**
  String get none_listed_yet;

  /// No description provided for @not_valid.
  ///
  /// In en, this message translates to:
  /// **'Not valid'**
  String get not_valid;

  /// No description provided for @not_yet.
  ///
  /// In en, this message translates to:
  /// **'Not yet'**
  String get not_yet;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @orange_cap.
  ///
  /// In en, this message translates to:
  /// **'ORANGE CAP'**
  String get orange_cap;

  /// No description provided for @overs.
  ///
  /// In en, this message translates to:
  /// **'OVERS'**
  String get overs;

  /// No description provided for @one_last_call.
  ///
  /// In en, this message translates to:
  /// **'One last call'**
  String get one_last_call;

  /// No description provided for @open_crickethub_on_a_phone_to.
  ///
  /// In en, this message translates to:
  /// **'Open CricketHub on a phone to verify a booking QR.'**
  String get open_crickethub_on_a_phone_to;

  /// No description provided for @open_calendar.
  ///
  /// In en, this message translates to:
  /// **'Open calendar'**
  String get open_calendar;

  /// No description provided for @opening_bowler.
  ///
  /// In en, this message translates to:
  /// **'Opening bowler'**
  String get opening_bowler;

  /// No description provided for @opens.
  ///
  /// In en, this message translates to:
  /// **'Opens'**
  String get opens;

  /// No description provided for @or_type_a_new_bowler.
  ///
  /// In en, this message translates to:
  /// **'Or type a new bowler'**
  String get or_type_a_new_bowler;

  /// No description provided for @over_complete_next_bowler.
  ///
  /// In en, this message translates to:
  /// **'Over complete! Next bowler'**
  String get over_complete_next_bowler;

  /// No description provided for @overs_per_match.
  ///
  /// In en, this message translates to:
  /// **'Overs per match'**
  String get overs_per_match;

  /// No description provided for @pick_a_date.
  ///
  /// In en, this message translates to:
  /// **'PICK A DATE'**
  String get pick_a_date;

  /// No description provided for @pick_a_window.
  ///
  /// In en, this message translates to:
  /// **'PICK A WINDOW'**
  String get pick_a_window;

  /// No description provided for @price_breakdown.
  ///
  /// In en, this message translates to:
  /// **'PRICE BREAKDOWN'**
  String get price_breakdown;

  /// No description provided for @pts.
  ///
  /// In en, this message translates to:
  /// **'PTS'**
  String get pts;

  /// No description provided for @purple_cap.
  ///
  /// In en, this message translates to:
  /// **'PURPLE CAP'**
  String get purple_cap;

  /// No description provided for @participating_teams.
  ///
  /// In en, this message translates to:
  /// **'Participating teams'**
  String get participating_teams;

  /// No description provided for @payout_earned.
  ///
  /// In en, this message translates to:
  /// **'Payout earned'**
  String get payout_earned;

  /// No description provided for @pending_settlement.
  ///
  /// In en, this message translates to:
  /// **'Pending settlement'**
  String get pending_settlement;

  /// No description provided for @people.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get people;

  /// No description provided for @phone_number.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phone_number;

  /// No description provided for @photos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get photos;

  /// No description provided for @pick_a_rating_from_1_to.
  ///
  /// In en, this message translates to:
  /// **'Pick a rating from 1 to 5 first.'**
  String get pick_a_rating_from_1_to;

  /// No description provided for @pick_your_slot.
  ///
  /// In en, this message translates to:
  /// **'Pick your slot'**
  String get pick_your_slot;

  /// No description provided for @pitch_quality_lights_changing_rooms_staff.
  ///
  /// In en, this message translates to:
  /// **'Pitch quality, lights, changing rooms, staff…'**
  String get pitch_quality_lights_changing_rooms_staff;

  /// No description provided for @pitch_type.
  ///
  /// In en, this message translates to:
  /// **'Pitch type'**
  String get pitch_type;

  /// No description provided for @player_leaders_appear_here.
  ///
  /// In en, this message translates to:
  /// **'Player leaders appear here'**
  String get player_leaders_appear_here;

  /// No description provided for @point_at_the_organizer_s_qr.
  ///
  /// In en, this message translates to:
  /// **'Point at the organizer’s QR'**
  String get point_at_the_organizer_s_qr;

  /// No description provided for @points_and_nrr_are_calculated_automatically.
  ///
  /// In en, this message translates to:
  /// **'Points and NRR are calculated automatically after each completed fixture.'**
  String get points_and_nrr_are_calculated_automatically;

  /// No description provided for @points_configuration.
  ///
  /// In en, this message translates to:
  /// **'Points configuration'**
  String get points_configuration;

  /// No description provided for @points_system.
  ///
  /// In en, this message translates to:
  /// **'Points system'**
  String get points_system;

  /// No description provided for @price_low_high.
  ///
  /// In en, this message translates to:
  /// **'Price: Low → High'**
  String get price_low_high;

  /// No description provided for @pricing.
  ///
  /// In en, this message translates to:
  /// **'Pricing'**
  String get pricing;

  /// No description provided for @profile_photo.
  ///
  /// In en, this message translates to:
  /// **'Profile photo'**
  String get profile_photo;

  /// No description provided for @profile_updated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated.'**
  String get profile_updated;

  /// No description provided for @pune.
  ///
  /// In en, this message translates to:
  /// **'Pune'**
  String get pune;

  /// No description provided for @reviews.
  ///
  /// In en, this message translates to:
  /// **'REVIEWS'**
  String get reviews;

  /// No description provided for @rating_high_low.
  ///
  /// In en, this message translates to:
  /// **'Rating: High → Low'**
  String get rating_high_low;

  /// No description provided for @ready_to_bowl.
  ///
  /// In en, this message translates to:
  /// **'Ready to bowl'**
  String get ready_to_bowl;

  /// No description provided for @reason_optional.
  ///
  /// In en, this message translates to:
  /// **'Reason (optional)'**
  String get reason_optional;

  /// No description provided for @recent_balls.
  ///
  /// In en, this message translates to:
  /// **'Recent balls'**
  String get recent_balls;

  /// No description provided for @recent_form.
  ///
  /// In en, this message translates to:
  /// **'Recent form'**
  String get recent_form;

  /// No description provided for @refund.
  ///
  /// In en, this message translates to:
  /// **'Refund'**
  String get refund;

  /// No description provided for @request_declined.
  ///
  /// In en, this message translates to:
  /// **'Request declined.'**
  String get request_declined;

  /// No description provided for @resolve_tie.
  ///
  /// In en, this message translates to:
  /// **'Resolve tie'**
  String get resolve_tie;

  /// No description provided for @reviews_come_from_a_completed_booking.
  ///
  /// In en, this message translates to:
  /// **'Reviews come from a completed booking.'**
  String get reviews_come_from_a_completed_booking;

  /// No description provided for @round_robin_2.
  ///
  /// In en, this message translates to:
  /// **'Round robin'**
  String get round_robin_2;

  /// No description provided for @show_this_at_the_ground.
  ///
  /// In en, this message translates to:
  /// **'SHOW THIS AT THE GROUND'**
  String get show_this_at_the_ground;

  /// No description provided for @side_a.
  ///
  /// In en, this message translates to:
  /// **'SIDE A'**
  String get side_a;

  /// No description provided for @side_b.
  ///
  /// In en, this message translates to:
  /// **'SIDE B'**
  String get side_b;

  /// No description provided for @strike_rate.
  ///
  /// In en, this message translates to:
  /// **'STRIKE RATE'**
  String get strike_rate;

  /// No description provided for @save_selected_teams.
  ///
  /// In en, this message translates to:
  /// **'Save selected teams'**
  String get save_selected_teams;

  /// No description provided for @scan_qr.
  ///
  /// In en, this message translates to:
  /// **'Scan QR'**
  String get scan_qr;

  /// No description provided for @scan_a_booking_qr.
  ///
  /// In en, this message translates to:
  /// **'Scan a booking QR'**
  String get scan_a_booking_qr;

  /// No description provided for @scan_again.
  ///
  /// In en, this message translates to:
  /// **'Scan again'**
  String get scan_again;

  /// No description provided for @scan_booking_qr.
  ///
  /// In en, this message translates to:
  /// **'Scan booking QR'**
  String get scan_booking_qr;

  /// No description provided for @scan_next.
  ///
  /// In en, this message translates to:
  /// **'Scan next'**
  String get scan_next;

  /// No description provided for @search_grounds_city_pitch.
  ///
  /// In en, this message translates to:
  /// **'Search grounds, city, pitch...'**
  String get search_grounds_city_pitch;

  /// No description provided for @send_back.
  ///
  /// In en, this message translates to:
  /// **'Send back'**
  String get send_back;

  /// No description provided for @send_in.
  ///
  /// In en, this message translates to:
  /// **'Send in'**
  String get send_in;

  /// No description provided for @set_the_competition_rules_first_you.
  ///
  /// In en, this message translates to:
  /// **'Set the competition rules first. You can choose app teams and generate the schedule next.'**
  String get set_the_competition_rules_first_you;

  /// No description provided for @set_up_a_match.
  ///
  /// In en, this message translates to:
  /// **'Set up a match'**
  String get set_up_a_match;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @slot_length.
  ///
  /// In en, this message translates to:
  /// **'Slot length'**
  String get slot_length;

  /// No description provided for @starts.
  ///
  /// In en, this message translates to:
  /// **'Starts'**
  String get starts;

  /// No description provided for @striker_name.
  ///
  /// In en, this message translates to:
  /// **'Striker name'**
  String get striker_name;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @submitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted.'**
  String get submitted;

  /// No description provided for @t_nr.
  ///
  /// In en, this message translates to:
  /// **'T/NR'**
  String get t_nr;

  /// No description provided for @target.
  ///
  /// In en, this message translates to:
  /// **'TARGET'**
  String get target;

  /// No description provided for @team.
  ///
  /// In en, this message translates to:
  /// **'TEAM'**
  String get team;

  /// No description provided for @teams.
  ///
  /// In en, this message translates to:
  /// **'TEAMS'**
  String get teams;

  /// No description provided for @this_over.
  ///
  /// In en, this message translates to:
  /// **'THIS OVER'**
  String get this_over;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'TODAY'**
  String get today;

  /// No description provided for @total_net_payout.
  ///
  /// In en, this message translates to:
  /// **'TOTAL NET PAYOUT'**
  String get total_net_payout;

  /// No description provided for @total_runs.
  ///
  /// In en, this message translates to:
  /// **'TOTAL RUNS'**
  String get total_runs;

  /// No description provided for @team_details.
  ///
  /// In en, this message translates to:
  /// **'Team details'**
  String get team_details;

  /// No description provided for @team_name.
  ///
  /// In en, this message translates to:
  /// **'Team name'**
  String get team_name;

  /// No description provided for @tennis_ball_by_default_toss_comes.
  ///
  /// In en, this message translates to:
  /// **'Tennis ball by default · toss comes next'**
  String get tennis_ball_by_default_toss_comes;

  /// No description provided for @thanks_for_the_review.
  ///
  /// In en, this message translates to:
  /// **'Thanks for the review!'**
  String get thanks_for_the_review;

  /// No description provided for @the_orange_cap_and_purple_cap.
  ///
  /// In en, this message translates to:
  /// **'The Orange Cap and Purple Cap lists update from completed tournament scorecards.'**
  String get the_orange_cap_and_purple_cap;

  /// No description provided for @the_ground_owner_scans_this_to.
  ///
  /// In en, this message translates to:
  /// **'The ground owner scans this to verify your booking.'**
  String get the_ground_owner_scans_this_to;

  /// No description provided for @the_organizer_can_add_teams_and.
  ///
  /// In en, this message translates to:
  /// **'The organizer can add teams and generate the schedule from Overview.'**
  String get the_organizer_can_add_teams_and;

  /// No description provided for @the_organizer_is_still_preparing_the.
  ///
  /// In en, this message translates to:
  /// **'The organizer is still preparing the team list and fixtures.'**
  String get the_organizer_is_still_preparing_the;

  /// No description provided for @the_scorecard_will_fill_in_as.
  ///
  /// In en, this message translates to:
  /// **'The scorecard will fill in as innings are completed.'**
  String get the_scorecard_will_fill_in_as;

  /// No description provided for @the_table_is_ready_for_play.
  ///
  /// In en, this message translates to:
  /// **'The table is ready for play'**
  String get the_table_is_ready_for_play;

  /// No description provided for @the_toss.
  ///
  /// In en, this message translates to:
  /// **'The toss'**
  String get the_toss;

  /// No description provided for @there_is_no_league_points_table.
  ///
  /// In en, this message translates to:
  /// **'There is no league points table for elimination matches. Follow each round in the Fixtures tab.'**
  String get there_is_no_league_points_table;

  /// No description provided for @tie.
  ///
  /// In en, this message translates to:
  /// **'Tie'**
  String get tie;

  /// No description provided for @tied_fixture_organizer_decision_required.
  ///
  /// In en, this message translates to:
  /// **'Tied fixture · organizer decision required'**
  String get tied_fixture_organizer_decision_required;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @tournament_details.
  ///
  /// In en, this message translates to:
  /// **'Tournament details'**
  String get tournament_details;

  /// No description provided for @tournament_leaders.
  ///
  /// In en, this message translates to:
  /// **'Tournament leaders'**
  String get tournament_leaders;

  /// No description provided for @tournament_name.
  ///
  /// In en, this message translates to:
  /// **'Tournament name'**
  String get tournament_name;

  /// No description provided for @tournament_not_found.
  ///
  /// In en, this message translates to:
  /// **'Tournament not found'**
  String get tournament_not_found;

  /// No description provided for @try_removing_a_filter_or_switch.
  ///
  /// In en, this message translates to:
  /// **'Try removing a filter or switch city.'**
  String get try_removing_a_filter_or_switch;

  /// No description provided for @umpire.
  ///
  /// In en, this message translates to:
  /// **'Umpire'**
  String get umpire;

  /// No description provided for @umpire_requested.
  ///
  /// In en, this message translates to:
  /// **'Umpire requested'**
  String get umpire_requested;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @up_to_5_photos_5mb_each.
  ///
  /// In en, this message translates to:
  /// **'Up to 5 photos, 5MB each. The first one becomes the cover image.'**
  String get up_to_5_photos_5mb_each;

  /// No description provided for @vs.
  ///
  /// In en, this message translates to:
  /// **'VS'**
  String get vs;

  /// No description provided for @weekly_settlements.
  ///
  /// In en, this message translates to:
  /// **'WEEKLY SETTLEMENTS'**
  String get weekly_settlements;

  /// No description provided for @wicket.
  ///
  /// In en, this message translates to:
  /// **'WICKET'**
  String get wicket;

  /// No description provided for @wicket_next_batter.
  ///
  /// In en, this message translates to:
  /// **'WICKET! Next batter'**
  String get wicket_next_batter;

  /// No description provided for @weekday_rate_per_hour.
  ///
  /// In en, this message translates to:
  /// **'Weekday rate per hour'**
  String get weekday_rate_per_hour;

  /// No description provided for @weekday_hr.
  ///
  /// In en, this message translates to:
  /// **'Weekday ₹/hr'**
  String get weekday_hr;

  /// No description provided for @weekend_rate_per_hour.
  ///
  /// In en, this message translates to:
  /// **'Weekend rate per hour'**
  String get weekend_rate_per_hour;

  /// No description provided for @weekend_hr.
  ///
  /// In en, this message translates to:
  /// **'Weekend ₹/hr'**
  String get weekend_hr;

  /// No description provided for @weeks.
  ///
  /// In en, this message translates to:
  /// **'Weeks'**
  String get weeks;

  /// No description provided for @what_did_they_choose.
  ///
  /// In en, this message translates to:
  /// **'What did they choose?'**
  String get what_did_they_choose;

  /// No description provided for @when_where.
  ///
  /// In en, this message translates to:
  /// **'When & where'**
  String get when_where;

  /// No description provided for @who_won_the_toss.
  ///
  /// In en, this message translates to:
  /// **'Who won the toss?'**
  String get who_won_the_toss;

  /// No description provided for @win.
  ///
  /// In en, this message translates to:
  /// **'Win'**
  String get win;

  /// No description provided for @winners_advance_automatically_fixtures_marked_tbd.
  ///
  /// In en, this message translates to:
  /// **'Winners advance automatically. Fixtures marked TBD unlock when the previous round is complete.'**
  String get winners_advance_automatically_fixtures_marked_tbd;

  /// No description provided for @years_of_experience.
  ///
  /// In en, this message translates to:
  /// **'Years of experience'**
  String get years_of_experience;

  /// No description provided for @you_are_not_listed_as_an.
  ///
  /// In en, this message translates to:
  /// **'You are not listed as an umpire'**
  String get you_are_not_listed_as_an;

  /// No description provided for @you_are_offline_scoring_continues_syncs.
  ///
  /// In en, this message translates to:
  /// **'You are offline. Scoring continues — syncs automatically.'**
  String get you_are_offline_scoring_continues_syncs;

  /// No description provided for @you_can_rate_an_umpire_after.
  ///
  /// In en, this message translates to:
  /// **'You can rate an umpire after a completed booking.'**
  String get you_can_rate_an_umpire_after;

  /// No description provided for @you_can_undo_scoring_actions_during.
  ///
  /// In en, this message translates to:
  /// **'You can undo scoring actions during the match.'**
  String get you_can_undo_scoring_actions_during;

  /// No description provided for @your_rating_helps_other_organizers_pick.
  ///
  /// In en, this message translates to:
  /// **'Your rating helps other organizers pick a good ground.'**
  String get your_rating_helps_other_organizers_pick;

  /// No description provided for @e_g_ahmedabad.
  ///
  /// In en, this message translates to:
  /// **'e.g. Ahmedabad'**
  String get e_g_ahmedabad;

  /// No description provided for @e_g_ahmedabad_monsoon_cup.
  ///
  /// In en, this message translates to:
  /// **'e.g. Ahmedabad Monsoon Cup'**
  String get e_g_ahmedabad_monsoon_cup;

  /// No description provided for @e_g_ahmedabad_strikers.
  ///
  /// In en, this message translates to:
  /// **'e.g. Ahmedabad Strikers'**
  String get e_g_ahmedabad_strikers;

  /// No description provided for @unverified.
  ///
  /// In en, this message translates to:
  /// **'unverified'**
  String get unverified;

  /// No description provided for @errFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed: {error}'**
  String errFailed(String error);

  /// No description provided for @errCouldNotConfirm.
  ///
  /// In en, this message translates to:
  /// **'Could not confirm: {error}'**
  String errCouldNotConfirm(String error);

  /// No description provided for @errCouldNotCloseBooking.
  ///
  /// In en, this message translates to:
  /// **'Could not close the booking: {error}'**
  String errCouldNotCloseBooking(String error);

  /// No description provided for @errCouldNotCancel.
  ///
  /// In en, this message translates to:
  /// **'Could not cancel: {error}'**
  String errCouldNotCancel(String error);

  /// No description provided for @errCouldNotPostReview.
  ///
  /// In en, this message translates to:
  /// **'Could not post review: {error}'**
  String errCouldNotPostReview(String error);

  /// No description provided for @errCouldNotCreateMatch.
  ///
  /// In en, this message translates to:
  /// **'Could not create match: {error}'**
  String errCouldNotCreateMatch(String error);

  /// No description provided for @errCouldNotStartMatch.
  ///
  /// In en, this message translates to:
  /// **'Could not start match: {error}'**
  String errCouldNotStartMatch(String error);

  /// No description provided for @errCouldNotUpdateAlerts.
  ///
  /// In en, this message translates to:
  /// **'Could not update match alerts: {error}'**
  String errCouldNotUpdateAlerts(String error);

  /// No description provided for @errCouldNotSaveInnings.
  ///
  /// In en, this message translates to:
  /// **'Could not save innings: {error}'**
  String errCouldNotSaveInnings(String error);

  /// No description provided for @errCouldNotUpdate.
  ///
  /// In en, this message translates to:
  /// **'Could not update: {error}'**
  String errCouldNotUpdate(String error);

  /// No description provided for @errCouldNotCreateTeam.
  ///
  /// In en, this message translates to:
  /// **'Could not create team: {error}'**
  String errCouldNotCreateTeam(String error);

  /// No description provided for @errCouldNotCreateTournament.
  ///
  /// In en, this message translates to:
  /// **'Could not create tournament: {error}'**
  String errCouldNotCreateTournament(String error);

  /// No description provided for @errCouldNotSaveTeams.
  ///
  /// In en, this message translates to:
  /// **'Could not save teams: {error}'**
  String errCouldNotSaveTeams(String error);

  /// No description provided for @errCouldNotGenerateFixtures.
  ///
  /// In en, this message translates to:
  /// **'Could not generate fixtures: {error}'**
  String errCouldNotGenerateFixtures(String error);

  /// No description provided for @errCouldNotResolveTie.
  ///
  /// In en, this message translates to:
  /// **'Could not resolve the tie: {error}'**
  String errCouldNotResolveTie(String error);

  /// No description provided for @errCouldNotLoadBookings.
  ///
  /// In en, this message translates to:
  /// **'Could not load bookings: {error}'**
  String errCouldNotLoadBookings(String error);

  /// No description provided for @errCouldNotDecline.
  ///
  /// In en, this message translates to:
  /// **'Could not decline: {error}'**
  String errCouldNotDecline(String error);

  /// No description provided for @errCouldNotSave.
  ///
  /// In en, this message translates to:
  /// **'Could not save: {error}'**
  String errCouldNotSave(String error);

  /// No description provided for @errCouldNotOpenGallery.
  ///
  /// In en, this message translates to:
  /// **'Could not open the gallery: {error}'**
  String errCouldNotOpenGallery(String error);

  /// No description provided for @adminQueueHelp.
  ///
  /// In en, this message translates to:
  /// **'This queue is for CricketHub staff. Ask an existing admin to add you under /admins in the Firebase Console.'**
  String get adminQueueHelp;

  /// No description provided for @cancellationPolicyConsent.
  ///
  /// In en, this message translates to:
  /// **'By tapping \"Pay & Book\", you agree to the cancellation policy (full refund up to 24h before, 50% up to 12h before, no refund thereafter).'**
  String get cancellationPolicyConsent;

  /// No description provided for @ownerCashConfirmHelp.
  ///
  /// In en, this message translates to:
  /// **'The player pays you in cash at the ground. Confirm here so their QR becomes valid for check-in.'**
  String get ownerCashConfirmHelp;

  /// No description provided for @pickSlotHelp.
  ///
  /// In en, this message translates to:
  /// **'Use the calendar to pick a date and slots, or tap \"Book this ground\" below.'**
  String get pickSlotHelp;

  /// No description provided for @batterAlreadyUsed.
  ///
  /// In en, this message translates to:
  /// **'A batter who is already out (or already at the crease) cannot come in again.'**
  String get batterAlreadyUsed;

  /// No description provided for @groundVerificationHelp.
  ///
  /// In en, this message translates to:
  /// **'Your ground goes to an admin for verification. You can take bookings once it is approved.'**
  String get groundVerificationHelp;

  /// No description provided for @managedByCricketHub.
  ///
  /// In en, this message translates to:
  /// **'Verification status and ratings are managed by CricketHub — they are not editable here.'**
  String get managedByCricketHub;

  /// No description provided for @managedByCricketHubUmpire.
  ///
  /// In en, this message translates to:
  /// **'Verified status, ratings and match counts are managed by CricketHub — they are not editable here.'**
  String get managedByCricketHubUmpire;

  /// No description provided for @noPendingRequestsHelp.
  ///
  /// In en, this message translates to:
  /// **'No pending requests. New bookings will show up here.'**
  String get noPendingRequestsHelp;

  /// No description provided for @umpireRequestHelp.
  ///
  /// In en, this message translates to:
  /// **'When an organizer books you, the request lands here. Confirm it once you have the cash.'**
  String get umpireRequestHelp;

  /// No description provided for @declineRequestHelp.
  ///
  /// In en, this message translates to:
  /// **'The organizer will be told you cannot officiate. Their slot is freed for someone else.'**
  String get declineRequestHelp;

  /// No description provided for @draftProfileHelp.
  ///
  /// In en, this message translates to:
  /// **'Your profile is a draft. Submit it for verification so organizers can find you.'**
  String get draftProfileHelp;

  /// No description provided for @umpireCashHelp.
  ///
  /// In en, this message translates to:
  /// **'Cash on ground: nothing is charged online. The umpire confirms the cash in the app, then this booking is locked in.'**
  String get umpireCashHelp;

  /// No description provided for @payCashHelp.
  ///
  /// In en, this message translates to:
  /// **'Pay {amount} in cash to {name} on the day. They will confirm the booking in the app once they receive it.'**
  String payCashHelp(String amount, String name);

  /// No description provided for @umpireReceives.
  ///
  /// In en, this message translates to:
  /// **'Umpire receives ₹{amount} after the platform fee.'**
  String umpireReceives(int amount);

  /// No description provided for @howWasName.
  ///
  /// In en, this message translates to:
  /// **'How was {name}?'**
  String howWasName(String name);

  /// No description provided for @teamReadyForMatchDay.
  ///
  /// In en, this message translates to:
  /// **'{name} is ready for match day.'**
  String teamReadyForMatchDay(String name);

  /// No description provided for @bookingStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status: {status}'**
  String bookingStatusLabel(String status);

  /// No description provided for @teamsSelectedOf.
  ///
  /// In en, this message translates to:
  /// **'{selected}/{max} selected · at least 2 required'**
  String teamsSelectedOf(int selected, int max);

  /// No description provided for @teamsSavedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} teams saved.'**
  String teamsSavedCount(int count);

  /// No description provided for @scheduleReadyCount.
  ///
  /// In en, this message translates to:
  /// **'Schedule ready · {count} fixtures created.'**
  String scheduleReadyCount(int count);

  /// No description provided for @locationAndDate.
  ///
  /// In en, this message translates to:
  /// **'{location} · {date}'**
  String locationAndDate(String location, String date);

  /// No description provided for @cityAndPlayers.
  ///
  /// In en, this message translates to:
  /// **'{city} · {count} players'**
  String cityAndPlayers(String city, int count);

  /// No description provided for @cityAndRate.
  ///
  /// In en, this message translates to:
  /// **'{city} · ₹{rate}/hr'**
  String cityAndRate(String city, int rate);

  /// No description provided for @weekdayAndPitch.
  ///
  /// In en, this message translates to:
  /// **'Weekday • {pitch}'**
  String weekdayAndPitch(String pitch);

  /// No description provided for @groundAvailabilityHeader.
  ///
  /// In en, this message translates to:
  /// **'{name} · availability'**
  String groundAvailabilityHeader(String name);

  /// No description provided for @weekOf.
  ///
  /// In en, this message translates to:
  /// **'Week of {date}'**
  String weekOf(String date);

  /// No description provided for @minutesShort.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String minutesShort(int minutes);

  /// No description provided for @pointsShort.
  ///
  /// In en, this message translates to:
  /// **'{label} · {points} pts'**
  String pointsShort(String label, int points);

  /// No description provided for @roundLabel.
  ///
  /// In en, this message translates to:
  /// **'Round {round}'**
  String roundLabel(String round);

  /// No description provided for @byeAdvances.
  ///
  /// In en, this message translates to:
  /// **'{round} · BYE — advances automatically'**
  String byeAdvances(String round);

  /// No description provided for @waitingForResult.
  ///
  /// In en, this message translates to:
  /// **'{round} · Waiting for previous result'**
  String waitingForResult(String round);

  /// No description provided for @loadingFixture.
  ///
  /// In en, this message translates to:
  /// **'{round} · Loading fixture'**
  String loadingFixture(String round);

  /// No description provided for @teamVsTeam.
  ///
  /// In en, this message translates to:
  /// **'{a} vs {b}'**
  String teamVsTeam(String a, String b);

  /// No description provided for @bookUmpireName.
  ///
  /// In en, this message translates to:
  /// **'Book {name}'**
  String bookUmpireName(String name);

  /// No description provided for @windowLabel.
  ///
  /// In en, this message translates to:
  /// **'{start}–{end} · {hours}h'**
  String windowLabel(String start, String end, int hours);

  /// No description provided for @battingTeamLabel.
  ///
  /// In en, this message translates to:
  /// **'{team} batting'**
  String battingTeamLabel(String team);

  /// No description provided for @bowlingLabel.
  ///
  /// In en, this message translates to:
  /// **'Bowling: {bowler}'**
  String bowlingLabel(String bowler);

  /// No description provided for @needRuns.
  ///
  /// In en, this message translates to:
  /// **'Need {runs}'**
  String needRuns(int runs);

  /// No description provided for @lastNForm.
  ///
  /// In en, this message translates to:
  /// **'LAST {count}'**
  String lastNForm(int count);

  /// No description provided for @umpireExpMatches.
  ///
  /// In en, this message translates to:
  /// **'{years} yrs · {matches} matches'**
  String umpireExpMatches(int years, int matches);

  /// No description provided for @umpireListLine.
  ///
  /// In en, this message translates to:
  /// **'{city} · {years} yrs · ₹{rate}/hr'**
  String umpireListLine(String city, int years, int rate);

  /// No description provided for @countLive.
  ///
  /// In en, this message translates to:
  /// **'{count} live'**
  String countLive(int count);

  /// No description provided for @countMatches.
  ///
  /// In en, this message translates to:
  /// **'{count} matches'**
  String countMatches(int count);

  /// No description provided for @hourlyRate.
  ///
  /// In en, this message translates to:
  /// **'₹{rate}/hr'**
  String hourlyRate(int rate);

  /// No description provided for @oversShort.
  ///
  /// In en, this message translates to:
  /// **'{value} ov'**
  String oversShort(String value);

  /// No description provided for @teamsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No teams} =1{1 team} other{{count} teams}}'**
  String teamsCount(int count);

  /// No description provided for @bookingsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 booking} other{{count} bookings}}'**
  String bookingsCount(int count);

  /// No description provided for @errCouldNotLoadGrounds.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load grounds. Pull to refresh.'**
  String get errCouldNotLoadGrounds;

  /// No description provided for @letsPlay.
  ///
  /// In en, this message translates to:
  /// **'Let\'s Play'**
  String get letsPlay;

  /// No description provided for @inningsHeader.
  ///
  /// In en, this message translates to:
  /// **'Innings {number} · {team}'**
  String inningsHeader(String number, String team);

  /// No description provided for @ballDetail.
  ///
  /// In en, this message translates to:
  /// **'Inn {innings} · {over} · {bowler} to {striker}'**
  String ballDetail(String innings, String over, String bowler, String striker);

  /// No description provided for @slotsSelected.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No slot selected} =1{1 slot} other{{count} slots}}'**
  String slotsSelected(int count);

  /// No description provided for @runsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 run} other{{count} runs}}'**
  String runsCount(int count);

  /// No description provided for @runsExclaimed.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 run!} other{{count} runs!}}'**
  String runsExclaimed(int count);

  /// No description provided for @extraWide.
  ///
  /// In en, this message translates to:
  /// **'Wide ball'**
  String get extraWide;

  /// No description provided for @extraNoBall.
  ///
  /// In en, this message translates to:
  /// **'No-ball'**
  String get extraNoBall;

  /// No description provided for @wicketEvent.
  ///
  /// In en, this message translates to:
  /// **'WICKET! {player} ({type})'**
  String wicketEvent(String player, String type);

  /// No description provided for @quickActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'What do you want to do?'**
  String get quickActionsTitle;

  /// No description provided for @quickActionsBody.
  ///
  /// In en, this message translates to:
  /// **'Start a match, build a team, or find a ground.'**
  String get quickActionsBody;

  /// No description provided for @quickStartMatch.
  ///
  /// In en, this message translates to:
  /// **'Start a match'**
  String get quickStartMatch;

  /// No description provided for @quickStartMatchSub.
  ///
  /// In en, this message translates to:
  /// **'Set up teams, toss and live scoring'**
  String get quickStartMatchSub;

  /// No description provided for @quickCreateTeamSub.
  ///
  /// In en, this message translates to:
  /// **'Add players and start a squad'**
  String get quickCreateTeamSub;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi', 'ta'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'ta':
      return AppLocalizationsTa();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
