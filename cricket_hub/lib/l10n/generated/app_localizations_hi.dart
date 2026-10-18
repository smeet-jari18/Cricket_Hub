// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get retry => 'पुनः प्रयास करें';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get create => 'बनाएँ';

  @override
  String get quickActionsTitle => 'आज मैच डे बनाएँ';

  @override
  String get quickActionsBody => 'चुनें कि आप क्या सेट करना चाहते हैं।';

  @override
  String get quickStartMatch => 'मैच शुरू करें';

  @override
  String get quickStartMatchSub => 'टीम चुनें, टॉस करें और स्कोरिंग शुरू करें';

  @override
  String get quickCreateTeam => 'टीम बनाएँ';

  @override
  String get quickCreateTeamSub => 'अगले मैच के लिए टीम बनाएँ';

  @override
  String get navHome => 'होम';

  @override
  String get navMyCricket => 'मेरा क्रिकेट';

  @override
  String get navTours => 'टूर्नामेंट';

  @override
  String get navInternational => 'अंतरराष्ट्रीय';

  @override
  String get navMenu => 'मेन्यू';

  @override
  String get menuProfileTitle => 'आपकी प्रोफ़ाइल';

  @override
  String get menuSeason => 'आपका सीज़न';

  @override
  String get menuCareerStats => 'करियर आँकड़े';

  @override
  String get menuComingSoon => 'जल्द आ रहा है';

  @override
  String get menuRuns => 'रन';

  @override
  String get menuWickets => 'विकेट';

  @override
  String get menuAverage => 'औसत';

  @override
  String get menuCareerBody => 'आपका मैच इतिहास और लीडरबोर्ड यहाँ दिखेंगे।';

  @override
  String get menuExplore => 'खोजें';

  @override
  String get menuGroundBooking => 'ग्राउंड बुकिंग';

  @override
  String get menuGroundBookingSub => 'अपने अगले मैच के लिए जगह खोजें';

  @override
  String get menuUmpireBooking => 'अंपायर बुकिंग';

  @override
  String get menuUmpireBookingSub => 'मैच के दिन अधिकारी बुलाएँ';

  @override
  String get menuMyBookings => 'मेरी बुकिंग';

  @override
  String get menuMyBookingsSub => 'आपके स्लॉट और QR कोड';

  @override
  String get menuInternational => 'अंतरराष्ट्रीय स्कोर';

  @override
  String get menuInternationalSub => 'पूरी क्रिकेट दुनिया पर नज़र';

  @override
  String get menuForOwners => 'मालिकों के लिए';

  @override
  String get menuOwnerPanel => 'ग्राउंड मालिक पैनल';

  @override
  String get menuOwnerPanelSub =>
      'ग्राउंड सूचीबद्ध करें, दिन संभालें, भुगतान देखें';

  @override
  String get menuUmpireDashboard => 'अंपायर डैशबोर्ड';

  @override
  String get menuUmpireDashboardSub => 'आपकी लिस्टिंग, दरें और उपलब्धता';

  @override
  String get menuLanguage => 'भाषा';

  @override
  String get menuLanguageSub => 'English, हिन्दी, தமிழ்';

  @override
  String get menuLogout => 'लॉग आउट';

  @override
  String get menuLogoutTitle => 'लॉग आउट करें?';

  @override
  String get menuLogoutBody =>
      'आप कभी भी दोबारा साइन इन करके अपनी टीमों पर लौट सकते हैं।';

  @override
  String get menuTagline => 'CricketHub  ·  स्थानीय क्रिकेट. प्रो लेवल.';

  @override
  String get menuStaff => 'स्टाफ़';

  @override
  String get menuVerificationQueue => 'सत्यापन कतार';

  @override
  String get menuVerificationQueueSub => 'ग्राउंड और अंपायर स्वीकृत करें';

  @override
  String get menuPlayer => 'खिलाड़ी';

  @override
  String get intlTitle => 'अंतरराष्ट्रीय';

  @override
  String get intlTabLive => 'लाइव';

  @override
  String get intlTabUpcoming => 'आगामी';

  @override
  String get intlTabRecent => 'हाल के';

  @override
  String get intlLiveNow => 'लाइव';

  @override
  String get intlCompleted => 'पूरा हुआ';

  @override
  String get intlUpcomingLabel => 'आगामी';

  @override
  String get intlEmptyLive => 'अभी कोई मैच लाइव नहीं है।';

  @override
  String get intlEmptyUpcoming => 'कोई आगामी मैच सूचीबद्ध नहीं है।';

  @override
  String get intlEmptyRecent => 'अभी कोई हालिया नतीजा नहीं है।';

  @override
  String get intlDemoBanner =>
      'डेमो डेटा — लाइव स्कोर के लिए CricAPI key जोड़ें।';

  @override
  String get intlNoKeyTitle => 'लाइव स्कोर के लिए CricAPI key चाहिए';

  @override
  String get intlNoKeyBody =>
      'असली अंतरराष्ट्रीय मैचों के लिए ऐप को --dart-define=CRICAPI_KEY=your_key के साथ चलाएँ, या डेमो डेटा से स्क्रीन देखें।';

  @override
  String get intlLoadDemo => 'डेमो मैच दिखाएँ';

  @override
  String get intlErrNetwork => 'CricAPI तक नहीं पहुँच सके। कनेक्शन जाँचें।';

  @override
  String get intlErrInvalidKey =>
      'CricAPI ने key अस्वीकार कर दी। CRICAPI_KEY जाँचें।';

  @override
  String get intlErrRateLimited =>
      'CricAPI की रोज़ाना सीमा पूरी हो गई। कल फिर कोशिश करें।';

  @override
  String get intlErrGeneric => 'स्कोर लोड करने में कुछ गड़बड़ हुई।';

  @override
  String get intlScorecard => 'स्कोरकार्ड';

  @override
  String get intlBatting => 'बल्लेबाज़ी';

  @override
  String get intlBowling => 'गेंदबाज़ी';

  @override
  String get intlBatter => 'बल्लेबाज़';

  @override
  String get intlBowler => 'गेंदबाज़';

  @override
  String get intlRunsShort => 'रन';

  @override
  String get intlBallsShort => 'गें';

  @override
  String get intlFours => '4s';

  @override
  String get intlSixes => '6s';

  @override
  String get intlStrikeRate => 'SR';

  @override
  String get intlOversShort => 'ओ';

  @override
  String get intlMaidensShort => 'मे';

  @override
  String get intlEconomy => 'इको';

  @override
  String get intlWicketsShort => 'वि';

  @override
  String get intlVenue => 'मैदान';

  @override
  String get intlNoScorecard =>
      'इस मैच का स्कोरकार्ड अभी प्रकाशित नहीं हुआ है।';

  @override
  String get languageTitle => 'भाषा';

  @override
  String get languageSubtitle => 'ऐप की भाषा चुनें।';

  @override
  String get languageSystem => 'डिवाइस की भाषा';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageHindi => 'हिन्दी';

  @override
  String get languageTamil => 'தமிழ்';
}
