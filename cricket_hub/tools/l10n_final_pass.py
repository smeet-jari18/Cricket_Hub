#!/usr/bin/env python3
"""The last mile: strings a flat phrasebook cannot express.

Two shapes were deliberately left out of `l10n_sweep.py`:

  * **concatenated** `Text('first half ' 'second half')` — replacing one half
    would produce invalid Dart, and the sentence only makes sense as a whole;
  * **interpolated** `'Could not save: $e'` — needs an ARB *placeholder*, not a
    flat lookup, or the error text disappears.

This script edits those sites by hand-authored, asserted replacements and adds
the matching keys with `@…` placeholder metadata, so `flutter gen-l10n` emits a
typed method (`l10n.couldNotSave(error)`), not a String that silently drops the
value.

    python3 tools/l10n_final_pass.py --dry-run
    python3 tools/l10n_final_pass.py
"""
from __future__ import annotations

import collections
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
ARB = {
    "en": ROOT / "lib/l10n/app_en.arb",
    "hi": ROOT / "lib/l10n/app_hi.arb",
    "ta": ROOT / "lib/l10n/app_ta.arb",
}

# (key, en, hi, ta, placeholders)
KEYS: list[tuple[str, str, str, str, dict[str, str]]] = [
    # ---- errors -----------------------------------------------------------
    ("errFailed", "Failed: {error}",
     "विफल: {error}", "தோல்வி: {error}", {"error": "String"}),
    ("errCouldNotConfirm", "Could not confirm: {error}",
     "पुष्टि नहीं हो सकी: {error}", "உறுதிசெய்ய முடியவில்லை: {error}", {"error": "String"}),
    ("errCouldNotCloseBooking", "Could not close the booking: {error}",
     "बुकिंग बंद नहीं हो सकी: {error}", "முன்பதிவை மூட முடியவில்லை: {error}", {"error": "String"}),
    ("errCouldNotCancel", "Could not cancel: {error}",
     "रद्द नहीं हो सका: {error}", "ரத்துசெய்ய முடியவில்லை: {error}", {"error": "String"}),
    ("errCouldNotPostReview", "Could not post review: {error}",
     "समीक्षा पोस्ट नहीं हो सकी: {error}", "மதிப்பாய்வை இட முடியவில்லை: {error}", {"error": "String"}),
    ("errCouldNotCreateMatch", "Could not create match: {error}",
     "मैच नहीं बन सका: {error}", "ஆட்டத்தை உருவாக்க முடியவில்லை: {error}", {"error": "String"}),
    ("errCouldNotStartMatch", "Could not start match: {error}",
     "मैच शुरू नहीं हो सका: {error}", "ஆட்டத்தைத் தொடங்க முடியவில்லை: {error}", {"error": "String"}),
    ("errCouldNotUpdateAlerts", "Could not update match alerts: {error}",
     "मैच अलर्ट अपडेट नहीं हो सके: {error}", "ஆட்ட அறிவிப்புகளைப் புதுப்பிக்க முடியவில்லை: {error}", {"error": "String"}),
    ("errCouldNotSaveInnings", "Could not save innings: {error}",
     "पारी सहेजी नहीं जा सकी: {error}", "இன்னிங்ஸைச் சேமிக்க முடியவில்லை: {error}", {"error": "String"}),
    ("errCouldNotUpdate", "Could not update: {error}",
     "अपडेट नहीं हो सका: {error}", "புதுப்பிக்க முடியவில்லை: {error}", {"error": "String"}),
    ("errCouldNotCreateTeam", "Could not create team: {error}",
     "टीम नहीं बन सकी: {error}", "அணியை உருவாக்க முடியவில்லை: {error}", {"error": "String"}),
    ("errCouldNotCreateTournament", "Could not create tournament: {error}",
     "टूर्नामेंट नहीं बन सका: {error}", "போட்டியை உருவாக்க முடியவில்லை: {error}", {"error": "String"}),
    ("errCouldNotSaveTeams", "Could not save teams: {error}",
     "टीमें सहेजी नहीं जा सकीं: {error}", "அணிகளைச் சேமிக்க முடியவில்லை: {error}", {"error": "String"}),
    ("errCouldNotGenerateFixtures", "Could not generate fixtures: {error}",
     "फ़िक्स्चर नहीं बन सके: {error}", "ஆட்டங்களை உருவாக்க முடியவில்லை: {error}", {"error": "String"}),
    ("errCouldNotResolveTie", "Could not resolve the tie: {error}",
     "टाई नहीं सुलझी: {error}", "சமநிலையைத் தீர்க்க முடியவில்லை: {error}", {"error": "String"}),
    ("errCouldNotLoadBookings", "Could not load bookings: {error}",
     "बुकिंग लोड नहीं हो सकीं: {error}", "முன்பதிவுகளை ஏற்ற முடியவில்லை: {error}", {"error": "String"}),
    ("errCouldNotDecline", "Could not decline: {error}",
     "अस्वीकार नहीं हो सका: {error}", "நிராகரிக்க முடியவில்லை: {error}", {"error": "String"}),
    ("errCouldNotSave", "Could not save: {error}",
     "सहेजा नहीं जा सका: {error}", "சேமிக்க முடியவில்லை: {error}", {"error": "String"}),
    ("errCouldNotOpenGallery", "Could not open the gallery: {error}",
     "गैलरी नहीं खुल सकी: {error}", "கேலரியைத் திறக்க முடியவில்லை: {error}", {"error": "String"}),
    # ---- long help sentences (previously split across literals) -----------
    ("adminQueueHelp",
     "This queue is for CricketHub staff. Ask an existing admin to add you under /admins in the Firebase Console.",
     "यह कतार CricketHub स्टाफ़ के लिए है। Firebase Console में /admins के तहत खुद को जोड़ने के लिए किसी मौजूदा एडमिन से कहें।",
     "இந்த வரிசை CricketHub பணியாளர்களுக்கானது. Firebase Console-இல் /admins கீழ் உங்களைச் சேர்க்க ஏற்கனவே உள்ள நிர்வாகியிடம் கேளுங்கள்.",
     {}),
    ("cancellationPolicyConsent",
     'By tapping "Pay & Book", you agree to the cancellation policy (full refund up to 24h before, 50% up to 12h before, no refund thereafter).',
     '"Pay & Book" दबाकर आप रद्दीकरण नीति से सहमत होते हैं (24 घंटे पहले तक पूरा रिफ़ंड, 12 घंटे पहले तक 50%, उसके बाद कोई रिफ़ंड नहीं)।',
     '"Pay & Book" தட்டுவதன் மூலம் ரத்துக் கொள்கையை ஏற்கிறீர்கள் (24 மணி நேரத்திற்கு முன் முழு பணத்திருப்பம், 12 மணி நேரத்திற்கு முன் 50%, அதன் பின் திருப்பம் இல்லை).',
     {}),
    ("ownerCashConfirmHelp",
     "The player pays you in cash at the ground. Confirm here so their QR becomes valid for check-in.",
     "खिलाड़ी आपको ग्राउंड पर नकद देता है। यहाँ पुष्टि करें ताकि उसका QR चेक-इन के लिए मान्य हो जाए।",
     "வீரர் மைதானத்தில் பணமாகத் தருவார். இங்கே உறுதிசெய்தால் அவரது QR செக்-இனுக்குச் செல்லுபடியாகும்.",
     {}),
    ("pickSlotHelp",
     'Use the calendar to pick a date and slots, or tap "Book this ground" below.',
     "तारीख और स्लॉट चुनने के लिए कैलेंडर इस्तेमाल करें, या नीचे \"यह ग्राउंड बुक करें\" दबाएँ।",
     "தேதியையும் நேரத்தையும் தேர்ந்தெடுக்க நாட்காட்டியைப் பயன்படுத்துங்கள் அல்லது கீழே \"இந்த மைதானத்தை முன்பதிவு செய்\" தட்டுங்கள்.",
     {}),
    ("batterAlreadyUsed",
     "A batter who is already out (or already at the crease) cannot come in again.",
     "जो बल्लेबाज़ पहले ही आउट है (या क्रीज़ पर है) वह दोबारा नहीं आ सकता।",
     "ஏற்கனவே ஆட்டமிழந்த (அல்லது களத்தில் இருக்கும்) பேட்டர் மீண்டும் வர முடியாது.",
     {}),
    ("groundVerificationHelp",
     "Your ground goes to an admin for verification. You can take bookings once it is approved.",
     "आपका ग्राउंड सत्यापन के लिए एडमिन के पास जाता है। मंज़ूरी के बाद आप बुकिंग ले सकते हैं।",
     "உங்கள் மைதானம் சரிபார்ப்புக்கு நிர்வாகியிடம் செல்லும். அனுமதிக்குப் பிறகு முன்பதிவுகளைப் பெறலாம்.",
     {}),
    ("managedByCricketHub",
     "Verification status and ratings are managed by CricketHub — they are not editable here.",
     "सत्यापन स्थिति और रेटिंग CricketHub संभालता है — इन्हें यहाँ बदला नहीं जा सकता।",
     "சரிபார்ப்பு நிலையும் மதிப்பீடுகளும் CricketHub நிர்வகிக்கும் — இங்கே திருத்த முடியாது.",
     {}),
    ("managedByCricketHubUmpire",
     "Verified status, ratings and match counts are managed by CricketHub — they are not editable here.",
     "सत्यापित स्थिति, रेटिंग और मैच संख्या CricketHub संभालता है — इन्हें यहाँ बदला नहीं जा सकता।",
     "சரிபார்ப்பு நிலை, மதிப்பீடுகள், ஆட்ட எண்ணிக்கை CricketHub நிர்வகிக்கும் — இங்கே திருத்த முடியாது.",
     {}),
    ("noPendingRequestsHelp",
     "No pending requests. New bookings will show up here.",
     "कोई लंबित अनुरोध नहीं। नई बुकिंग यहाँ दिखेंगी।",
     "நிலுவையில் கோரிக்கைகள் இல்லை. புதிய முன்பதிவுகள் இங்கே தோன்றும்.",
     {}),
    ("umpireRequestHelp",
     "When an organizer books you, the request lands here. Confirm it once you have the cash.",
     "जब कोई आयोजक आपको बुक करता है, अनुरोध यहाँ आता है। नकद मिलने पर उसे पक्का करें।",
     "ஏற்பாட்டாளர் உங்களை முன்பதிவு செய்தால் கோரிக்கை இங்கே வரும். பணம் கிடைத்ததும் உறுதிசெய்யுங்கள்.",
     {}),
    ("declineRequestHelp",
     "The organizer will be told you cannot officiate. Their slot is freed for someone else.",
     "आयोजक को बताया जाएगा कि आप उपलब्ध नहीं हैं। उनका स्लॉट किसी और के लिए खुल जाएगा।",
     "நீங்கள் கடமையாற்ற முடியாது என்று ஏற்பாட்டாளருக்குத் தெரிவிக்கப்படும். அவரது நேரம் வேறொருவருக்குக் கிடைக்கும்.",
     {}),
    ("draftProfileHelp",
     "Your profile is a draft. Submit it for verification so organizers can find you.",
     "आपकी प्रोफ़ाइल ड्राफ़्ट है। सत्यापन के लिए भेजें ताकि आयोजक आपको ढूँढ सकें।",
     "உங்கள் சுயவிவரம் வரைவில் உள்ளது. ஏற்பாட்டாளர்கள் கண்டறிய சரிபார்ப்புக்கு அனுப்புங்கள்.",
     {}),
    ("umpireCashHelp",
     "Cash on ground: nothing is charged online. The umpire confirms the cash in the app, then this booking is locked in.",
     "ग्राउंड पर नकद: ऑनलाइन कुछ नहीं कटता। अंपायर ऐप में नकद की पुष्टि करता है, फिर यह बुकिंग पक्की हो जाती है।",
     "மைதானத்தில் பணம்: ஆன்லைனில் எதுவும் வசூலாகாது. நடுவர் செயலியில் பணத்தை உறுதிசெய்ததும் முன்பதிவு உறுதியாகும்.",
     {}),
    ("payCashHelp",
     "Pay {amount} in cash to {name} on the day. They will confirm the booking in the app once they receive it.",
     "उस दिन {name} को {amount} नकद दें। राशि मिलने पर वे ऐप में बुकिंग पक्की करेंगे।",
     "அன்று {name} க்கு {amount} பணமாகத் தரவும். பெற்றதும் செயலியில் முன்பதிவை உறுதிசெய்வார்.",
     {"amount": "String", "name": "String"}),
    ("umpireReceives",
     "Umpire receives ₹{amount} after the platform fee.",
     "प्लेटफ़ॉर्म शुल्क के बाद अंपायर को ₹{amount} मिलते हैं।",
     "தளக் கட்டணத்திற்குப் பின் நடுவருக்கு ₹{amount} கிடைக்கும்.",
     {"amount": "int"}),
    # ---- sentences with values -------------------------------------------
    ("howWasName", "How was {name}?",
     "{name} कैसा रहा?", "{name} எப்படி இருந்தது?", {"name": "String"}),
    ("teamReadyForMatchDay", "{name} is ready for match day.",
     "{name} मैच के दिन के लिए तैयार है।", "{name} ஆட்ட நாளுக்குத் தயார்.", {"name": "String"}),
    ("bookingStatusLabel", "Status: {status}",
     "स्थिति: {status}", "நிலை: {status}", {"status": "String"}),
    ("teamsSelectedOf", "{selected}/{max} selected · at least 2 required",
     "{selected}/{max} चुनी · कम से कम 2 ज़रूरी", "{selected}/{max} தேர்ந்தெடுக்கப்பட்டது · குறைந்தது 2 தேவை",
     {"selected": "int", "max": "int"}),
    ("teamsSavedCount", "{count} teams saved.",
     "{count} टीमें सहेजी गईं।", "{count} அணிகள் சேமிக்கப்பட்டன.", {"count": "int"}),
    ("scheduleReadyCount", "Schedule ready · {count} fixtures created.",
     "शेड्यूल तैयार · {count} फ़िक्स्चर बने।", "அட்டவணை தயார் · {count} ஆட்டங்கள் உருவாக்கப்பட்டன.", {"count": "int"}),
    ("locationAndDate", "{location} · {date}",
     "{location} · {date}", "{location} · {date}", {"location": "String", "date": "String"}),
    ("cityAndPlayers", "{city} · {count} players",
     "{city} · {count} खिलाड़ी", "{city} · {count} வீரர்கள்", {"city": "String", "count": "int"}),
    ("cityAndRate", "{city} · ₹{rate}/hr",
     "{city} · ₹{rate}/घंटा", "{city} · ₹{rate}/மணி", {"city": "String", "rate": "int"}),
    ("weekdayAndPitch", "Weekday • {pitch}",
     "कार्यदिवस • {pitch}", "வேலைநாள் • {pitch}", {"pitch": "String"}),
    ("groundAvailabilityHeader", "{name} · availability",
     "{name} · उपलब्धता", "{name} · கிடைக்கும் நேரம்", {"name": "String"}),
    ("weekOf", "Week of {date}",
     "{date} वाला सप्ताह", "{date} வாரம்", {"date": "String"}),
    ("minutesShort", "{minutes} min",
     "{minutes} मिनट", "{minutes} நிமிடம்", {"minutes": "int"}),
    ("pointsShort", "{label} · {points} pts",
     "{label} · {points} अंक", "{label} · {points} புள்ளி", {"label": "String", "points": "int"}),
    ("roundLabel", "Round {round}",
     "राउंड {round}", "சுற்று {round}", {"round": "String"}),
    ("byeAdvances", "{round} · BYE — advances automatically",
     "{round} · बाय — अपने आप आगे", "{round} · பை — தானாக முன்னேறும்", {"round": "String"}),
    ("waitingForResult", "{round} · Waiting for previous result",
     "{round} · पिछले परिणाम की प्रतीक्षा", "{round} · முந்தைய முடிவுக்காகக் காத்திருப்பு", {"round": "String"}),
    ("loadingFixture", "{round} · Loading fixture",
     "{round} · फ़िक्स्चर लोड हो रहा है", "{round} · ஆட்டம் ஏற்றப்படுகிறது", {"round": "String"}),
    ("teamVsTeam", "{a} vs {b}",
     "{a} बनाम {b}", "{a} எதிர் {b}", {"a": "String", "b": "String"}),
    ("bookUmpireName", "Book {name}",
     "{name} को बुक करें", "{name} ஐ முன்பதிவு செய்", {"name": "String"}),
    ("windowLabel", "{start}–{end} · {hours}h",
     "{start}–{end} · {hours}घं", "{start}–{end} · {hours}மணி",
     {"start": "String", "end": "String", "hours": "int"}),
    ("battingTeamLabel", "{team} batting",
     "{team} बल्लेबाज़ी", "{team} பேட்டிங்", {"team": "String"}),
    ("bowlingLabel", "Bowling: {bowler}",
     "गेंदबाज़ी: {bowler}", "பந்துவீச்சு: {bowler}", {"bowler": "String"}),
    ("needRuns", "Need {runs}",
     "{runs} चाहिए", "{runs} தேவை", {"runs": "int"}),
    ("lastNForm", "LAST {count}",
     "पिछले {count}", "கடைசி {count}", {"count": "int"}),
    ("umpireExpMatches", "{years} yrs · {matches} matches",
     "{years} वर्ष · {matches} मैच", "{years} ஆண்டு · {matches} ஆட்டங்கள்",
     {"years": "int", "matches": "int"}),
    ("umpireListLine", "{city} · {years} yrs · ₹{rate}/hr",
     "{city} · {years} वर्ष · ₹{rate}/घंटा", "{city} · {years} ஆண்டு · ₹{rate}/மணி",
     {"city": "String", "years": "int", "rate": "int"}),
    ("countLive", "{count} live",
     "{count} लाइव", "{count} நேரலை", {"count": "int"}),
    ("countMatches", "{count} matches",
     "{count} मैच", "{count} ஆட்டங்கள்", {"count": "int"}),
    ("hourlyRate", "₹{rate}/hr",
     "₹{rate}/घंटा", "₹{rate}/மணி", {"rate": "int"}),
    ("oversShort", "{value} ov",
     "{value} ओवर", "{value} ஓவர்", {"value": "String"}),
    # ---- plural (ICU) ------------------------------------------------------
    ("teamsCount", "{count, plural, =0{No teams} =1{1 team} other{{count} teams}}",
     "{count, plural, =0{कोई टीम नहीं} =1{1 टीम} other{{count} टीमें}}",
     "{count, plural, =0{அணிகள் இல்லை} =1{1 அணி} other{{count} அணிகள்}}",
     {"count": "int"}),
    ("bookingsCount", "{count, plural, =1{1 booking} other{{count} bookings}}",
     "{count, plural, =1{1 बुकिंग} other{{count} बुकिंग}}",
     "{count, plural, =1{1 முன்பதிவு} other{{count} முன்பதிவுகள்}}",
     {"count": "int"}),
    ("reviewsCount", "({count, plural, =1{1 review} other{{count} reviews}})",
     "({count, plural, =1{1 समीक्षा} other{{count} समीक्षाएँ}})",
     "({count, plural, =1{1 மதிப்பாய்வு} other{{count} மதிப்பாய்வுகள்}})",
     {"count": "int"}),
]

