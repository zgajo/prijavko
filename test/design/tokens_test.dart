// Story 1.2 AC6.3 — guards `lib/design/tokens.dart` against drift.
// Pure Dart test — no Flutter binding required.

import 'package:flutter_test/flutter_test.dart';
import 'package:prijavko/design/tokens.dart';

void main() {
  group('TokensSpace — 4dp base grid', () {
    test('every value in TokensSpace.values is a non-zero multiple of 4', () {
      // guards AC1.1 — invariant iterates the canonical TokensSpace.values
      // list, NOT a hardcoded copy of the literals. Adding e.g.
      // `s10 = 10.0` to the values list would fail this immediately.
      expect(TokensSpace.values, isNotEmpty, reason: 'values list is empty');
      for (final v in TokensSpace.values) {
        // guards AC1.1 — 4dp grid invariant per UX spec §Spacing.
        expect(v % 4, 0.0, reason: 'space $v breaks the 4dp grid');
        // guards AC1.1 — 0.0 is technically a multiple of 4 but not a
        // useful spacing token; reject explicitly.
        expect(v, greaterThan(0.0), reason: 'space $v must be positive');
      }
    });

    test('TokensSpace.values is sorted ascending and unique', () {
      // guards AC1.1 — Kaizen: a duplicate or out-of-order value indicates
      // a careless edit; fail loud rather than ship a confusing token list.
      final sorted = <double>[...TokensSpace.values]..sort();
      expect(TokensSpace.values, equals(sorted), reason: 'not ascending');
      expect(
        TokensSpace.values.toSet().length,
        TokensSpace.values.length,
        reason: 'duplicate spacing value detected',
      );
    });

    test('expected canonical tokens are present', () {
      // guards AC1.1 — explicit check that the well-known step values
      // (s4 / s8 / s12 / s16 / s24 / s32 / s48 / s64) are in the list.
      // A separate test from the invariant so a missing step is
      // distinguishable from a non-multiple-of-4 regression.
      expect(TokensSpace.values, contains(TokensSpace.s4));
      expect(TokensSpace.values, contains(TokensSpace.s8));
      expect(TokensSpace.values, contains(TokensSpace.s12));
      expect(TokensSpace.values, contains(TokensSpace.s16));
      expect(TokensSpace.values, contains(TokensSpace.s24));
      expect(TokensSpace.values, contains(TokensSpace.s32));
      expect(TokensSpace.values, contains(TokensSpace.s48));
      expect(TokensSpace.values, contains(TokensSpace.s64));
    });
  });

  group('TokensRadius — figma-code-contract §1', () {
    test('button=12, card=16, sheet=24', () {
      // guards AC1.1 — radii match the Figma contract.
      expect(TokensRadius.button, 12.0);
      expect(TokensRadius.card, 16.0);
      expect(TokensRadius.sheet, 24.0);
    });
  });

  group('TokensSize — one-handed ergonomics', () {
    test('buttonMinHeight is 56dp', () {
      // guards AC1.1 — 56dp button min-height (PRD NFR-C3).
      expect(TokensSize.buttonMinHeight, 56.0);
    });

    test('outlinedButtonMinHeight is 48dp', () {
      // guards AC2.5 — secondary buttons de-emphasise via 48dp height.
      expect(TokensSize.outlinedButtonMinHeight, 48.0);
    });
  });

  group('TokensColor — single brand seed', () {
    test('primarySeed is 0xFF0D4F52 (Adriatic Teal)', () {
      // guards AC1.1 — Adriatic Teal seed is the only brand `Color` in tokens.
      // ignore: deprecated_member_use
      expect(TokensColor.primarySeed.value, 0xFF0D4F52);
    });
  });
}
