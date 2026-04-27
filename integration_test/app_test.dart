// Story 1.1 AC3.4 + AC10 — mount-to-first-frame guard rail for
// integration_fake.yml.
//
// Honest framing (per code-review decision D1, 2026-04-24): this probe is
// a *guard rail*, not a true cold-start metric. It measures the interval
// from `pumpWidget(MainApp)` to `waitUntilFirstFrameRasterized` inside an
// already-running Dart VM and integration-test binding — meaning the
// process, isolate, engine, and rasterizer are all warm by the time the
// Stopwatch starts. Real cold start (process launch → first frame) needs
// a `flutter drive` driver or a native-channel Activity.onCreate probe;
// that is deferred until a story actually requires the stronger signal.
//
// What this DOES catch: a regression that makes MainApp's first build
// exceed 2.5 s on the `reactivecircus/android-emulator-runner@v2` API 24
// AVD — e.g. a heavy synchronous init, a blocking provider, a secure-
// storage round-trip on the UI thread. That is the class of failure NFR-P8
// protects against at story-1.1 scope. When the app grows native init
// (Story 1.3+ keystore fetch, Dio bootstrap), the single-sample timing
// starts telling us something meaningful even without true cold start.
//
// Why `IntegrationTestWidgetsFlutterBinding` (and therefore an emulator):
// `firstFrameRasterized` only flips inside `RendererBinding` when a real
// `ui.View.render` call lands a frame on the GPU. The headless
// `AutomatedTestWidgetsFlutterBinding` never rasterizes, so the marker
// stays false there and the probe is unreachable without a device.
//
// Why a single sample, not N: with 5 samples, iteration 0 consumed the
// one-shot `waitUntilFirstFrameRasterized` Completer; iterations 1..4
// measured warm widget rebuilds on the same binding — producing a
// "p95" that was arithmetically identical to `max`, which is theatre,
// not signal. A single sample is honest. p50/p95 return when a driver-
// based cold-start harness lands.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:prijavko/main.dart';

// Threshold inlined rather than `--dart-define`d: a guard rail that can
// be silently loosened from CI arguments is not a guard rail. Changes
// must land as a code change + review.
const _firstFrameThreshold = Duration(milliseconds: 2500);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app boots and paints its first frame', (tester) async {
    await tester.pumpWidget(const MainApp());
    await tester.pumpAndSettle();

    // Story 1.2 swapped the `Hello World!` placeholder for the design-system
    // preview surface. The preview lands a FilledButton, an OutlinedButton,
    // and a Material Symbols Icon — if any token wiring is broken, this
    // probe goes red on the same emulator that protects the cold-start NFR.
    expect(find.byType(FilledButton), findsOneWidget);
    expect(find.byType(OutlinedButton), findsOneWidget);
    // The preview button labels are 'Preview'. Asserting on rendered text
    // (in addition to widget types) restores the strength of the original
    // `Hello World!` content probe — a font-load failure that swallows
    // glyphs but does not throw would still find the buttons but render
    // empty Text, and that path needs to fail loud.
    expect(find.text('Preview'), findsAtLeastNWidgets(1));
  });

  testWidgets('mount-to-first-frame stays under 2.5s (AC10 / NFR-P8 guard)', (
    tester,
  ) async {
    final stopwatch = Stopwatch()..start();
    await tester.pumpWidget(const MainApp());
    // `waitUntilFirstFrameRasterized` is a per-binding one-shot Completer.
    // On the integration binding, awaiting it blocks until a real vsync
    // lands the first GPU frame — which is the best proxy to "the app is
    // visible" we can honestly produce from inside a test harness.
    await WidgetsBinding.instance.waitUntilFirstFrameRasterized;
    stopwatch.stop();

    expect(
      WidgetsBinding.instance.firstFrameRasterized,
      isTrue,
      reason: 'first-frame marker must be set after initial render',
    );

    // debugPrint so CI log parsers can trend the number without re-running
    // failing builds. No PII (pii_guard regex matches `.firstName` etc. —
    // pure numeric output is safe).
    debugPrint(
      'first-frame probe: '
      'first_frame_ms=${stopwatch.elapsed.inMilliseconds} '
      'threshold_ms=${_firstFrameThreshold.inMilliseconds}',
    );

    expect(
      stopwatch.elapsed <= _firstFrameThreshold,
      isTrue,
      reason:
          'mount-to-first-frame ${stopwatch.elapsed.inMilliseconds}ms '
          'exceeded ${_firstFrameThreshold.inMilliseconds}ms threshold',
    );
  });
}