# Whole-sentence fragments written as adjacent Dart literals.
# Sentences written as adjacent Dart literals: `'first half ' 'second half'`.
# Replacing one half would leave invalid Dart, so the whole run is replaced by a
# single lookup. `head` only has to be an unambiguous prefix of the sentence.
FRAGMENTS: list[tuple[str, str, str]] = [
    ("lib/screens/admin/admin_verification_screen.dart",
     "This queue is for CricketHub staff. Ask an ", "l10n.adminQueueHelp"),
    ("lib/screens/booking/booking_checkout_screen.dart",
     "By tapping ", "l10n.cancellationPolicyConsent"),
    ("lib/screens/booking/booking_detail_screen.dart",
     "The player pays you in cash at the ground. ", "l10n.ownerCashConfirmHelp"),
    ("lib/screens/ground/ground_detail_screen.dart",
     "Use the calendar to pick a date and slots, or tap ", "l10n.pickSlotHelp"),
    ("lib/screens/match/scoring_dashboard_screen.dart",
     "A batter who is already out (or already at the crease) ", "l10n.batterAlreadyUsed"),
    ("lib/screens/owner/owner_create_ground_screen.dart",
     "Your ground goes to an admin for verification. You can take ",
     "l10n.groundVerificationHelp"),
    ("lib/screens/owner/owner_edit_ground_screen.dart",
     "Verification status and ratings are managed by CricketHub — ",
     "l10n.managedByCricketHub"),
    ("lib/screens/umpire/umpire_booking_requests_screen.dart",
     "No pending requests. New bookings will show up ", "l10n.noPendingRequestsHelp"),
    ("lib/screens/umpire/umpire_booking_requests_screen.dart",
     "When an organizer books you, the request lands here. Confirm it ",
     "l10n.umpireRequestHelp"),
    ("lib/screens/umpire/umpire_booking_requests_screen.dart",
     "The organizer will be told you cannot officiate. Their slot is ",
     "l10n.declineRequestHelp"),
    ("lib/screens/umpire/umpire_dashboard.dart",
     "Your profile is a draft. Submit it for verification ", "l10n.draftProfileHelp"),
    ("lib/screens/umpire/umpire_edit_screen.dart",
     "Verified status, ratings and match counts are managed by ",
     "l10n.managedByCricketHubUmpire"),
    ("lib/screens/umpire/umpire_booking_screen.dart",
     "Cash on ground: nothing is charged online. The umpire ", "l10n.umpireCashHelp"),
    ("lib/screens/umpire/umpire_booking_screen.dart",
     "Pay $_rupees in cash to ", "l10n.payCashHelp('₹$_rupees', _umpire.displayName)"),
    ("lib/screens/umpire/umpire_booking_screen.dart",
     "Umpire receives ₹", "l10n.umpireReceives(((base - fee) / 100).round())"),
]

