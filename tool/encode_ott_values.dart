// ignore_for_file: avoid_print

import 'dart:typed_data';

// Keep this salt + algorithm byte-for-byte identical to
// lib/trailway/core/pebble_cipher.dart. Change both together.
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

List<int> fold(String value) {
  final bytes = Uint8List.fromList(value.codeUnits);
  final stream = _pebbleStream(bytes.length);
  return List<int>.generate(
    bytes.length,
    (index) => (bytes[index] + stream[index] + (index * 17 + 11)) & 0xff,
  );
}

String unfold(List<int> encoded) {
  final stream = _pebbleStream(encoded.length);
  return String.fromCharCodes(
    List<int>.generate(
      encoded.length,
      (index) => (encoded[index] - stream[index] - (index * 17 + 11)) & 0xff,
    ),
  );
}

void main() {
  const values = <String, String>{
    'endpoint': 'https://orbtumbletrail.com/config.php',
    'privacy': 'https://orbtumbletrail.com/privacy-policy.html',
    'support': 'https://orbtumbletrail.com/support.html',
    'gcd': 'https://gcdsdk.appsflyer.com/install_data/v5.0/',
    'webkit': '605.1.15',
    'safari': '18.6',
    'safariTail': '604.1',
    'appsFlyerKey': 'qQswUhPpbtxPjadp2vmzg3',
    'firebaseProjectNumber': '307154938045',
    'oneLinkHost': 'orbtumbletrail.onelink.me',
  };

  for (final entry in values.entries) {
    final encoded = fold(entry.value);
    print('${entry.key}: <int>[${encoded.join(', ')}]');
    if (unfold(encoded) != entry.value) {
      throw StateError('Round-trip failed for ${entry.key}');
    }
  }
  print('VERIFY: all values round-tripped');
}
