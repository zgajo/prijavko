// guards AC2.2, AC2.3, AC2.4
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prijavko/core/security/aes_gcm_helper.dart';

void main() {
  final key32 = Uint8List(32)..fillRange(0, 32, 0x42);
  final plaintext = Uint8List.fromList([1, 2, 3, 4, 5]);

  group('AesGcmHelper', () {
    test('constructor throws ArgumentError for key that is not 32 bytes', () {
      expect(() => AesGcmHelper(Uint8List(31)), throwsArgumentError);
      expect(() => AesGcmHelper(Uint8List(33)), throwsArgumentError);
      expect(() => AesGcmHelper(Uint8List(0)), throwsArgumentError);
    });

    test('encrypt → decrypt round-trip returns original plaintext', () async {
      final helper = AesGcmHelper(key32);
      final encrypted = await helper.encrypt(plaintext);
      final decrypted = await helper.decrypt(encrypted);
      expect(decrypted, plaintext);
    });

    test('encrypt → decrypt round-trip with empty plaintext', () async {
      final helper = AesGcmHelper(key32);
      final empty = Uint8List(0);
      final encrypted = await helper.encrypt(empty);
      // Output is nonce (12) + ciphertext (0) + mac (16) = 28 bytes.
      expect(encrypted.length, 28);
      final decrypted = await helper.decrypt(encrypted);
      expect(decrypted, empty);
    });

    test(
      'two encrypt calls on same plaintext produce different ciphertexts (random nonce)',
      () async {
        final helper = AesGcmHelper(key32);
        final c1 = await helper.encrypt(plaintext);
        final c2 = await helper.encrypt(plaintext);
        // Deterministic output would be a security bug (nonce reuse).
        expect(c1, isNot(equals(c2)));
      },
    );

    test(
      'decrypt of tampered ciphertext (flipped MAC byte) throws authentication error',
      () async {
        final helper = AesGcmHelper(key32);
        final encrypted = await helper.encrypt(plaintext);
        final tampered = Uint8List.fromList(encrypted);
        // Flip last byte (MAC area — last 16 bytes).
        tampered[tampered.length - 1] ^= 0xFF;
        expect(
          () => helper.decrypt(tampered),
          throwsA(isA<SecretBoxAuthenticationError>()),
        );
      },
    );

    test(
      'decrypt of tampered ciphertext (flipped nonce byte) throws authentication error',
      () async {
        final helper = AesGcmHelper(key32);
        final encrypted = await helper.encrypt(plaintext);
        final tampered = Uint8List.fromList(encrypted);
        // Flip first byte (nonce — first 12 bytes). AES-GCM authenticates
        // nonce || ciphertext || aad so this MUST fail MAC verification.
        tampered[0] ^= 0xFF;
        expect(
          () => helper.decrypt(tampered),
          throwsA(isA<SecretBoxAuthenticationError>()),
        );
      },
    );

    test(
      'decrypt of tampered ciphertext (flipped body byte) throws authentication error',
      () async {
        final helper = AesGcmHelper(key32);
        final encrypted = await helper.encrypt(plaintext);
        final tampered = Uint8List.fromList(encrypted);
        // Flip a byte in the ciphertext body (between offset 12 and length-16).
        const bodyOffset = 12;
        tampered[bodyOffset] ^= 0xFF;
        expect(
          () => helper.decrypt(tampered),
          throwsA(isA<SecretBoxAuthenticationError>()),
        );
      },
    );

    test(
      'decrypt rejects truncated input shorter than nonce+mac (28 bytes)',
      () async {
        final helper = AesGcmHelper(key32);
        // Empty.
        expect(() => helper.decrypt(Uint8List(0)), throwsArgumentError);
        // Only the nonce, no MAC.
        expect(() => helper.decrypt(Uint8List(12)), throwsArgumentError);
        // One byte short of the minimum.
        expect(() => helper.decrypt(Uint8List(27)), throwsArgumentError);
      },
    );
  });
}