# (file, literal-to-find, replacement dart expression)
SITES: list[tuple[str, str, str]] = [
    # errors
    ("lib/screens/admin/admin_verification_screen.dart", "Failed: $e", "l10n.errFailed('$e')"),
    ("lib/screens/admin/admin_verification_screen.dart", "Failed: $e", "l10n.errFailed('$e')"),
    ("lib/screens/booking/booking_detail_screen.dart", "Could not confirm: $e", "l10n.errCouldNotConfirm('$e')"),
    ("lib/screens/booking/booking_detail_screen.dart", "Could not close the booking: $e", "l10n.errCouldNotCloseBooking('$e')"),
    ("lib/screens/booking/booking_detail_screen.dart", "Could not cancel: $e", "l10n.errCouldNotCancel('$e')"),
    ("lib/screens/booking/leave_review_screen.dart", "Could not post review: $e", "l10n.errCouldNotPostReview('$e')"),
    ("lib/screens/match/create_match_screen.dart", "Could not create match: $error", "l10n.errCouldNotCreateMatch('$error')"),
    ("lib/screens/match/toss_screen.dart", "Could not start match: $error", "l10n.errCouldNotStartMatch('$error')"),
    ("lib/screens/match/live_match_screen.dart", "Could not update match alerts: $error", "l10n.errCouldNotUpdateAlerts('$error')"),
    ("lib/screens/match/scoring_dashboard_screen.dart", "Could not save innings: $error", "l10n.errCouldNotSaveInnings('$error')"),
    ("lib/screens/owner/owner_calendar_screen.dart", "Could not update: $e", "l10n.errCouldNotUpdate('$e')"),
    ("lib/screens/umpire/umpire_availability_screen.dart", "Could not update: $e", "l10n.errCouldNotUpdate('$e')"),
    ("lib/screens/team/create_team_screen.dart", "Could not create team: $error", "l10n.errCouldNotCreateTeam('$error')"),
    ("lib/screens/tournament/create_tournament_screen.dart", "Could not create tournament: $error", "l10n.errCouldNotCreateTournament('$error')"),
    ("lib/screens/tournament/tournament_detail_screen.dart", "Could not save teams: $error", "l10n.errCouldNotSaveTeams('$error')"),
    ("lib/screens/tournament/tournament_detail_screen.dart", "Could not generate fixtures: $error", "l10n.errCouldNotGenerateFixtures('$error')"),
    ("lib/screens/tournament/tournament_detail_screen.dart", "Could not resolve the tie: $error", "l10n.errCouldNotResolveTie('$error')"),
    ("lib/screens/umpire/umpire_booking_requests_screen.dart", "Could not load bookings: ${snapshot.error}", "l10n.errCouldNotLoadBookings('${snapshot.error}')"),
    ("lib/screens/umpire/umpire_booking_requests_screen.dart", "Could not decline: $e", "l10n.errCouldNotDecline('$e')"),
    ("lib/screens/umpire/umpire_booking_requests_screen.dart", "Could not confirm: $e", "l10n.errCouldNotConfirm('$e')"),
    ("lib/screens/owner/owner_edit_ground_screen.dart", "Could not save: $e", "l10n.errCouldNotSave('$e')"),
    ("lib/screens/umpire/umpire_edit_screen.dart", "Could not save: $e", "l10n.errCouldNotSave('$e')"),
    ("lib/screens/umpire/umpire_onboarding_screen.dart", "Could not save: $e", "l10n.errCouldNotSave('$e')"),
    ("lib/screens/owner/owner_edit_ground_screen.dart", "Could not open the gallery: $e", "l10n.errCouldNotOpenGallery('$e')"),
    ("lib/screens/umpire/umpire_onboarding_screen.dart", "Could not open the gallery: $e", "l10n.errCouldNotOpenGallery('$e')"),
    # values
    ("lib/screens/booking/leave_review_screen.dart", "How was $name?", "l10n.howWasName('$name')"),
    ("lib/screens/team/create_team_screen.dart", "$name is ready for match day.", "l10n.teamReadyForMatchDay('$name')"),
    ("lib/screens/booking/booking_success_screen.dart", "Status: ${booking.status}", "l10n.bookingStatusLabel('${booking.status}')"),
    ("lib/screens/tournament/tournament_detail_screen.dart",
     "${_selected.length}/${widget.maxTeams} selected · at least 2 required",
     "l10n.teamsSelectedOf(_selected.length, widget.maxTeams)"),
    ("lib/screens/tournament/tournament_detail_screen.dart", "${selected.length} teams saved.", "l10n.teamsSavedCount(selected.length)"),
    ("lib/screens/tournament/tournament_detail_screen.dart", "Schedule ready · $count fixtures created.", "l10n.scheduleReadyCount(count)"),
    ("lib/screens/tournament/tournament_detail_screen.dart", "${tournament.location} · $dateLabel", "l10n.locationAndDate(tournament.location, dateLabel)"),
    ("lib/screens/tournament/tournaments_screen.dart", "${tournament.location}  ·  $date", "l10n.locationAndDate(tournament.location, date)"),
    ("lib/screens/tournament/tournament_detail_screen.dart", "${team.city} · ${team.roster.length} players", "l10n.cityAndPlayers(team.city, team.roster.length)"),
    ("lib/screens/home/my_cricket_screen.dart", "${team.city}  ·  ${team.roster.length} players", "l10n.cityAndPlayers(team.city, team.roster.length)"),
    ("lib/screens/home/home_screen.dart", "${otherMatches.length} matches", "l10n.countMatches(otherMatches.length)"),
    ("lib/screens/home/home_screen.dart", "$count live", "l10n.countLive(count)"),
    ("lib/screens/home/home_screen.dart", "${match.teamAName}  vs  ${match.teamBName}", "l10n.teamVsTeam(match.teamAName, match.teamBName)"),
    ("lib/screens/match/live_match_screen.dart", "${match.teamAName}  vs  ${match.teamBName}", "l10n.teamVsTeam(match.teamAName, match.teamBName)"),
    ("lib/screens/tournament/tournament_detail_screen.dart", "${match.teamAName}  vs  ${match.teamBName}", "l10n.teamVsTeam(match.teamAName, match.teamBName)"),
    ("lib/screens/match/create_match_screen.dart", "$overs overs", "l10n.oversCount(overs)"),
    ("lib/widgets/live_match_card.dart", "${match.totalOvers} overs", "l10n.oversCount(match.totalOvers)"),
    ("lib/widgets/live_match_card.dart", "$overs ov", "l10n.oversShort(overs)"),
    ("lib/screens/tournament/create_tournament_screen.dart", "$value overs", "l10n.oversCount(value)"),
    ("lib/screens/owner/owner_create_ground_screen.dart", "$m min", "l10n.minutesShort(m)"),
    ("lib/screens/ground/ground_detail_screen.dart", "Weekday • ${_ground!.pitchType}", "l10n.weekdayAndPitch(_ground!.pitchType)"),
    ("lib/screens/ground/ground_detail_screen.dart", "(${g.reviewCount} reviews)", "l10n.reviewsCount(g.reviewCount)"),
    ("lib/screens/ground/ground_detail_screen.dart", "₹${_ground!.priceWeekdayHourly}/hr", "l10n.hourlyRate(_ground!.priceWeekdayHourly)"),
    ("lib/screens/ground/ground_list_screen.dart", "₹${ground.priceWeekdayHourly}/hr", "l10n.hourlyRate(ground.priceWeekdayHourly)"),
    ("lib/screens/owner/owner_dashboard.dart", "${ground.city} · ₹${ground.priceWeekdayHourly}/hr", "l10n.cityAndRate(ground.city, ground.priceWeekdayHourly)"),
    ("lib/screens/owner/owner_calendar_screen.dart", "${_ground.name} · availability", "l10n.groundAvailabilityHeader(_ground.name)"),
    ("lib/screens/owner/owner_earnings_screen.dart", "Week of ${week.weekStart}", "l10n.weekOf('${week.weekStart}')"),
    ("lib/screens/match/scoring_dashboard_screen.dart", "${s.battingTeamName} batting", "l10n.battingTeamLabel(s.battingTeamName)"),
    ("lib/screens/match/scoring_dashboard_screen.dart", "Need ${s.runsNeeded}", "l10n.needRuns(s.runsNeeded)"),
    ("lib/screens/home/career_stats_screen.dart", "LAST ${recent.length.clamp(0, 5)}", "l10n.lastNForm(recent.length.clamp(0, 5))"),
    ("lib/screens/umpire/umpire_list_screen.dart", "${umpire.experienceYears} yrs · ${umpire.matchesOfficiated} matches",
     "l10n.umpireExpMatches(umpire.experienceYears, umpire.matchesOfficiated)"),
    ("lib/screens/admin/admin_verification_screen.dart", "${u.city} · ${u.experienceYears} yrs · ₹${u.hourlyRate}/hr",
     "l10n.umpireListLine(u.city, u.experienceYears, u.hourlyRate)"),
    ("lib/screens/tournament/tournament_detail_screen.dart", "Round $round", "l10n.roundLabel('$round')"),
    ("lib/screens/tournament/tournament_detail_screen.dart", "${fixture.roundName} · BYE — advances automatically",
     "l10n.byeAdvances(fixture.roundName)"),
    ("lib/screens/tournament/tournament_detail_screen.dart", "${fixture.roundName} · Waiting for previous result",
     "l10n.waitingForResult(fixture.roundName)"),
    ("lib/screens/tournament/tournament_detail_screen.dart", "${fixture.roundName} · Loading fixture",
     "l10n.loadingFixture(fixture.roundName)"),
    ("lib/screens/tournament/tournament_detail_screen.dart", "$label · $points pts", "l10n.pointsShort(label, points)"),
    ("lib/screens/umpire/umpire_booking_screen.dart", "Book ${umpire.displayName}", "l10n.bookUmpireName(umpire.displayName)"),
    ("lib/screens/umpire/umpire_booking_screen.dart", "${window.start}–${window.end} · ${window.hours}h",
     "l10n.windowLabel(window.start, window.end, window.hours)"),
]


