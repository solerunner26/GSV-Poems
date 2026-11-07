/// Festivals and vrat days by the Gujarati (amanta) calendar.
library;

import 'panchang.dart';

enum FestivalKind { festival, ekadashi, purnima, amavasya, chaturthi }

class Festival {
  const Festival(this.names, this.kind, {this.icon = 'diya'});

  /// [gu, hi, en]
  final List<String> names;
  final FestivalKind kind;
  final String icon;
}

/// Which moment of the day decides the festival.
enum _At { sunrise, midday, afternoon, sunset, midnight }

class _Rule {
  const _Rule(this.month, this.tithi, this.festival, {this.at = _At.sunrise});
  final int month, tithi; // month 0 = Chaitra; tithi 1–30
  final Festival festival;
  final _At at;
}

int _tithiAt(PanchangDay p, _At at) => switch (at) {
      _At.sunrise => p.tithi,
      _At.midday => p.middayTithi,
      _At.afternoon => p.afternoonTithi,
      _At.sunset => p.sunsetTithi,
      _At.midnight => p.midnightTithi,
    };

const _rules = <_Rule>[
  _Rule(0, 1, Festival(['ચૈત્રી નવરાત્રિ પ્રારંભ', 'चैत्र नवरात्रि प्रारंभ', 'Chaitra Navratri begins'], FestivalKind.festival)),
  _Rule(0, 9, Festival(['રામ નવમી', 'राम नवमी', 'Ram Navami'], FestivalKind.festival)),
  _Rule(0, 15, Festival(['હનુમાન જયંતી', 'हनुमान जयंती', 'Hanuman Jayanti'], FestivalKind.festival)),
  _Rule(1, 3, Festival(['અખાત્રીજ', 'अक्षय तृतीया', 'Akshaya Tritiya'], FestivalKind.festival)),
  _Rule(3, 2, Festival(['રથયાત્રા', 'रथ यात्रा', 'Rath Yatra'], FestivalKind.festival)),
  _Rule(3, 11, Festival(['દેવપોઢી એકાદશી', 'देवशयनी एकादशी', 'Devshayani Ekadashi'], FestivalKind.ekadashi)),
  _Rule(3, 15, Festival(['ગુરુ પૂર્ણિમા', 'गुरु पूर्णिमा', 'Guru Purnima'], FestivalKind.purnima)),
  _Rule(4, 15, Festival(['રક્ષાબંધન', 'रक्षाबंधन', 'Raksha Bandhan'], FestivalKind.festival)),
  _Rule(4, 23, Festival(['જન્માષ્ટમી', 'जन्माष्टमी', 'Janmashtami'], FestivalKind.festival), at: _At.midnight),
  _Rule(5, 4, Festival(['ગણેશ ચતુર્થી', 'गणेश चतुर्थी', 'Ganesh Chaturthi'], FestivalKind.chaturthi), at: _At.midday),
  _Rule(6, 1, Festival(['નવરાત્રિ પ્રારંભ', 'नवरात्रि प्रारंभ', 'Navratri begins'], FestivalKind.festival)),
  _Rule(6, 10, Festival(['દશેરા', 'दशहरा', 'Dussehra'], FestivalKind.festival), at: _At.afternoon),
  _Rule(6, 15, Festival(['શરદ પૂનમ', 'शरद पूर्णिमा', 'Sharad Purnima'], FestivalKind.purnima)),
  _Rule(6, 26, Festival(['રમા એકાદશી', 'रमा एकादशी', 'Rama Ekadashi'], FestivalKind.ekadashi)),
  _Rule(6, 28, Festival(['ધનતેરસ', 'धनतेरस', 'Dhanteras'], FestivalKind.festival)),
  _Rule(6, 29, Festival(['કાળી ચૌદસ', 'नरक चतुर्दशी', 'Kali Chaudas'], FestivalKind.festival)),
  _Rule(6, 30, Festival(['દિવાળી', 'दीपावली', 'Diwali'], FestivalKind.festival), at: _At.sunset),
  _Rule(7, 1, Festival(['નૂતન વર્ષ (બેસતું વર્ષ)', 'नूतन वर्ष (गोवर्धन पूजा)', 'Gujarati New Year'], FestivalKind.festival)),
  _Rule(7, 2, Festival(['ભાઈબીજ', 'भाई दूज', 'Bhai Bij'], FestivalKind.festival)),
  _Rule(7, 5, Festival(['લાભ પાંચમ', 'लाभ पंचमी', 'Labh Pancham'], FestivalKind.festival)),
  _Rule(7, 11, Festival(['દેવ ઊઠી એકાદશી', 'देवउठनी एकादशी', 'Dev Uthi Ekadashi'], FestivalKind.ekadashi)),
  _Rule(7, 15, Festival(['દેવ દિવાળી', 'देव दीपावली', 'Dev Diwali'], FestivalKind.purnima)),
  _Rule(10, 5, Festival(['વસંત પંચમી', 'वसंत पंचमी', 'Vasant Panchami'], FestivalKind.festival)),
  _Rule(10, 29, Festival(['મહાશિવરાત્રિ', 'महाशिवरात्रि', 'Maha Shivratri'], FestivalKind.festival), at: _At.midnight),
  _Rule(11, 15, Festival(['હોળી', 'होली', 'Holi'], FestivalKind.festival), at: _At.sunset),
];

