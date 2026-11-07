import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';

import '../theme/app_themes.dart';
import '../theme/neon_tokens.dart';

/// Art for one 3D clay icon: tile colour, highlight colour, label and
/// path layers on a 24×24 grid (f = filled body, s = tube strokes,
/// h = carved fills, c = carved strokes). Same art as the design canvas.
class IconArt {
  const IconArt(this.base, this.glyph, this.label, this.f, this.s, this.h, this.c);
  final Color base, glyph;
  final String label, f, s, h, c;
}

const _teal = Color(0xFF0E5E5A), _peacock = Color(0xFF2D6CB5), _peach = Color(0xFFFFC48A);
const _white = Color(0xFFFFFFFF), _aqua = Color(0xFF8FE3DA);

const iconArt = <String, IconArt>{
  'lotus': IconArt(
    _teal,
    _peach,
    'Lotus',
    'M12 3.5c2.4 3.4 2.4 7.6 0 11.5c-2.4-3.9-2.4-8.1 0-11.5zM12 15c-1.8-3.8-5-6-9.5-6.6c.6 4 4.2 6.6 9.5 6.6zM12 15c1.8-3.8 5-6 9.5-6.6c-.6 4-4.2 6.6-9.5 6.6z',
    'M5 20.5c4-2 9.5-2.6 14.5-2',
    '',
    '',
  ),
  'bhakti': IconArt(
    Color(0xFFC2410C),
    _peach,
    'Devotion',
    'M12 2.5c2.2 3 2.2 5.4 0 7.5c-2.2-2.1-2.2-4.5 0-7.5zM3.5 12.5h17c0 4.2-3.8 6.5-8.5 6.5s-8.5-2.3-8.5-6.5z',
    'M9 21.5h6',
    '',
    '',
  ),
  'diya': IconArt(
    Color(0xFFD9640F),
    Color(0xFFFFE08A),
    'Festival',
    'M12 2.5c2.2 3 2.2 5.4 0 7.5c-2.2-2.1-2.2-4.5 0-7.5zM3.5 12.5h17c0 4.2-3.8 6.5-8.5 6.5s-8.5-2.3-8.5-6.5z',
    'M9 21.5h6',
    '',
    '',
  ),
  'prem': IconArt(
    Color(0xFFB4235A),
    Color(0xFFFFC2D6),
    'Love',
    'M12 20.5s-7.5-4.6-7.5-10.4A4.3 4.3 0 0 1 12 7.4a4.3 4.3 0 0 1 7.5 2.7c0 5.8-7.5 10.4-7.5 10.4z',
    '',
    '',
    '',
  ),
  'prakruti': IconArt(
    Color(0xFF2F7D4F),
    Color(0xFFC8F2A6),
    'Nature',
    'M4.5 19.5C4.5 11 10.5 4.5 19.5 4.5c0 9-6.5 15-15 15z',
    '',
    '',
    'M6.5 17.5l8-8',
  ),
  'desh': IconArt(Color(0xFFEA580C), _white, 'Nation', 'M6.5 4h11.5l-2.5 4 2.5 4H6.5z', 'M6 21.5V3.5', '', ''),
  'jivan': IconArt(
    Color(0xFFCA8A04),
    Color(0xFFFFF1A8),
    'Life',
    'M12 7.5a4.5 4.5 0 1 0 0 9a4.5 4.5 0 1 0 0-9z',
    'M12 2v1.8M12 20.2V22M2 12h1.8M20.2 12H22M4.9 4.9l1.3 1.3M17.8 17.8l1.3 1.3M4.9 19.1l1.3-1.3M17.8 6.2l1.3-1.3',
    '',
    '',
  ),
  'parivar': IconArt(
    Color(0xFF5B47A8),
    Color(0xFFD9CFFF),
    'Family',
    'M8 4.5a3 3 0 1 0 0 6a3 3 0 1 0 0-6zM16.5 6a2.5 2.5 0 1 0 0 5a2.5 2.5 0 1 0 0-5zM2.5 20.5c0-3.5 2.5-6 5.5-6s5.5 2.5 5.5 6zM12.5 20.5c0-2.8 1.8-4.8 4-4.8s4 2 4 4.8z',
    '',
    '',
    '',
  ),
  'ghazal': IconArt(
    Color(0xFF25407F),
    Color(0xFFFFD58A),
    'Ghazal',
    'M19.5 14.5A8 8 0 1 1 9.5 4.5a6.3 6.3 0 0 0 10 10zM18 2.5l.7 1.6 1.7.2-1.3 1.1.4 1.7-1.5-.9-1.5.9.4-1.7-1.3-1.1 1.7-.2z',
    '',
    '',
    '',
  ),
  'bhajan': IconArt(
    Color(0xFF8A2B6E),
    Color(0xFFFFC9EE),
    'Bhajan',
    'M6 15.2a3 3 0 1 0 0 6a3 3 0 1 0 0-6zM17 13.2a3 3 0 1 0 0 6a3 3 0 1 0 0-6zM9 5.5l11-2v3l-11 2z',
    'M9 18V6M20 16V4',
    '',
    '',
  ),
  'hasya': IconArt(
    Color(0xFFD97706),
    Color(0xFFFFE7A3),
    'Humour',
    'M12 3a9 9 0 1 0 0 18a9 9 0 1 0 0-18z',
    '',
    'M8.8 8.6a1.2 1.2 0 1 0 0 2.4a1.2 1.2 0 1 0 0-2.4zM15.2 8.6a1.2 1.2 0 1 0 0 2.4a1.2 1.2 0 1 0 0-2.4z',
    'M8 14c1 1.5 2.5 2.2 4 2.2s3-.7 4-2.2',
  ),
  'other': IconArt(
    Color(0xFF4F6664),
    Color(0xFFD6ECE9),
    'Other',
    'M5 4.5h14a1.5 1.5 0 0 1 0 3H5a1.5 1.5 0 0 1 0-3zM5 10.5h14a1.5 1.5 0 0 1 0 3H5a1.5 1.5 0 0 1 0-3zM5 16.5h8a1.5 1.5 0 0 1 0 3H5a1.5 1.5 0 0 1 0-3z',
    '',
    '',
    '',
  ),
  'settings': IconArt(
    Color(0xFF3D5A80),
    Color(0xFFD7E6FF),
    'Settings',
    'M12 5.6a6.4 6.4 0 1 0 0 12.8a6.4 6.4 0 1 0 0-12.8z',
    'M12 2.8v2M12 19.2v2M2.8 12h2M19.2 12h2M5.5 5.5l1.4 1.4M17.1 17.1l1.4 1.4M5.5 18.5l1.4-1.4M17.1 6.9l1.4-1.4',
    'M12 9.5a2.5 2.5 0 1 0 0 5a2.5 2.5 0 1 0 0-5z',
    '',
  ),
  'search': IconArt(
    _peacock,
    Color(0xFFCFE4FF),
    'Search',
    'M10.5 6a4.5 4.5 0 1 0 0 9a4.5 4.5 0 1 0 0-9z',
    'M10.5 3.5a7 7 0 1 0 0 14a7 7 0 1 0 0-14zM16 16l4.5 4.5',
    '',
    '',
  ),
  'home': IconArt(_teal, _peach, 'Home', 'M12 3.2l9 7.3v10.3H15v-6.3H9v6.3H3V10.5z', '', '', ''),
  'write': IconArt(
    Color(0xFFB9520A),
    Color(0xFFFFE2C2),
    'Write',
    'M20.5 3.5C13 3.5 7 9 5.5 16.5c7.5-1 14-6.5 15-13z',
    'M5.5 16.5L3.5 20.5',
    '',
    'M8.5 13.5l6.5-5.5',
  ),
  'collection': IconArt(
    _teal,
    _aqua,
    'Collection',
    'M3.5 4h4.5v16.5H3.5zM9.5 4H14v16.5H9.5zM15.3 5.2l3.6-.9 3.4 15.6-3.6.9z',
    '',
    '',
    'M3.5 8h4.5M9.5 8H14',
  ),
  'calendar': IconArt(
    _peacock,
    _white,
    'Calendar',
    'M5 5h14a1.5 1.5 0 0 1 1.5 1.5v12.5a1.5 1.5 0 0 1-1.5 1.5H5a1.5 1.5 0 0 1-1.5-1.5V6.5A1.5 1.5 0 0 1 5 5z',
    'M8 3v3.5M16 3v3.5',
    'M7 12h2.5v2.5H7zM10.75 12h2.5v2.5h-2.5zM14.5 12H17v2.5h-2.5zM7 15.8h2.5v2.5H7z',
    'M3.8 9.5h16.4',
  ),
  'mic': IconArt(
    Color(0xFFB9520A),
    Color(0xFFFFE2C2),
    'Voice typing',
    'M12 2.5a3.5 3.5 0 0 0-3.5 3.5v6a3.5 3.5 0 0 0 7 0V6A3.5 3.5 0 0 0 12 2.5z',
    'M5.5 11.5a6.5 6.5 0 0 0 13 0M12 18.5v3',
    '',
    '',
  ),
  'share': IconArt(Color(0xFF1F8A5B), Color(0xFFCFF7E3), 'Share', 'M4.5 13h3v5.5h9V13h3v8.5h-15z', 'M12 15V4M7.5 8.5L12 4l4.5 4.5', '', ''),
  'speaker': IconArt(_peacock, Color(0xFFCFE4FF), 'Read aloud', 'M3.5 9v6h4l5 4V5l-5 4z', 'M16 9a4 4 0 0 1 0 6M18.6 6.4a8 8 0 0 1 0 11.2', '', ''),
  'star': IconArt(
    Color(0xFFD97706),
    Color(0xFFFFE7A3),
    'Favourite',
    'M12 2.8l2.8 5.9 6.4.8-4.7 4.4 1.2 6.4L12 17.2l-5.7 3.1 1.2-6.4-4.7-4.4 6.4-.8z',
    '',
    '',
    '',
  ),
  'lock': IconArt(
    _teal,
    _peach,
    'PIN lock',
    'M6 10.5h12a1 1 0 0 1 1 1v8a1 1 0 0 1-1 1H6a1 1 0 0 1-1-1v-8a1 1 0 0 1 1-1z',
    'M8.5 10.5V7.5a3.5 3.5 0 0 1 7 0v3',
    'M12 13.5a1.5 1.5 0 1 0 0 3a1.5 1.5 0 1 0 0-3z',
    '',
  ),
  'fingerprint': IconArt(
    Color(0xFF1F8A5B),
    Color(0xFFCFF7E3),
    'Fingerprint',
    '',
    'M6.5 6.5A8 8 0 0 1 20 12v1M4 12a8 8 0 0 1 .7-3.3M8 20.5A12 12 0 0 1 6 12a6 6 0 0 1 12 0v1.5M12 21c-1.5-2.5-2-5.5-2-9a2 2 0 0 1 4 0c0 3 .6 5.5 2 8',
    '',
    '',
  ),
  'key': IconArt(
    Color(0xFFCA8A04),
    Color(0xFFFFF1A8),
    'Recovery key',
    'M8 6a4.5 4.5 0 1 0 0 9a4.5 4.5 0 1 0 0-9z',
    'M11.5 12.5l8.5 8.5M17.2 18.2l2-2M14.6 15.6l2-2',
    'M8 9a1.5 1.5 0 1 0 0 3a1.5 1.5 0 1 0 0-3z',
    '',
  ),
  'mail': IconArt(
    Color(0xFFB4235A),
    Color(0xFFFFD6E4),
    'Email',
    'M4.5 5.5h15a1.5 1.5 0 0 1 1.5 1.5v10a1.5 1.5 0 0 1-1.5 1.5h-15A1.5 1.5 0 0 1 3 17V7a1.5 1.5 0 0 1 1.5-1.5z',
    '',
    '',
    'M3.8 6.6l8.2 6.4 8.2-6.4',
  ),
  'cloud': IconArt(_peacock, _white, 'Google Drive', 'M7 19h10.5a4.5 4.5 0 0 0 .6-9A6.5 6.5 0 0 0 5.6 9.2A5 5 0 0 0 7 19z', '', '', ''),
  'download': IconArt(
    Color(0xFFD9640F),
    Color(0xFFFFE2C2),
    'Import',
    'M4 18h16a1.2 1.2 0 0 1 0 3H4a1.2 1.2 0 0 1 0-3z',
    'M12 3.5v10M7.5 9.5L12 14l4.5-4.5',
    '',
    '',
  ),
  'location': IconArt(
    Color(0xFF1F8A5B),
    Color(0xFFCFF7E3),
    'Location',
    'M12 21.5s-6.5-6-6.5-11.5a6.5 6.5 0 0 1 13 0c0 5.5-6.5 11.5-6.5 11.5z',
    '',
    'M12 7.5a2.5 2.5 0 1 0 0 5a2.5 2.5 0 1 0 0-5z',
    '',
  ),
  'bell': IconArt(Color(0xFF8A2B6E), Color(0xFFFFC9EE), 'Reminders', 'M6 16.5V11a6 6 0 0 1 12 0v5.5l2 2H4zM10 20h4a2 2 0 0 1-4 0z', '', '', ''),
  'help': IconArt(
    _teal,
    _peach,
    'Help',
    'M12 3a9 9 0 1 0 0 18a9 9 0 1 0 0-18z',
    '',
    'M12 16.2a1.2 1.2 0 1 0 0 2.4a1.2 1.2 0 1 0 0-2.4z',
    'M9.5 9.5a2.5 2.5 0 1 1 3.5 2.3c-.6.3-1 .8-1 1.5V14',
  ),
  'theme': IconArt(
    Color(0xFFD9640F),
    _white,
    'Theme',
    'M12 3a9 9 0 1 0 0 18c1.1 0 1.6-.8 1.6-1.6c0-1.3-1.1-1.6-1.1-2.7s.9-1.6 2.1-1.6H17a4 4 0 0 0 4-4C21 6.8 17 3 12 3z',
    '',
    'M7.5 10a1.3 1.3 0 1 0 0 2.6a1.3 1.3 0 1 0 0-2.6zM10.5 6.2a1.3 1.3 0 1 0 0 2.6a1.3 1.3 0 1 0 0-2.6zM15 6.5a1.3 1.3 0 1 0 0 2.6a1.3 1.3 0 1 0 0-2.6z',
    '',
  ),
  'language': IconArt(
    Color(0xFF25407F),
    Color(0xFFD7E6FF),
    'Language',
    'M4.5 4.5h10a2 2 0 0 1 2 2v6a2 2 0 0 1-2 2H9.5l-4 3.5v-3.5h-1a2 2 0 0 1-2-2v-6a2 2 0 0 1 2-2z',
    '',
    '',
    'M6.5 8.5h6M6.5 11.5h4',
  ),
  'fontsize': IconArt(Color(0xFF4F6664), Color(0xFFD6ECE9), 'Text size', '', 'M3.5 19.5L8.5 5l5 14.5M5.5 14.5h6M15 19.5l3-8 3 8M16 16.5h4', '', ''),
  'photo': IconArt(
    Color(0xFF8A2B6E),
    Color(0xFFFFC9EE),
    'Photo',
    'M4.5 5h15a1.5 1.5 0 0 1 1.5 1.5v11a1.5 1.5 0 0 1-1.5 1.5h-15A1.5 1.5 0 0 1 3 17.5v-11A1.5 1.5 0 0 1 4.5 5z',
    '',
    'M4.5 17l4.5-5 3.5 3.5 3-3 4 4.5zM16 8a1.6 1.6 0 1 0 0 3.2a1.6 1.6 0 1 0 0-3.2z',
    '',
  ),
  'shield': IconArt(
    Color(0xFF1F8A5B),
    Color(0xFFCFF7E3),
    'Backup',
    'M12 2.8l8 3v6.2c0 4.6-3.4 8.2-8 9.2c-4.6-1-8-4.6-8-9.2V5.8z',
    '',
    '',
    'M8.5 12l2.5 2.5 4.5-5',
  ),
  'trash': IconArt(
    Color(0xFF9B2C2C),
    Color(0xFFFFD2D2),
    'Recycle bin',
    'M6 8h12l-1 12.5H7zM4.5 5h15a1.2 1.2 0 0 1 0 2.5h-15a1.2 1.2 0 0 1 0-2.5z',
    '',
    '',
    'M10 11v6.5M14 11v6.5',
  ),
  'undo': IconArt(_teal, _aqua, 'Undo', '', 'M9 14L4 9l5-5M4 9h10a6 6 0 0 1 0 12h-3', '', ''),
  'edit': IconArt(Color(0xFFB9520A), Color(0xFFFFE2C2), 'Edit', 'M4 20l1-4.5L16 4.5l3.5 3.5L8.5 19z', '', '', 'M14 7l3 3'),
  'check': IconArt(_teal, _peach, 'Save', '', 'M5 12.5l4.5 4.5L19.5 7', '', ''),
  // Collection icons: two-tone (dominant tile colour + lighter highlight).
  'samaj': IconArt(
    Color(0xFF9A3412),
    Color(0xFFFFD7B5),
    'Society',
    'M6 5.6a2.3 2.3 0 1 0 0 4.6a2.3 2.3 0 1 0 0-4.6zM18 5.6a2.3 2.3 0 1 0 0 4.6a2.3 2.3 0 1 0 0-4.6zM12 3.4a2.7 2.7 0 1 0 0 5.4a2.7 2.7 0 1 0 0-5.4zM1.8 20.5c0-3 1.9-5.2 4.2-5.2c1.2 0 2.2.5 3 1.4zM22.2 20.5c0-3-1.9-5.2-4.2-5.2c-1.2 0-2.2.5-3 1.4zM6.8 20.5c0-3.8 2.3-6.4 5.2-6.4s5.2 2.6 5.2 6.4z',
    '',
    '',
    '',
  ),
  'sunrise': IconArt(
    Color(0xFFC2410C),
    Color(0xFFFFE08A),
    'Morning flowers',
    'M5 16a7 7 0 0 1 14 0z',
    'M12 3.5v2.5M4.6 7.6l1.7 1.7M19.4 7.6l-1.7 1.7M2.5 16H4M20 16h1.5M3 19.5h18',
    '',
    '',
  ),
  'mountain': IconArt(
    Color(0xFF475569),
    Color(0xFFE2E8F0),
    'Struggle',
    'M2 20.5L9 7.5l4 6 2.5-3.5L22 20.5z',
    'M15.5 9.5V3.5l3.2 1.3-3.2 1.3',
    '',
    'M7 11.2l2 1.3 2-1.6',
  ),
  'wave': IconArt(
    Color(0xFF1D4ED8),
    Color(0xFFBFDBFE),
    'Ocean of devotion',
    '',
    'M2 8.5c2.5-2 4.5-2 7 0s4.5 2 7 0 4.5-2 6 0M2 13.5c2.5-2 4.5-2 7 0s4.5 2 7 0 4.5-2 6 0M2 18.5c2.5-2 4.5-2 7 0s4.5 2 7 0 4.5-2 6 0',
    '',
    '',
  ),
  'flame': IconArt(
    Color(0xFFB91C1C),
    Color(0xFFFFD36E),
    'Light of love',
    'M12 2.5c3.5 4 6 6.6 6 10.5a6 6 0 0 1-12 0c0-2.6 1.4-4.4 3-6c.3 2 1.1 3 2.3 3.6C10.6 7.6 11 5 12 2.5z',
    '',
    'M12 13.5c1.4 1.4 2.2 2.4 2.2 3.6a2.2 2.2 0 0 1-4.4 0c0-1.2.8-2.2 2.2-3.6z',
    '',
  ),
  'hourglass': IconArt(
    Color(0xFF7C3AED),
    Color(0xFFE9D5FF),
    'Memories',
    'M6 3h12v2.5c0 3-2.6 4.8-4.5 6.5c1.9 1.7 4.5 3.5 4.5 6.5V21H6v-2.5c0-3 2.6-4.8 4.5-6.5C8.6 10.3 6 8.5 6 5.5z',
    '',
    'M9 19.5h6c-.6-1.6-1.8-2.6-3-3.4c-1.2.8-2.4 1.8-3 3.4zM9.5 7h5c-.6 1-1.5 1.8-2.5 2.5C11 8.8 10.1 8 9.5 7z',
    '',
  ),
  'gift': IconArt(
    Color(0xFFBE185D),
    Color(0xFFFFE4F1),
    'Good wishes',
    'M4 11h16v9.5H4zM3 7.5h18V11H3z',
    'M12 7.5C10 4 6.5 4.5 7.5 6.5S12 7.5 12 7.5zM12 7.5c2-3.5 5.5-3 4.5-1S12 7.5 12 7.5z',
    '',
    'M12 7.5v13',
  ),
  'tree': IconArt(
    Color(0xFF166534),
    Color(0xFFBBF7D0),
    'With nature',
    'M12 2.5a6 6 0 0 1 5.6 8.1A4.5 4.5 0 0 1 15 18.5H9a4.5 4.5 0 0 1-2.6-7.9A6 6 0 0 1 12 2.5z',
    '',
    '',
    'M12 11v10.5M12 15.5l-2.5-2M12 14l2.5-2',
  ),
  'swirl': IconArt(
    Color(0xFF0E7490),
    Color(0xFFA5F3FC),
    'Churning of life',
    '',
    'M12 12a1.5 1.5 0 1 1 1.5 1.5a4 4 0 1 1-4-4a6.5 6.5 0 1 1-6.5 6.5',
    '',
    '',
  ),
  'spark': IconArt(
    Color(0xFFA16207),
    Color(0xFFFEF08A),
    'Inspiration',
    'M12 2.5l1.9 5.6 5.6 1.9-5.6 1.9L12 17.5l-1.9-5.6L4.5 10l5.6-1.9z',
    'M18.5 16.5v4M16.5 18.5h4',
    '',
    '',
  ),
  'restore': IconArt(Color(0xFF1F8A5B), Color(0xFFCFF7E3), 'Restore', '', 'M15 10l5-5-5-5M20 5H10a6 6 0 0 0 0 12h3', '', ''),
};