def add_keys(dry_run: bool) -> int:
    added = 0
    for lang, path in ARB.items():
        arb = json.loads(path.read_text(encoding="utf-8"),
                         object_pairs_hook=collections.OrderedDict)
        for key, en, hi, ta, placeholders in KEYS:
            if key in arb:
                continue
            arb[key] = {"en": en, "hi": hi, "ta": ta}[lang]
            meta = arb.setdefault("@" + key, {"placeholders": {
                name: {"type": kind} for name, kind in placeholders.items()}})
            added += 1
        if not dry_run:
            path.write_text(json.dumps(arb, ensure_ascii=False, indent=2) + "\n",
                            encoding="utf-8")
    return added


def replace_concat(source: str, first: str) -> tuple[str, bool]:
    """Replace a whole `'a ' + 'b'` run that starts with `first`."""
    token = "'" + first + "'"
    start = source.find(token)
    if start < 0:
        return source, False
    i = start + len(token)
    while True:
        while i < len(source) and source[i] in " \n+":
            i += 1
        if i < len(source) and source[i] == "'":
            i += 1
            while i < len(source) and source[i] != "'":
                i += 2 if source[i] == "\\" else 1
            i += 1  # closing quote
            continue
        break
    return source[:start] + "@@SPAN@@", True, i


