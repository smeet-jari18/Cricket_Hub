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

  /// No description provided for @quickActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Make it a match day'**
  String get quickActionsTitle;

  /// No description provided for @quickActionsBody.
  ///
  /// In en, this message translates to:
  /// **'Pick what you want to set up.'**
  String get quickActionsBody;

  /// No description provided for @quickStartMatch.
  ///
  /// In en, this message translates to:
  /// **'Start a match'**
  String get quickStartMatch;

  /// No description provided for @quickStartMatchSub.
  ///
  /// In en, this message translates to:
  /// **'Choose teams, toss and start scoring'**
  String get quickStartMatchSub;

  /// No description provided for @quickCreateTeam.
  ///
  /// In en, this message translates to:
  /// **'Create a team'**
  String get quickCreateTeam;

  /// No description provided for @quickCreateTeamSub.
  ///
  /// In en, this message translates to:
  /// **'Build a squad for your next game'**
  String get quickCreateTeamSub;

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