/// A raised, embossed symbol on a subtly recessed tile, in two tones of the
/// active theme (or the explicit [base]/[glyph]). The tile carries a soft neon
/// glow that breathes slowly. When pressed, a darker neon line traces the
/// symbol's own contour and fades. The trace listens to the pointer without
/// taking part in gestures, so taps reach the surrounding button exactly as
/// before. With reduced motion the glow is still and the trace shows only
/// while the finger is down.
class Icon3D extends StatefulWidget {
  const Icon3D(this.icon, {super.key, this.size = 48, this.well = false, this.base, this.glyph, this.semanticLabel, this.primary});

  final String icon;
  final double size;

  /// A deeper, more visible recess (the tile always sits in a subtle one).
  final bool well;
  final Color? base, glyph;
  final String? semanticLabel;

  /// A stronger glow for the main symbol of a screen or the selected tab.
  /// Defaults to true for large symbols.
  final bool? primary;

  @override
  State<Icon3D> createState() => _Icon3DState();
}

class _Icon3DState extends State<Icon3D> with SingleTickerProviderStateMixin {
  AnimationController? _trace;
  bool _held = false;

  AnimationController _controller(Duration d) => _trace ??= AnimationController(vsync: this, duration: d);

  @override
  void dispose() {
    _trace?.dispose();
    super.dispose();
  }

