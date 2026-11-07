/// Panchang names in Gujarati, Hindi and English: each list is [gu, hi, en].
library;

const tithiNames = <List<String>>[
  ['એકમ', 'प्रतिपदा', 'Pratipada'],
  ['બીજ', 'द्वितीया', 'Dwitiya'],
  ['ત્રીજ', 'तृतीया', 'Tritiya'],
  ['ચોથ', 'चतुर्थी', 'Chaturthi'],
  ['પાંચમ', 'पंचमी', 'Panchami'],
  ['છઠ', 'षष्ठी', 'Shashthi'],
  ['સાતમ', 'सप्तमी', 'Saptami'],
  ['આઠમ', 'अष्टमी', 'Ashtami'],
  ['નોમ', 'नवमी', 'Navami'],
  ['દશમ', 'दशमी', 'Dashami'],
  ['અગિયારસ', 'एकादशी', 'Ekadashi'],
  ['બારસ', 'द्वादशी', 'Dwadashi'],
  ['તેરસ', 'त्रयोदशी', 'Trayodashi'],
  ['ચૌદસ', 'चतुर्दशी', 'Chaturdashi'],
];
const purnima = ['પૂનમ', 'पूर्णिमा', 'Purnima'];
const amavasya = ['અમાસ', 'अमावस्या', 'Amavasya'];
const pakshaNames = <List<String>>[
  ['સુદ', 'शुक्ल', 'Shukla'],
  ['વદ', 'कृष्ण', 'Krishna'],
];

/// Amanta lunar months, 0 = Chaitra.
const monthNames = <List<String>>[
  ['ચૈત્ર', 'चैत्र', 'Chaitra'],
  ['વૈશાખ', 'वैशाख', 'Vaishakh'],
  ['જેઠ', 'ज्येष्ठ', 'Jyeshtha'],
  ['અષાઢ', 'आषाढ़', 'Ashadh'],
  ['શ્રાવણ', 'श्रावण', 'Shravan'],
  ['ભાદરવો', 'भाद्रपद', 'Bhadrapad'],
  ['આસો', 'आश्विन', 'Ashvin'],
  ['કારતક', 'कार्तिक', 'Kartik'],
  ['માગશર', 'मार्गशीर्ष', 'Margashirsha'],
  ['પોષ', 'पौष', 'Paush'],
  ['મહા', 'माघ', 'Magh'],
  ['ફાગણ', 'फाल्गुन', 'Phalgun'],
];
const adhikName = ['અધિક', 'अधिक', 'Adhik'];

/// 0 = Sunday.
const vaarNames = <List<String>>[
  ['રવિવાર', 'रविवार', 'Sunday'],
  ['સોમવાર', 'सोमवार', 'Monday'],
  ['મંગળવાર', 'मंगलवार', 'Tuesday'],
  ['બુધવાર', 'बुधवार', 'Wednesday'],
  ['ગુરુવાર', 'गुरुवार', 'Thursday'],
  ['શુક્રવાર', 'शुक्रवार', 'Friday'],
  ['શનિવાર', 'शनिवार', 'Saturday'],
];

const nakshatraNames = <List<String>>[
  ['અશ્વિની', 'अश्विनी', 'Ashwini'],
  ['ભરણી', 'भरणी', 'Bharani'],
  ['કૃત્તિકા', 'कृत्तिका', 'Krittika'],
  ['રોહિણી', 'रोहिणी', 'Rohini'],
  ['મૃગશીર્ષ', 'मृगशिरा', 'Mrigashira'],
  ['આર્દ્રા', 'आर्द्रा', 'Ardra'],
  ['પુનર્વસુ', 'पुनर्वसु', 'Punarvasu'],
  ['પુષ્ય', 'पुष्य', 'Pushya'],
  ['આશ્લેષા', 'आश्लेषा', 'Ashlesha'],
  ['મઘા', 'मघा', 'Magha'],
  ['પૂર્વા ફાલ્ગુની', 'पूर्वा फाल्गुनी', 'Purva Phalguni'],
  ['ઉત્તરા ફાલ્ગુની', 'उत्तरा फाल्गुनी', 'Uttara Phalguni'],
  ['હસ્ત', 'हस्त', 'Hasta'],
  ['ચિત્રા', 'चित्रा', 'Chitra'],
  ['સ્વાતિ', 'स्वाति', 'Swati'],
  ['વિશાખા', 'विशाखा', 'Vishakha'],
  ['અનુરાધા', 'अनुराधा', 'Anuradha'],
  ['જ્યેષ્ઠા', 'ज्येष्ठा', 'Jyeshtha'],
  ['મૂળ', 'मूल', 'Mula'],
  ['પૂર્વાષાઢા', 'पूर्वाषाढ़ा', 'Purva Ashadha'],
  ['ઉત્તરાષાઢા', 'उत्तराषाढ़ा', 'Uttara Ashadha'],
  ['શ્રવણ', 'श्रवण', 'Shravana'],
  ['ધનિષ્ઠા', 'धनिष्ठा', 'Dhanishtha'],
  ['શતભિષા', 'शतभिषा', 'Shatabhisha'],
  ['પૂર્વા ભાદ્રપદ', 'पूर्वा भाद्रपद', 'Purva Bhadrapada'],
  ['ઉત્તરા ભાદ્રપદ', 'उत्तरा भाद्रपद', 'Uttara Bhadrapada'],
  ['રેવતી', 'रेवती', 'Revati'],
];

