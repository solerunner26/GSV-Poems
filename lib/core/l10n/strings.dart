import 'package:flutter/widgets.dart';

import '../text/text_tools.dart';

/// Interface text in Gujarati, Hindi and English: [gu, hi, en].
const Map<String, List<String>> _t = {
  'app_title': ['કાવ્ય સંગ્રહ', 'काव्य संग्रह', 'Poem Collection'],
  'greeting': ['જય શ્રી કૃષ્ણ', 'जय श्री कृष्ण', 'Jai Shri Krishna'],
  'enter': ['પ્રવેશ કરો', 'प्रवेश करें', 'Enter'],
  'poet_name': ['ગીગાભાઈ સનાભાઈ વાળા "ગૌરવ"', 'गीगाभाई सनाभाई वाला "गौरव"', 'Gigabhai Sanabhai Vala "Gaurav"'],
  'poet_pen': ['ગૌરવ', 'गौरव', 'Gaurav'],
  'pin_enter': ['તમારો PIN લખો', 'अपना PIN डालें', 'Enter your PIN'],
  'pin_enter_sub': ['4 આંકડાનો PIN', '4 अंकों का PIN', 'Your 4-digit PIN'],
  'pin_new': ['નવો 4 આંકડાનો PIN બનાવો', 'नया 4 अंकों का PIN बनाएँ', 'Create a 4-digit PIN'],
  'pin_new_sub': ['એપ ખોલવા આ PIN જોઈશે', 'ऐप खोलने के लिए यह PIN चाहिए', 'You will need it to open the app'],
  'pin_confirm': ['એ જ PIN ફરી લખો', 'वही PIN फिर से डालें', 'Enter the same PIN again'],
  'pin_mismatch': ['બંને PIN જુદા છે. ફરી પ્રયત્ન કરો.', 'दोनों PIN अलग हैं। फिर कोशिश करें।', 'The PINs did not match. Try again.'],
  'pin_wrong': ['ખોટો PIN. ફરી પ્રયત્ન કરો.', 'गलत PIN। फिर कोशिश करें।', 'Wrong PIN. Try again.'],
  'pin_locked': ['ઘણા ખોટા પ્રયત્ન. 30 સેકન્ડ રાહ જુઓ.', 'कई गलत प्रयास। 30 सेकंड रुकें।', 'Too many tries. Wait 30 seconds.'],
  'pin_forgot': ['PIN ભૂલી ગયા?', 'PIN भूल गए?', 'Forgot PIN?'],
  'pin_forgot_body': [
    'Recovery key થી PIN બદલી શકાશે. આ સુવિધા બેકઅપ સાથે આવતા અપડેટમાં આવશે. ત્યાં સુધી PIN યાદ રાખજો.',
    'Recovery key से PIN बदला जा सकेगा। यह सुविधा बैकअप के साथ अगले अपडेट में आएगी। तब तक PIN याद रखें।',
    'You will be able to reset the PIN with the recovery key. That arrives with the backup update. Until then, please remember the PIN.'
  ],
  'pin_changed': ['PIN બદલાઈ ગયો', 'PIN बदल गया', 'PIN changed'],
  'pin_current': ['હાલનો PIN લખો', 'वर्तमान PIN डालें', 'Enter your current PIN'],
  'fingerprint_reason': ['એપ ખોલવા આંગળી મૂકો', 'ऐप खोलने के लिए उंगली रखें', 'Touch the sensor to open the app'],
  'unlock_fingerprint': ['આંગળીથી ખોલો', 'उंगली से खोलें', 'Unlock with fingerprint'],
  'delete_digit': ['છેલ્લો આંકડો ભૂંસો', 'आखिरी अंक मिटाएँ', 'Delete last digit'],
  'nav_settings': ['સેટિંગ', 'सेटिंग', 'Settings'],
  'nav_search': ['શોધ', 'खोज', 'Search'],
  'nav_home': ['હોમ', 'होम', 'Home'],
  'nav_write': ['લખો', 'लिखें', 'Write'],
  'nav_collection': ['સંગ્રહ', 'संग्रह', 'Collection'],
  'panchang_soon': ['પંચાંગ અને ચોઘડિયાં આવતા અપડેટમાં', 'पंचांग और चौघड़िया अगले अपडेट में', 'Panchang & Choghadiya arrive in the next update'],
  'recent7': ['છેલ્લા ૭ દિવસની કવિતા', 'पिछले 7 दिनों की कविताएँ', 'Poems from the last 7 days'],
  'clear_list': ['યાદી સાફ કરો', 'सूची साफ़ करें', 'Clear list'],
  'list_cleared': ['યાદી સાફ થઈ. કવિતા સંગ્રહમાં સલામત છે.', 'सूची साफ़ हुई। कविताएँ संग्रह में सुरक्षित हैं।', 'List cleared. The poems are safe in the collection.'],
  'favorites': ['મનગમતી કવિતા', 'पसंदीदा कविताएँ', 'Favourite poems'],
  'no_favorites': ['કવિતા વાંચતી વખતે ★ દબાવો, તે અહીં દેખાશે', 'कविता पढ़ते समय ★ दबाएँ, वह यहाँ दिखेगी', 'Tap ★ while reading a poem to see it here'],
  'total_poems': ['કુલ કવિતા', 'कुल कविताएँ', 'Total poems'],
  'total_words': ['કુલ શબ્દો', 'कुल शब्द', 'Total words'],
  'lang_gu': ['ગુજરાતી', 'गुजराती', 'Gujarati'],
  'lang_hi': ['हिन्दी', 'हिन्दी', 'Hindi'],
  'lang_en': ['English', 'English', 'English'],
  'on_this_day': ['આજના દિવસે', 'आज के दिन', 'On this day'],
  'poem_of_day': ['આજની કવિતા', 'आज की कविता', 'Poem of the day'],
  'read_full': ['પૂરી કવિતા વાંચો', 'पूरी कविता पढ़ें', 'Read the full poem'],
  'no_poems': ['હજી કોઈ કવિતા નથી', 'अभी कोई कविता नहीं', 'No poems yet'],
  'write_first': ['પહેલી કવિતા લખો', 'पहली कविता लिखें', 'Write the first poem'],
  'editor_new': ['નવી કવિતા', 'नई कविता', 'New poem'],
  'editor_edit': ['કવિતા સુધારો', 'कविता बदलें', 'Edit poem'],
  'title_hint': ['શીર્ષક (ન લખો તો પહેલી પંક્તિ)', 'शीर्षक (न लिखें तो पहली पंक्ति)', 'Title (first line if left empty)'],
  'body_label': ['કવિતા', 'कविता', 'Poem'],
  'body_hint': ['અહીં કવિતા લખો…', 'यहाँ कविता लिखें…', 'Write your poem here…'],
  'keyboard_tip': ['ગુજરાતી Gboard, Alaya કે માઈક — ગમે તે વાપરો', 'हिंदी Gboard, Alaya या माइक — कुछ भी चुनें', 'Gujarati Gboard, Alaya or the mic — any works'],
  'autosaved': ['આપમેળે સચવાયું', 'अपने-आप सहेजा गया', 'Saved automatically'],
  'words': ['શબ્દો', 'शब्द', 'words'],
  'voice': ['બોલીને લખો', 'बोलकर लिखें', 'Speak to write'],
  'listening': ['સાંભળે છે…', 'सुन रहा है…', 'Listening…'],
  'voice_unavailable': ['આ ફોનમાં અવાજથી લખવાનું ચાલુ નથી. Gboard નું માઈક વાપરો.', 'इस फ़ोन में आवाज़ से लिखना उपलब्ध नहीं। Gboard का माइक इस्तेमाल करें।', 'Voice typing is not available here. Use the mic on Gboard.'],
  'save': ['સાચવો', 'सहेजें', 'Save'],
  'saved': ['કવિતા સચવાઈ ગઈ', 'कविता सहेज ली गई', 'Poem saved'],
  'empty_poem': ['પહેલાં કવિતા લખો', 'पहले कविता लिखें', 'Write the poem first'],
  'back': ['પાછા', 'वापस', 'Back'],
  'category': ['વિભાગ', 'विभाग', 'Category'],
  'no_category': ['વિભાગ નથી', 'कोई विभाग नहीं', 'No category'],
  'undo': ['પાછું કરો', 'पूर्ववत करें', 'Undo'],
  'smaller': ['નાના', 'छोटे', 'Smaller'],
  'bigger': ['મોટા', 'बड़े', 'Bigger'],
  'read_aloud': ['સાંભળો', 'सुनें', 'Listen'],
  'stop': ['બંધ', 'रोकें', 'Stop'],
  'favorite': ['મનગમતી', 'पसंदीदा', 'Favourite'],
  'share': ['મોકલો', 'भेजें', 'Share'],
  'edit': ['સુધારો', 'बदलें', 'Edit'],
  'swipe_hint': ['← આગળ / પાછળની કવિતા માટે ખસેડો →', '← अगली / पिछली कविता के लिए सरकाएँ →', '← Swipe for next / previous poem →'],
  'delete': ['કચરાપેટીમાં મૂકો', 'कूड़ेदान में डालें', 'Move to recycle bin'],
  'moved_to_bin': ['કચરાપેટીમાં મૂકી', 'कूड़ेदान में डाली', 'Moved to recycle bin'],
  'restore': ['પાછી લાવો', 'वापस लाएँ', 'Restore'],
  'restored': ['કવિતા પાછી આવી', 'कविता वापस आ गई', 'Poem restored'],
  'delete_forever': ['કાયમ માટે ભૂંસો', 'हमेशा के लिए मिटाएँ', 'Delete forever'],
  'confirm_forever': ['આ કવિતા કાયમ માટે ભૂંસાઈ જશે. પાછી નહીં આવે.', 'यह कविता हमेशा के लिए मिट जाएगी। वापस नहीं आएगी।', 'This poem will be erased for good. It cannot come back.'],
  'confirm_forever2': ['ખરેખર? છેલ્લી વાર પૂછીએ છીએ.', 'सच में? आखिरी बार पूछ रहे हैं।', 'Are you sure? Asking one last time.'],
  'cancel': ['રહેવા દો', 'रहने दें', 'Cancel'],
  'yes_delete': ['હા, ભૂંસો', 'हाँ, मिटाएँ', 'Yes, delete'],
  'search_hint': ['કોઈ પણ ૩ અક્ષર લખો…', 'कोई भी 3 अक्षर लिखें…', 'Type any 3 letters…'],
  'search_min3': ['ઓછામાં ઓછા ૩ અક્ષર લખો', 'कम से कम 3 अक्षर लिखें', 'Type at least 3 letters'],
  'found': ['કવિતા મળી', 'कविताएँ मिलीं', 'poems found'],
  'filter_all': ['બધી', 'सभी', 'All'],
  'no_results': ['કંઈ ન મળ્યું. બીજો શબ્દ લખી જુઓ.', 'कुछ नहीं मिला। दूसरा शब्द आज़माएँ।', 'Nothing found. Try another word.'],
  'cross_script': ['અંગ્રેજી અક્ષરથી પણ શોધી શકો: "prem"', 'अंग्रेज़ी अक्षरों से भी खोज सकते हैं: "prem"', 'Latin letters work too: "prem"'],
  'all_poems': ['બધી કવિતા', 'सभी कविताएँ', 'All poems'],
  'recycle_bin': ['કચરાપેટી', 'कूड़ेदान', 'Recycle bin'],
  'bin_empty': ['કચરાપેટી ખાલી છે', 'कूड़ेदान खाली है', 'The recycle bin is empty'],
  'bin_note': ['અહીંની કવિતા "પાછી લાવો" થી પાછી આવે છે', 'यहाँ की कविताएँ "वापस लाएँ" से लौटती हैं', 'Poems here come back with "Restore"'],
  'sort_newest': ['નવી પહેલાં', 'नई पहले', 'Newest first'],
  'sort_oldest': ['જૂની પહેલાં', 'पुरानी पहले', 'Oldest first'],
  'sort_number': ['ક્રમાંક પ્રમાણે', 'क्रमांक से', 'By number'],
  'sort_title': ['શીર્ષક પ્રમાણે', 'शीर्षक से', 'By title'],
  'poems': ['કવિતા', 'कविताएँ', 'poems'],
  'today': ['આજે', 'आज', 'Today'],
  'yesterday': ['ગઈકાલે', 'कल', 'Yesterday'],
  'days_ago': ['દિવસ પહેલાં', 'दिन पहले', 'days ago'],
  'settings_title': ['સેટિંગ', 'सेटिंग', 'Settings'],
  'sec_look': ['દેખાવ', 'रूप', 'Appearance'],
  'sec_security': ['સુરક્ષા', 'सुरक्षा', 'Security'],
  'sec_backup': ['બેકઅપ અને સિંક', 'बैकअप और सिंक', 'Backup & sync'],
  'sec_help': ['મદદ', 'मदद', 'Help'],
  'theme': ['થીમ', 'थीम', 'Theme'],
  'language': ['ભાષા · भाषा · Language', 'भाषा · ભાષા · Language', 'Language · ભાષા · भाषा'],
  'text_size': ['અક્ષરનું કદ', 'अक्षर का आकार', 'Text size'],
  'size_m': ['સામાન્ય', 'सामान्य', 'Normal'],
  'size_l': ['મોટું', 'बड़ा', 'Large'],
  'size_xl': ['ખૂબ મોટું', 'बहुत बड़ा', 'Extra large'],
  'change_pin': ['PIN બદલો', 'PIN बदलें', 'Change PIN'],
  'fingerprint': ['આંગળીની છાપથી ખોલો', 'उंगली की छाप से खोलें', 'Unlock with fingerprint'],
  'fingerprint_none': ['આ ફોનમાં આંગળીની છાપ સેટ નથી', 'इस फ़ोन में फ़िंगरप्रिंट सेट नहीं है', 'No fingerprint is set up on this phone'],
  'backup_soon': ['એન્ક્રિપ્ટેડ બેકઅપ, WhatsApp, ઈમેલ, Drive — આવતા અપડેટમાં', 'एन्क्रिप्टेड बैकअप, WhatsApp, ईमेल, Drive — अगले अपडेट में', 'Encrypted backup, WhatsApp, email, Drive — next update'],
  'keep_soon': ['Google Keep થી કવિતા લાવો — આવતા અપડેટમાં', 'Google Keep से कविताएँ लाएँ — अगले अपडेट में', 'Import from Google Keep — next update'],
  'keep_import': ['Google Keep થી કવિતા લાવો', 'Google Keep से कविताएँ लाएँ', 'Import from Google Keep'],
  'keep_import_sub': ['Takeout ની .json ફાઈલો', 'Takeout की .json फ़ाइलें', 'Takeout .json files'],
  'keep_how': [
    'Google Takeout માંથી Keep ની .json ફાઈલો આ ફોનમાં રાખો. પછી નીચેનું બટન દબાવી બધી ફાઈલો પસંદ કરો. દરેક ફાઈલનું નામ સંગ્રહનું નામ બનશે. એક જ ફાઈલ બે વાર લાવશો તો પણ કવિતા બે વાર નહીં ઉમેરાય.',
    'Google Takeout से Keep की .json फ़ाइलें इस फ़ोन में रखें। फिर नीचे का बटन दबाकर सभी फ़ाइलें चुनें। हर फ़ाइल का नाम संग्रह का नाम बनेगा। एक ही फ़ाइल दो बार लाने पर भी कविता दो बार नहीं जुड़ेगी।',
    'Put the Keep .json files from Google Takeout on this phone, then tap the button below and select them all. Each file\'s title becomes a collection. Importing the same file twice never adds a poem twice.'
  ],
  'keep_pick': ['ફાઈલો પસંદ કરો', 'फ़ाइलें चुनें', 'Choose files'],
  'keep_reading': ['ફાઈલો વાંચે છે…', 'फ़ाइलें पढ़ रहा है…', 'Reading files…'],
  'keep_found': ['કવિતા મળી', 'कविताएँ मिलीं', 'poems found'],
  'keep_in': ['સંગ્રહમાં', 'संग्रहों में', 'collections'],
  'keep_add': ['બધી કવિતા ઉમેરો', 'सभी कविताएँ जोड़ें', 'Add all poems'],
  'keep_done': ['નવી કવિતા ઉમેરાઈ', 'नई कविताएँ जुड़ीं', 'new poems added'],
  'keep_already': ['પહેલેથી હતી', 'पहले से थीं', 'were already there'],
  'keep_missing': ['યાદીમાં છે પણ કવિતા લખાઈ નથી', 'सूची में है पर कविता लिखी नहीं', 'Listed in contents but not written yet'],
  'keep_skipped': ['ખાલી કે કચરાપેટીની નોંધ, છોડી દીધી', 'खाली या कूड़ेदान की नोट, छोड़ दी', 'Empty or trashed notes, skipped'],
  'keep_none': ['આ ફાઈલોમાં કોઈ કવિતા ન મળી', 'इन फ़ाइलों में कोई कविता नहीं मिली', 'No poems found in these files'],
  'dup_title': ['એકસરખી કવિતા', 'एक जैसी कविताएँ', 'Duplicate poems'],
  'dup_note': ['કંઈ પણ આપમેળે ભૂંસાતું નથી', 'कुछ भी अपने-आप नहीं मिटता', 'Nothing is removed by itself'],
  'dup_none': ['કોઈ એકસરખી કવિતા નથી', 'कोई एक जैसी कविता नहीं', 'No duplicate poems'],
  'dup_found': ['એકસરખી કવિતા મળી', 'एक जैसी कविताएँ मिलीं', 'duplicate poems found'],
  'dup_review': ['જોવા અને વધારાની કાઢવા અહીં દબાવો', 'देखने और अतिरिक्त हटाने के लिए दबाएँ', 'Tap to review and remove the extra copies'],
  'dup_keep_this': ['આ રાખો', 'यह रखें', 'Keep this one'],
  'dup_remove_all': ['બધી વધારાની નકલ કાઢો', 'सभी अतिरिक्त प्रतियाँ हटाएँ', 'Remove all extra copies'],
  'dup_remove_all_body': [
    'વધારાની નકલ કચરાપેટીમાં જશે. દરેકની પહેલી (સૌથી જૂની) નકલ રહેશે. જરૂર પડે તો કચરાપેટીમાંથી પાછી લાવી શકાય.',
    'अतिरिक्त प्रतियाँ कूड़ेदान में जाएँगी। हर कविता की पहली (सबसे पुरानी) प्रति रहेगी। ज़रूरत हो तो कूड़ेदान से वापस ला सकते हैं।',
    'extra copies will go to the recycle bin. The first (oldest) copy of each poem stays. You can bring them back from the recycle bin.'
  ],
  'dup_yes': ['હા, કાઢો', 'हाँ, हटाएँ', 'Yes, remove'],
  'dup_moved': ['નકલ કચરાપેટીમાં મૂકી', 'प्रतियाँ कूड़ेदान में डालीं', 'copies moved to the recycle bin'],
  'dup_in_editor': ['આ કવિતા પહેલેથી સંગ્રહમાં છે', 'यह कविता पहले से संग्रह में है', 'This poem is already in the collection'],
  'dup_open': ['જુઓ', 'देखें', 'Open'],
  'dup_save_anyway': ['છતાં સાચવવી છે?', 'फिर भी सहेजें?', 'Save it anyway?'],
  'dup_save_anyway_body': ['આ જ કવિતા પહેલેથી છે. બીજી નકલ સાચવશો તો "એકસરખી કવિતા" માં દેખાશે.', 'यही कविता पहले से है। दूसरी प्रति सहेजेंगे तो "एक जैसी कविताएँ" में दिखेगी।', 'The same poem already exists. A second copy will be listed under "Duplicate poems".'],
  'save_anyway': ['હા, સાચવો', 'हाँ, सहेजें', 'Yes, save'],
  'update_title': ['નવું અપડેટ આવ્યું', 'नया अपडेट आया', 'A new update is ready'],
  'update_current': ['હાલની આવૃત્તિ', 'वर्तमान संस्करण', 'Current version'],
  'update_safe': ['બધી કવિતા સલામત રહેશે. "હમણાં અપડેટ કરો" દબાવો, પછી "Install" દબાવો.', 'सभी कविताएँ सुरक्षित रहेंगी। "अभी अपडेट करें" दबाएँ, फिर "Install" दबाएँ।', 'All poems stay safe. Tap "Update Now", then tap "Install".'],
  'update_now': ['હમણાં અપડેટ કરો', 'अभी अपडेट करें', 'Update Now'],
  'update_later': ['પછી', 'बाद में', 'Later'],
  'update_downloading': ['ડાઉનલોડ થાય છે…', 'डाउनलोड हो रहा है…', 'Downloading…'],
  'update_failed': ['અપડેટ ન થયું. ઇન્ટરનેટ ચાલુ છે તે જુઓ.', 'अपडेट नहीं हुआ। इंटरनेट चालू है देखें।', 'The update did not finish. Check the internet connection.'],
  'up_to_date': ['એપ નવીનતમ છે', 'ऐप नवीनतम है', 'The app is up to date'],
  'check_update': ['અપડેટ તપાસો', 'अपडेट जाँचें', 'Check for update'],
  'help': ['કેવી રીતે વાપરવું', 'कैसे इस्तेमाल करें', 'How to use'],
  'version': ['આવૃત્તિ', 'संस्करण', 'Version'],
  'history': ['જૂની આવૃત્તિઓ', 'पुराने संस्करण', 'Earlier versions'],
  'no_history': ['હજી કોઈ જૂની આવૃત્તિ નથી', 'अभी कोई पुराना संस्करण नहीं', 'No earlier versions yet'],
  'use_version': ['આ આવૃત્તિ પાછી લાવો', 'यह संस्करण वापस लाएँ', 'Bring this version back'],
  'more': ['વધુ', 'और', 'More'],
  'close': ['બંધ કરો', 'बंद करें', 'Close'],
  'help_for_screen': ['આ સ્ક્રીનની મદદ', 'इस स्क्रीन की मदद', 'Help for this screen'],
};

