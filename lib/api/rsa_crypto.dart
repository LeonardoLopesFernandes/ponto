import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

class RsaCrypto {
  static String? encryptWithPublicKey(String base64Key, String plainText) {
    try {
      final keyBytes = base64Decode(base64Key);
      final publicKey = _parseSubjectPublicKeyInfo(keyBytes);
      if (publicKey == null) return null;

      final cipher = PKCS1Encoding(RSAEngine());
      cipher.init(true, PublicKeyParameter<RSAPublicKey>(publicKey));
      final output = cipher.process(Uint8List.fromList(utf8.encode(plainText)));
      return base64Encode(output);
    } catch (_) {
      return null;
    }
  }

  static RSAPublicKey? _parseSubjectPublicKeyInfo(Uint8List der) {
    final reader = _DerReader(der);
    if (reader.readTag() != 0x30) return null; // SEQUENCE SPKI
    final spkiLength = reader.readLength();
    final end = reader.pos + spkiLength;

    final algSeq = reader.readTag();
    if (algSeq != 0x30) return null; // algorithm SEQUENCE
    reader.readLength();
    reader.skipContent();

    final bitString = reader.readTag();
    if (bitString != 0x03) return null; // BIT STRING
    final bitLength = reader.readLength();
    final bitEnd = reader.pos + bitLength;
    reader.skip(1); // unused-bits count

    final rsaSeq = reader.readTag();
    if (rsaSeq != 0x30) return null; // RSAPublicKey SEQUENCE
    reader.readLength();

    final modulus = reader.readInteger();
    final exponent = reader.readInteger();
    if (modulus == null || exponent == null) return null;

    if (reader.pos > end && bitEnd > end) return null;
    return RSAPublicKey(modulus, exponent);
  }
}

class _DerReader {
  final ByteData _data;
  int pos = 0;

  _DerReader(Uint8List bytes) : _data = ByteData.sublistView(bytes);

  int readTag() {
    if (pos >= _data.lengthInBytes) return -1;
    return _data.getUint8(pos++);
  }

  int readLength() {
    final first = _data.getUint8(pos++);
    if (first < 0x80) return first;
    final count = first & 0x7f;
    var length = 0;
    for (var i = 0; i < count; i++) {
      length = (length << 8) | _data.getUint8(pos++);
    }
    return length;
  }

  void skipContent() {
    pos = pos + readLength();
  }

  void skip(int count) {
    pos += count;
  }

  BigInt? readInteger() {
    final tag = readTag();
    if (tag != 0x02) return null; // INTEGER
    final length = readLength();
    final start = pos;
    pos += length;
    final bytes = _data.buffer.asUint8List(_data.offsetInBytes + start, length);
    var trimmed = bytes;
    if (trimmed.length > 1 && trimmed[0] == 0x00) {
      trimmed = trimmed.sublist(1);
    }
    return BigInt.parse(
      trimmed.map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
      radix: 16,
    );
  }
}