  void _down(PointerDownEvent _) {
    if (context.reduceMotion) {
      setState(() => _held = true);
      return;
    }
    final fresh = _trace == null;
    final c = _controller(context.neon.traceDuration);
    // A new controller must reach the painter before it can repaint it.
    if (fresh) setState(() {});
    c.forward(from: 0);
  }

  void _up(PointerEvent _) {
    if (_held) setState(() => _held = false);
  }

  @override
  Widget build(BuildContext context) {
    final art = iconArt[widget.icon] ?? iconArt['lotus']!;
    final theme = Theme.of(context).extension<GsvColors>();
    final tokens = context.neon;
    final base = widget.base ?? theme?.accentDeep ?? art.base;
    final glyph = widget.glyph ?? theme?.accentLight ?? art.glyph;
    final recess = theme?.bg ?? const Color(0xFFE4ECEA);
    final glow = theme?.glow ?? art.base;
    final traceColor = Color.lerp(glow, const Color(0xFF17121E), 0.23)!;
    final still = context.reduceMotion;
    final trace = _trace;
    final pulse = still || theme == null ? null : NeonClock.instance;
    return Semantics(
      label: widget.semanticLabel,
      excludeSemantics: widget.semanticLabel == null,
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: _down,
        onPointerUp: _up,
        onPointerCancel: _up,
        child: RepaintBoundary(
          child: CustomPaint(
            size: Size.square(widget.size),
            painter: _Icon3DPainter(
              art,
              deepWell: widget.well,
              base: base,
              glyph: glyph,
              recess: recess,
              dark: theme?.isDark ?? false,
              glow: theme == null ? null : glow,
              primary: widget.primary ?? widget.size >= 52,
              intensity: tokens.glowIntensity,
              pulse: pulse,
              pulseCycle: tokens.iconPulse,
              traceColor: traceColor,
              progress: trace,
              held: _held,
            ),
          ),
        ),
      ),
    );
  }
}

