// Story 1.2 AC6.3 — guards `lib/design/tokens.dart` against drift.
// Pure Dart test — no Flutter binding required.

import 'package:flutter_test/flutter_test.dart';
import 'package:prijavko/design/tokens.dart';

void main() {
  group('Tokens.space — 4dp base grid', () {
    // guards AC1.1 — every spacing token is a multiple of 4.
    test('every space token is a multiple of 4', () {
      const values = <double>[4.0, 8.0, 12.0, 16.0, 24.0, 32.0, 48.0, 64.0];
      for (final v in values) {
        expect(v % 4, 0.0, reason: 'space $v breaks the 4dp grid');
      }
      expect(Tokens.space.s4, 4.0);
      expect(Tokens.space.s8, 8.0);
      expect(Tokens.space.s12, 12.0);
      expect(Tokens.space.s16, 16.0);
      expect(Tokens.space.s24, 24.0);
      expect(Tokens.space.s32, 32.0);
      expect(Tokens.space.s48, 48.0);
      expect(Tokens.space.s64, 64.0);
    });
  });

  group('Tokens.radius — figma-code-contract §1', () {
    // guards AC1.1 — radii match the Figma contract.
    test('button=12, card=16, sheet=24', () {
      expect(Tokens.radius.button, 12.0);
      expect(Tokens.radius.card, 16.0);
      expect(Tokens.radius.sheet, 24.0);
    });
  });

  group('Tokens.size — one-handed ergonomics', () {
    // guards AC1.1 — 56dp button min-height (PRD NFR-C3).
    test('buttonMinHeight is 56dp', () {
      expect(Tokens.size.buttonMinHeight, 56.0);
    });
  });

  group('Tokens.color — single brand seed', () {
    // guards AC1.1 — Adriatic Teal seed is the only brand `Color` in tokens.
    test('primarySeed is 0xFF0D4F52 (Adriatic Teal)', () {
      // ignore: deprecated_member_use
      expect(Tokens.color.primarySeed.value, 0xFF0D4F52);
    });
  });
}