/// Help text per screen: [gu, hi, en].
const Map<String, List<String>> helpText = {
  'home': [
    'હોમ પર આજની તારીખ, તાજી લખેલી કવિતા, મનગમતી કવિતા અને કુલ કવિતા દેખાય છે. નીચેના પટ્ટામાં વચ્ચેનું બટન હંમેશાં અહીં પાછું લાવે છે. "લખો" દબાવી નવી કવિતા લખો.',
    'होम पर आज की तारीख, हाल की कविताएँ, पसंदीदा और कुल कविताएँ दिखती हैं। नीचे बीच का बटन हमेशा यहाँ लाता है। "लिखें" दबाकर नई कविता लिखें।',
    'Home shows today\'s date, recent poems, favourites and totals. The middle button at the bottom always brings you here. Tap "Write" to write a new poem.'
  ],
  'editor': [
    'ઉપર શીર્ષક, નીચે કવિતા લખો. ગુજરાતી Gboard, Alaya કે "બોલીને લખો" બટન વાપરો. કવિતા આપમેળે સચવાય છે. અંતે "સાચવો" દબાવો.',
    'ऊपर शीर्षक, नीचे कविता लिखें। Gboard, Alaya या "बोलकर लिखें" बटन इस्तेमाल करें। कविता अपने-आप सहेजी जाती है। अंत में "सहेजें" दबाएँ।',
    'Write the title at the top and the poem below. Use Gboard, Alaya or "Speak to write". The poem saves automatically; tap "Save" at the end.'
  ],
  'reader': [
    'A− / A+ થી અક્ષર નાના-મોટા કરો. "સાંભળો" દબાવી કવિતા સાંભળો. ★ દબાવી મનગમતી બનાવો. "મોકલો" થી WhatsApp પર મોકલો. આંગળી ડાબે-જમણે ખસેડી બીજી કવિતા જુઓ.',
    'A− / A+ से अक्षर छोटे-बड़े करें। "सुनें" से कविता सुनें। ★ से पसंदीदा बनाएँ। "भेजें" से WhatsApp पर भेजें। उंगली दाएँ-बाएँ सरकाकर दूसरी कविता देखें।',
    'A− / A+ change the text size. "Listen" reads the poem aloud. ★ marks it as a favourite. "Share" sends it on WhatsApp. Swipe left or right for other poems.'
  ],
  'search': [
    'કોઈ પણ ૩ અક્ષર લખતાં જ એ શબ્દવાળી બધી કવિતા દેખાય છે — ગુજરાતી, હિન્દી કે અંગ્રેજી અક્ષરમાં. કવિતા પર દબાવી વાંચો.',
    'कोई भी 3 अक्षर लिखते ही वह शब्द वाली सभी कविताएँ दिखती हैं — गुजराती, हिंदी या अंग्रेज़ी में। कविता पर दबाकर पढ़ें।',
    'Type any 3 letters and every poem containing them appears — Gujarati, Hindi or English letters. Tap a poem to read it.'
  ],
  'collection': [
    'અહીં વિભાગ પ્રમાણે બધી કવિતા છે. "⋯" દબાવી સુધારો, મોકલો કે કચરાપેટીમાં મૂકો. કચરાપેટીમાંથી "પાછી લાવો" દબાવી કવિતા પાછી લાવી શકાય.',
    'यहाँ विभाग के अनुसार सभी कविताएँ हैं। "⋯" दबाकर बदलें, भेजें या कूड़ेदान में डालें। कूड़ेदान से "वापस लाएँ" दबाकर कविता लौटाई जा सकती है।',
    'All poems by category. Tap "⋯" to edit, share or move to the recycle bin. In the recycle bin, "Restore" brings a poem back.'
  ],
  'settings': [
    'થીમ, ભાષા, અક્ષરનું કદ અને PIN અહીં બદલો. બેકઅપની સુવિધા આવતા અપડેટમાં અહીં આવશે.',
    'थीम, भाषा, अक्षर का आकार और PIN यहाँ बदलें। बैकअप की सुविधा अगले अपडेट में यहाँ आएगी।',
    'Change theme, language, text size and PIN here. Backup arrives here in the next update.'
  ],
};

/// Supplies the active interface language. Wrapping a subtree in a
/// [LangScope] switches just that part (e.g. a Hindi poem shows Hindi buttons).
class LangScope extends InheritedWidget {
  const LangScope({super.key, required this.lang, required super.child});
  final PoemLang lang;

  static PoemLang of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LangScope>()?.lang ?? PoemLang.gu;

  @override
  bool updateShouldNotify(LangScope old) => old.lang != lang;
}

String tr(String key, PoemLang lang) {
  final v = _t[key];
  if (v == null) return key;
  return v[lang.index];
}

extension Tr on BuildContext {
  PoemLang get lang => LangScope.of(this);
  String t(String key) => tr(key, LangScope.of(this));
  String help(String screen) => (helpText[screen] ?? const ['', '', ''])[LangScope.of(this).index];
}
