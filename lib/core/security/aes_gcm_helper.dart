import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

class AesGcmHelper {
  AesGcmHelper(Uint8List keyBytes)
    : _algorithm = AesGcm.with256bits(),
      _secretKey = SecretKeyData(keyBytes) {
    // Poka-yoke: prevents key truncation bugs — AES-256-GCM requires exactly 32 bytes.
    if (keyBytes.length != 32) {
      throw ArgumentError(
        'AES-256-GCM key must be exactly 32 bytes, got ${keyBytes.length}',
      );
    }
  }

  final AesGcm _algorithm;
  final SecretKeyData _secretKey;

  Future<Uint8List> encrypt(Uint8List plaintext) async {
    // WHY: A fresh random nonce per encrypt call is non-negotiable for AES-GCM
    // security — reusing a (key, nonce) pair leaks the key stream.
    final nonce = _algorithm.newNonce();
    final secretBox = await _algorithm.encrypt(
      plaintext,
      secretKey: _secretKey,
      nonce: nonce,
    );
    // Output format: [nonce (12 bytes)] ++ [ciphertext] ++ [mac (16 bytes)]
    // The 12-byte prefix lets decrypt locate the nonce without a side-channel.
    final result = Uint8List(
      nonce.length + secretBox.cipherText.length + secretBox.mac.bytes.length,
    );
    result.setRange(0, nonce.length, nonce);
    result.setRange(
      nonce.length,
      nonce.length + secretBox.cipherText.length,
      secretBox.cipherText,
    );
    result.setRange(
      nonce.length + secretBox.cipherText.length,
      result.length,
      secretBox.mac.bytes,
    );
    return result;
  }

  Future<Uint8List> decrypt(Uint8List ciphertext) async {
    const nonceLength = 12;
    const macLength = 16;
    final nonce = ciphertext.sublist(0, nonceLength);
    final mac = Mac(ciphertext.sublist(ciphertext.length - macLength));
    final encryptedBytes = ciphertext.sublist(
      nonceLength,
      ciphertext.length - macLength,
    );
    final secretBox = SecretBox(encryptedBytes, nonce: nonce, mac: mac);
    // Throws SecretBoxAuthenticationError on MAC mismatch — do not catch here;
    // callers handle the Err variant.
    final plaintext = await _algorithm.decrypt(
      secretBox,
      secretKey: _secretKey,
    );
    return Uint8List.fromList(plaintext);
  }
}
