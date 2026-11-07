import 'package:geolocator/geolocator.dart';

import '../../core/panchang/panchang.dart';

/// Cities offered when GPS is not used. Names: [gu, hi, en].
const cities = <(List<String>, double, double)>[
  (['અમદાવાદ', 'अहमदाबाद', 'Ahmedabad'], 23.0225, 72.5714),
  (['ગાંધીનગર', 'गांधीनगर', 'Gandhinagar'], 23.2156, 72.6369),
  (['રાજકોટ', 'राजकोट', 'Rajkot'], 22.3039, 70.8022),
  (['સુરત', 'सूरत', 'Surat'], 21.1702, 72.8311),
  (['વડોદરા', 'वडोदरा', 'Vadodara'], 22.3072, 73.1812),
  (['ભાવનગર', 'भावनगर', 'Bhavnagar'], 21.7645, 72.1519),
  (['જૂનાગઢ', 'जूनागढ़', 'Junagadh'], 21.5222, 70.4579),
  (['જામનગર', 'जामनगर', 'Jamnagar'], 22.4707, 70.0577),
  (['કચ્છ (ભુજ)', 'भुज', 'Bhuj'], 23.2420, 69.6669),
  (['મુંબઈ', 'मुंबई', 'Mumbai'], 19.0760, 72.8777),
  (['દિલ્હી', 'दिल्ली', 'Delhi'], 28.6139, 77.2090),
  (['ઓકલેન્ડ (ન્યુઝીલેન્ડ)', 'ऑकलैंड (न्यूज़ीलैंड)', 'Auckland (New Zealand)'], -36.8485, 174.7633),
];

/// Reads the phone's location once (coarse is enough for sunrise times).
/// Returns null when location is off or permission is refused.
Future<Place?> placeFromGps() async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return null;
    final pos =
        await Geolocator.getLastKnownPosition() ??
        await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.low, timeLimit: Duration(seconds: 20)),
        );
    final lat = (pos.latitude * 100).round() / 100, lon = (pos.longitude * 100).round() / 100;
    // Name it after the nearest listed city when close by, else "GPS".
    var best = 'GPS';
    var bestD = 1e9;
    for (final c in cities) {
      final d = (c.$2 - lat) * (c.$2 - lat) + (c.$3 - lon) * (c.$3 - lon);
      if (d < bestD) {
        bestD = d;
        best = c.$1[2];
      }
    }
    return Place(bestD < 0.25 ? best : 'GPS', lat, lon);
  } on Object {
    return null;
  }
}
