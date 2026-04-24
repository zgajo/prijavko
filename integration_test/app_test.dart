// Story 1.1 AC3.4 + AC10 — boot probe & cold-start guard rail for
// integration_fake.yml.
//
// Why this uses `IntegrationTestWidgetsFlutterBinding` (and therefore
// requires an emulator/device): AC10 calls for
// `binding.firstFrameRasterized` as the cold-start marker. That flag
// only flips inside `RendererBinding` when a real `ui.View.render` call
// lands a frame on the GPU — the headless `AutomatedTestWidgetsFlutterBinding`
// never rasterizes, so the marker stays false there. Running against
// the `reactivecircus/android-emulator-runner@v2` AVD wired by
// `integration_fake.yml` (Task 3) is what makes the probe honest.
// Local `flutter test integration_test/` without an emulator will
// therefore fail with "No supported devices connected" — that is
// expected for integration tests and matches PRD Day-One integration
// posture.
//
// AC10 / NFR-P8 (cold-start p95 ≤ 2.5s) is covered by:
//   1. A single true cold-start sample gated on
//      `WidgetsBinding.instance.waitUntilFirstFrameRasterized` (fires
//      once per binding lifetime, which is exactly what cold start is).
//   2. N-1 subsequent pump-and-render samples, each measured against a
//      live `pump()` — on the integration binding `pump()` awaits a
//      real vsync, so the stopwatch spans build + layout + GPU paint.
// p50/p95 are computed across all samples (cold + warm) so trend
// review in CI logs has distribution, not just the headline number.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:prijavko/main.dart';

// Sample count + threshold are inlined rather than `--dart-define`d: a
// guard rail that can be silently loosened from CI arguments is not a
// guard rail. Changes must land as a code change + review.
const _sampleCount = 5;
const _coldStartThreshold = Duration(milliseconds: 2500);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app boots and paints its first frame', (tester) async {
    await tester.pumpWidget(const MainApp());
    await tester.pumpAndSettle();

    expect(find.text('Hello World!'), findsOneWidget);
  });

  testWidgets('cold-start stays under 2.5s across $_sampleCount samples '
      '(AC10 / NFR-P8)', (tester) async {
    final samples = <Duration>[];

    for (var i = 0; i < _sampleCount; i++) {
      // Tear the tree down between iterations so each measurement
      // covers a fresh MainApp mount, not a re-attach to an already-
      // built element tree.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      final stopwatch = Stopwatch()..start();
      await tester.pumpWidget(const MainApp());
      if (i == 0) {
        // `waitUntilFirstFrameRasterized` is a per-binding Completer —
        // it fires exactly once. On iteration 0 this delimits the real
        // cold start (AC10.1); from iteration 1 on, `pump()` already
        // blocks on a live vsync under the integration binding so it's
        // the canonical "frame done" signal.
        await WidgetsBinding.instance.waitUntilFirstFrameRasterized;
        expect(
          WidgetsBinding.instance.firstFrameRasterized,
          isTrue,
          reason: 'cold-start marker must be set after first render',
        );
      } else {
        await tester.pump();
      }
      stopwatch.stop();

      samples.add(stopwatch.elapsed);
    }

    final coldStart = samples.first;
    final sorted = [...samples]..sort();
    final p50 = sorted[(_sampleCount * 0.5).floor()];
    final p95 =
        sorted[((_sampleCount * 0.95).ceil() - 1).clamp(0, _sampleCount - 1)];
    final maxSample = sorted.last;

    // debugPrint so CI log parsers can trend p50/p95 over time without
    // re-running failing builds. No PII (pii_guard regex only matches
    // `.documentNumber|.firstName|…` accessors — pure numeric output).
    debugPrint(
      'cold-start probe: '
      'cold_start_ms=${coldStart.inMilliseconds} '
      'samples_ms=${samples.map((s) => s.inMilliseconds).toList()} '
      'p50_ms=${p50.inMilliseconds} '
      'p95_ms=${p95.inMilliseconds} '
      'max_ms=${maxSample.inMilliseconds} '
      'threshold_ms=${_coldStartThreshold.inMilliseconds}',
    );

    // Hard-fail against the cold-start sample: AC10.1 is a cold-start
    // budget, not a steady-state frame budget. The warm samples exist
    // only to surface distribution in the log; they don't change the
    // gate. We also fail if *any* sample exceeds the threshold so that
    // a single slow outlier can't hide behind a lower p50/p95.
    expect(
      coldStart <= _coldStartThreshold,
      isTrue,
      reason:
          'cold-start ${coldStart.inMilliseconds}ms exceeded '
          '${_coldStartThreshold.inMilliseconds}ms threshold',
    );
    expect(
      maxSample <= _coldStartThreshold,
      isTrue,
      reason:
          'slowest pump ${maxSample.inMilliseconds}ms exceeded '
          '${_coldStartThreshold.inMilliseconds}ms threshold '
          '(p50=${p50.inMilliseconds}ms, p95=${p95.inMilliseconds}ms)',
    );
  });
}