final _pathCache = <String, Path>{};
Path _p(String d) => _pathCache.putIfAbsent(d, () => d.isEmpty ? Path() : parseSvgPathData(d));

Color _mix(Color a, Color b, double t) => Color.lerp(a, b, t)!;

/// Part of [paths] from the start up to [fraction] of their total length.
Path contourUpTo(List<Path> paths, double fraction) {
  final out = Path();
  final metrics = [for (final p in paths) ...p.computeMetrics()];
  final total = metrics.fold<double>(0, (s, m) => s + m.length);
  var left = total * fraction.clamp(0, 1);
  for (final m in metrics) {
    if (left <= 0) break;
    out.addPath(m.extractPath(0, left < m.length ? left : m.length), Offset.zero);
    left -= m.length;
  }
  return out;
}

class _Icon3DPainter extends CustomPainter {
  _Icon3DPainter(
    this.art, {
    required this.deepWell,
    required this.base,
    required this.glyph,
    required this.recess,
    required this.dark,
    required this.glow,
    required this.primary,
    required this.intensity,
    required this.pulse,
    required this.pulseCycle,
    required this.traceColor,
    required this.progress,
    required this.held,
  }) : super(repaint: Listenable.merge([?pulse, ?progress]));

  final IconArt art;
  final bool deepWell, dark, held, primary;
  final Color base, glyph, recess, traceColor;
  final Color? glow;
  final double intensity;
  final NeonClock? pulse;
  final Duration pulseCycle;
  final Animation<double>? progress;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / 64; // pixels per tile unit
    canvas.save();
    canvas.scale(unit);
    const black = Color(0xFF000000), white = Color(0xFFFFFFFF);
    final shadow = _mix(base, black, 0.7);