const yogaNames = <List<String>>[
  ['વિષ્કુંભ', 'विष्कम्भ', 'Vishkambha'],
  ['પ્રીતિ', 'प्रीति', 'Priti'],
  ['આયુષ્માન', 'आयुष्मान', 'Ayushman'],
  ['સૌભાગ્ય', 'सौभाग्य', 'Saubhagya'],
  ['શોભન', 'शोभन', 'Shobhana'],
  ['અતિગંડ', 'अतिगण्ड', 'Atiganda'],
  ['સુકર્મા', 'सुकर्मा', 'Sukarma'],
  ['ધૃતિ', 'धृति', 'Dhriti'],
  ['શૂલ', 'शूल', 'Shula'],
  ['ગંડ', 'गण्ड', 'Ganda'],
  ['વૃદ્ધિ', 'वृद्धि', 'Vriddhi'],
  ['ધ્રુવ', 'ध्रुव', 'Dhruva'],
  ['વ્યાઘાત', 'व्याघात', 'Vyaghata'],
  ['હર્ષણ', 'हर्षण', 'Harshana'],
  ['વજ્ર', 'वज्र', 'Vajra'],
  ['સિદ્ધિ', 'सिद्धि', 'Siddhi'],
  ['વ્યતિપાત', 'व्यतीपात', 'Vyatipata'],
  ['વરીયાન', 'वरीयान', 'Variyana'],
  ['પરિઘ', 'परिघ', 'Parigha'],
  ['શિવ', 'शिव', 'Shiva'],
  ['સિદ્ધ', 'सिद्ध', 'Siddha'],
  ['સાધ્ય', 'साध्य', 'Sadhya'],
  ['શુભ', 'शुभ', 'Shubha'],
  ['શુક્લ', 'शुक्ल', 'Shukla'],
  ['બ્રહ્મ', 'ब्रह्म', 'Brahma'],
  ['ઇન્દ્ર', 'इन्द्र', 'Indra'],
  ['વૈધૃતિ', 'वैधृति', 'Vaidhriti'],
];

/// 0–6 the seven moving karanas, then Shakuni, Chatushpada, Naga, Kimstughna.
const karanaNames = <List<String>>[
  ['બવ', 'बव', 'Bava'],
  ['બાલવ', 'बालव', 'Balava'],
  ['કૌલવ', 'कौलव', 'Kaulava'],
  ['તૈતિલ', 'तैतिल', 'Taitila'],
  ['ગર', 'गर', 'Gara'],
  ['વણિજ', 'वणिज', 'Vanija'],
  ['વિષ્ટિ', 'विष्टि', 'Vishti'],
  ['શકુનિ', 'शकुनि', 'Shakuni'],
  ['ચતુષ્પદ', 'चतुष्पद', 'Chatushpada'],
  ['નાગ', 'नाग', 'Naga'],
  ['કિંસ્તુઘ્ન', 'किंस्तुघ्न', 'Kimstughna'],
];

enum ChoghadiyaKind { amrit, shubh, labh, char, udveg, rog, kaal }

const choghadiyaNames = <ChoghadiyaKind, List<String>>{
  ChoghadiyaKind.amrit: ['અમૃત', 'अमृत', 'Amrit'],
  ChoghadiyaKind.shubh: ['શુભ', 'शुभ', 'Shubh'],
  ChoghadiyaKind.labh: ['લાભ', 'लाभ', 'Labh'],
  ChoghadiyaKind.char: ['ચલ', 'चर', 'Char'],
  ChoghadiyaKind.udveg: ['ઉદ્વેગ', 'उद्वेग', 'Udveg'],
  ChoghadiyaKind.rog: ['રોગ', 'रोग', 'Rog'],
  ChoghadiyaKind.kaal: ['કાળ', 'काल', 'Kaal'],
};

/// Good (Amrit, Shubh, Labh), neutral (Char) or not good (Udveg, Rog, Kaal).
enum Quality { good, neutral, bad }

Quality qualityOf(ChoghadiyaKind k) => switch (k) {
  ChoghadiyaKind.amrit || ChoghadiyaKind.shubh || ChoghadiyaKind.labh => Quality.good,
  ChoghadiyaKind.char => Quality.neutral,
  _ => Quality.bad,
};

const qualityNames = <Quality, List<String>>{
  Quality.good: ['શુભ', 'शुभ', 'Good'],
  Quality.neutral: ['સામાન્ય', 'सामान्य', 'Neutral'],
  Quality.bad: ['અશુભ', 'अशुभ', 'Not good'],
};
