import 'poem_repository.dart';

/// The poet's own details, shown on the profile screen. Kept with the app's
/// settings, so they travel with backups.
class Profile {
  const Profile({this.name = '', this.penName = '', this.birthDate = '', this.place = '', this.phone = '', this.email = '', this.about = ''});

  final String name, penName, birthDate, place, phone, email, about;

  /// Field keys in display order; each is also its storage key suffix.
  static const fields = ['name', 'penName', 'birthDate', 'place', 'phone', 'email', 'about'];

  String operator [](String field) => switch (field) {
    'name' => name,
    'penName' => penName,
    'birthDate' => birthDate,
    'place' => place,
    'phone' => phone,
    'email' => email,
    'about' => about,
    _ => '',
  };

  static Profile fromMap(Map<String, String> m) => Profile(
    name: m['name'] ?? '',
    penName: m['penName'] ?? '',
    birthDate: m['birthDate'] ?? '',
    place: m['place'] ?? '',
    phone: m['phone'] ?? '',
    email: m['email'] ?? '',
    about: m['about'] ?? '',
  );

  Map<String, String> toMap() => {for (final f in fields) f: this[f].trim()};

  bool get isEmpty => fields.every((f) => this[f].trim().isEmpty);

  static Future<Profile> load(PoemRepository repo) async {
    final m = <String, String>{};
    for (final f in fields) {
      final v = await repo.getSetting('profile.$f');
      if (v != null) m[f] = v;
    }
    return fromMap(m);
  }

  Future<void> save(PoemRepository repo) async {
    for (final e in toMap().entries) {
      await repo.setSetting('profile.${e.key}', e.value);
    }
  }
}