def main(argv: list[str]) -> int:
    dry_run = "--dry-run" in argv
    added = add_keys(dry_run)
    print(f"ARB: +{added} entry(s) across en/hi/ta")

    # Fragments first: they consume whole literal runs.
    touched = 0
    for rel, head, expression in FRAGMENTS:
        path = ROOT / rel
        source = path.read_text(encoding="utf-8")
        quote = source.find("'" + head)
        if quote < 0:
            print(f"  ! {rel}: fragment not found — {head!r}")
            continue
        i = quote + 1
        while True:
            while i < len(source) and source[i] != "'":
                i += 2 if source[i] == "\\" else 1
            i += 1                       # past the closing quote
            j = i
            while j < len(source) and source[j] in " \n+":
                j += 1
            if j < len(source) and source[j] == "'":
                i = j + 1                # another literal in the same run
                continue
            break
        touched += 1
        if dry_run:
            print(f"  ~ {rel}: would join -> {expression}")
        else:
            path.write_text(source[:quote] + expression + source[i:], encoding="utf-8")
            print(f"  ✓ {rel}: joined -> {expression}")

    # Placeholder sites.
    for rel, literal, expression in SITES:
        path = ROOT / rel
        if not path.exists():
            print(f"  ! missing file {rel}")
            continue
        source = path.read_text(encoding="utf-8")
        token = "'" + literal + "'"
        if token not in source:
            print(f"  ! {rel}: literal not found — {literal[:50]!r}")
            continue
        source = source.replace(token, expression)
        if not dry_run:
            path.write_text(source, encoding="utf-8")
        touched += 1
    print(f"\n{'Would touch' if dry_run else 'Touched'} {touched} site(s).")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