const _ekadashi = Festival(['એકાદશી', 'एकादशी', 'Ekadashi'], FestivalKind.ekadashi, icon: 'lotus');
const _purnima = Festival(['પૂનમ', 'पूर्णिमा', 'Purnima'], FestivalKind.purnima, icon: 'ghazal');
const _amavasya = Festival(['અમાસ', 'अमावस्या', 'Amavasya'], FestivalKind.amavasya, icon: 'ghazal');
const _sankashti = Festival(['સંકષ્ટ ચતુર્થી', 'संकष्टी चतुर्थी', 'Sankashti Chaturthi'], FestivalKind.chaturthi, icon: 'star');
const _uttarayan = Festival(['ઉત્તરાયણ (મકર સંક્રાંતિ)', 'मकर संक्रांति', 'Uttarayan (Makar Sankranti)'], FestivalKind.festival);
const _dhuleti = Festival(['ધુળેટી', 'धुलेंडी', 'Dhuleti'], FestivalKind.festival);

/// Does [tithi] fall on a day whose sunrise tithi is [cur] and whose next
/// sunrise tithi is [next]? Yes when it holds at sunrise, and also when it is
/// skipped (begins after this sunrise and ends before the next): a skipped
/// tithi is kept on the day it begins.
bool _onDay(int cur, int next, int tithi) {
  int dist(int a, int b) => (b - a + 30) % 30;
  if (cur == tithi) return true;
  final need = dist(cur, tithi);
  return need >= 1 && need < dist(cur, next);
}

List<Festival> _named(PanchangDay p, PanchangDay n) {
  // Festivals are kept in the regular (nija) month, never in an Adhik month.
  if (p.month.adhik) return const [];
  return [
    for (final r in _rules)
      if ((p.month.index == r.month || (r.tithi == 1 && n.month.index == r.month)) &&
          _onDay(_tithiAt(p, r.at), _tithiAt(n, r.at), r.tithi))
        r.festival,
  ];
}

/// Festivals and vrat days that fall on [day].
List<Festival> festivalsOn(DateTime day, Place place) {
  final d = DateTime(day.year, day.month, day.day);
  final p = panchangFor(d, place);
  final n = panchangFor(d.add(const Duration(days: 1)), place);
  final out = [..._named(p, n)];
  final kinds = {for (final f in out) f.kind};
  bool on(int t) => _onDay(p.tithi, n.tithi, t);
  if (!kinds.contains(FestivalKind.ekadashi) && (on(11) || on(26))) out.add(_ekadashi);
  if (!kinds.contains(FestivalKind.purnima) && on(15) && !out.any((f) => f.names[2] == 'Holi')) out.add(_purnima);
  if (on(30) && !out.any((f) => f.names[2] == 'Diwali')) out.add(_amavasya);
  if (on(19)) out.add(_sankashti);
  // Gujarat flies kites for Uttarayan on 14 January every year.
  if (d.month == 1 && d.day == 14) out.add(_uttarayan);
  // Dhuleti is the day after Holi.
  final y = panchangFor(d.subtract(const Duration(days: 1)), place);
  if (_named(y, p).any((f) => f.names[2] == 'Holi')) out.add(_dhuleti);
  return out;
}

/// Festival days from [from] for [days] days, in date order.
List<({DateTime date, Festival festival})> upcoming(DateTime from, Place place, {int days = 45}) {
  final start = DateTime(from.year, from.month, from.day);
  return [
    for (var i = 0; i < days; i++)
      for (final f in festivalsOn(start.add(Duration(days: i)), place)) (date: start.add(Duration(days: i)), festival: f),
  ];
}