    // Recessed tile bed: darker at the top edge, lighter at the bottom (light from above).
    const wellRect = Rect.fromLTWH(1, 1, 62, 62);
    final top = dark ? _mix(recess, black, deepWell ? 0.45 : 0.3) : _mix(recess, black, deepWell ? 0.14 : 0.08);
    final bottom = dark ? _mix(recess, white, deepWell ? 0.08 : 0.05) : _mix(recess, white, deepWell ? 0.6 : 0.45);
    canvas.drawRRect(
      RRect.fromRectAndRadius(wellRect, const Radius.circular(19)),
      Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [top, bottom]).createShader(wellRect),
    );

    const tileRect = Rect.fromLTWH(7, 6, 50, 50);
    final tile = RRect.fromRectAndRadius(tileRect, const Radius.circular(15.5));

    // Neon glow around the tile, breathing with the shared clock.
    final g = glow;
    if (g != null) {
      final b = pulse == null ? 0.4 : breath(pulse!.phase(pulseCycle));
      final px = primary ? 3 + 4 * b : 1.4 + 2.8 * b; // glow radius in pixels
      final a = (primary ? 0.95 : 0.8) * intensity;
      canvas.drawRRect(
        tile,
        Paint()
          ..color = g.withValues(alpha: a)
          ..maskFilter = MaskFilter.blur(BlurStyle.outer, px / unit * 1.2),
      );
      canvas.drawRRect(
        tile.inflate(0.4 / unit),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.9 / unit
          ..color = g.withValues(alpha: (0.35 + 0.4 * b) * intensity),
      );
    }

    canvas.drawRRect(
      tile.shift(const Offset(0, 3.2)),
      Paint()
        ..color = shadow.withValues(alpha: 0.38)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.6),
    );
    canvas.drawRRect(tile.shift(const Offset(0, 2.5)), Paint()..color = _mix(base, black, 0.42));
    // Smooth matte face.
    canvas.drawRRect(
      tile,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: const Alignment(-0.3, 1),
          colors: [_mix(base, white, 0.22), base, _mix(base, black, 0.2)],
          stops: const [0, 0.55, 1],
        ).createShader(tileRect),
    );
    // Restrained glass highlight.
    canvas.drawRRect(
      tile,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.4, -0.76),
          radius: 0.6,
          colors: [Color(0x66FFFFFF), Color(0x00FFFFFF)],
        ).createShader(tileRect),
    );

    canvas.translate(14, 13);
    canvas.scale(1.5);
    final k = unit * 1.5; // pixels per glyph unit
    final f = _p(art.f), s = _p(art.s), h = _p(art.h), c = _p(art.c);
    final extr = _mix(base, black, 0.5), carve = _mix(base, black, 0.3);
    Paint stroke(double w) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Raised symbol: extruded underside, contact shadow, then the face.
    canvas.save();
    canvas.translate(0, 0.85);
    canvas.drawPath(f, Paint()..color = extr);
    canvas.drawPath(s, stroke(2.7)..color = extr);
    canvas.restore();
    final sh = Paint()
      ..color = shadow.withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.55);
    canvas.save();
    canvas.translate(0.25, 0.9);
    canvas.drawPath(f, sh);
    canvas.drawPath(
      s,
      stroke(2.7)
        ..color = sh.color
        ..maskFilter = sh.maskFilter,
    );
    canvas.restore();

    final glyphShader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [_mix(glyph, white, 0.5), glyph, _mix(glyph, black, 0.12)],
      stops: const [0, 0.55, 1],
    ).createShader(const Rect.fromLTRB(4, 1, 12, 23));
    canvas.drawPath(f, Paint()..shader = glyphShader);
    canvas.drawPath(s, stroke(2.7)..shader = glyphShader);
    canvas.drawPath(h, Paint()..color = carve);
    canvas.drawPath(c, stroke(1.5)..color = carve);

    final gloss = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0x99FFFFFF), Color(0x00FFFFFF)],
    ).createShader(const Rect.fromLTRB(0, 2, 24, 13));
    canvas.drawPath(f, Paint()..shader = gloss);
    canvas.save();
    canvas.translate(-0.35, -0.45);
    canvas.drawPath(s, stroke(1.1)..shader = gloss);
    canvas.restore();

    // Press feedback: a darker neon line follows the symbol's contour, then fades.
    final t = progress?.value ?? 0;
    if (held || (t > 0 && t < 1)) {
      final opacity = held ? 1.0 : (t < 0.16 ? t / 0.16 : (t < 0.64 ? 1.0 : 1 - (t - 0.64) / 0.36));
      final drawn = held ? 1.0 : Curves.easeOut.transform((t / 0.64).clamp(0.0, 1.0));
      final bloom = held ? 3.0 : (t < 0.64 ? 1 + 4 * (t / 0.64) : 5 - 3 * ((t - 0.64) / 0.36));
      final contour = contourUpTo([f, s, c], drawn);
      final core = (size.width * 0.05).clamp(1.6, 3.2) / k;
      canvas.drawPath(
        contour,
        stroke(core * 2.4)
          ..color = (glow ?? traceColor).withValues(alpha: 0.75 * opacity)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, bloom / k),
      );
      canvas.drawPath(contour, stroke(core)..color = traceColor.withValues(alpha: opacity));
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_Icon3DPainter old) =>
      old.art != art ||
      old.deepWell != deepWell ||
      old.base != base ||
      old.glyph != glyph ||
      old.recess != recess ||
      old.glow != glow ||
      old.primary != primary ||
      old.held != held ||
      old.pulse != pulse ||
      old.progress != progress;
}
