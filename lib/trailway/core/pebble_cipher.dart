import 'dart:typed_data';

/// Position-keyed keystream cipher for Orb Tumble Trail's remote credentials.
///
/// The keystream is derived from [_trailSalt] via an FNV-1a fold seeding a
/// 32-bit linear-congruential generator (a deliberately different cipher
/// family from sibling projects, whose machine code must not match). Every
/// byte is additionally offset by a position term so identical plaintext
/// characters never encode to the same byte.
///
/// ⚠️ The salt below is unique to THIS app. Regenerate every encoded array
/// with `dart run tool/encode_ott_values.dart` after changing it, and confirm
/// the VERIFY block round-trips exactly.
const List<int> _trailSalt = <int>[
  0x30, 0x72, 0x62, 0x54, 0x75, 0x6D, 0x62, 0x31, 0x65, 0x5F, 0x39, 0x32,
];

int _foldSalt(List<int> seed) {
  var hash = 0x811c9dc5;
  for (final byte in seed) {
    hash = (hash ^ byte) & 0xffffffff;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return hash;
}

Uint8List _pebbleStream(int length) {
  var state = _foldSalt(_trailSalt);
  final result = Uint8List(length);
  for (var index = 0; index < length; index++) {
    state = (state * 1664525 + 1013904223) & 0xffffffff;
    result[index] = (state >> 23) & 0xff;
  }
  return result;
}

String unmaskPebbles(List<int> encoded) {
  if (encoded.isEmpty) return '';
  final stream = _pebbleStream(encoded.length);
  final plain = Uint8List(encoded.length);
  for (var index = 0; index < encoded.length; index++) {
    plain[index] = (encoded[index] - stream[index] - (index * 17 + 11)) & 0xff;
  }
  return String.fromCharCodes(plain);
}
