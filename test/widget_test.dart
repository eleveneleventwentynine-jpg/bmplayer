import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmplayer/core/theme/app_theme.dart';
import 'package:bmplayer/core/widgets/animated_waveform.dart';
import 'package:bmplayer/core/widgets/glass_container.dart';

// These tests intentionally exercise pure-UI widgets only, not the full
// BmPlayerApp. The app's real screens read from providers backed by
// platform plugins (on_audio_query, photo_manager, just_audio, ...) that
// have no implementation in the widget-test sandbox — pumping the full
// app here would fail on plugin channel errors that have nothing to do
// with whether the UI code itself is correct.

void main() {
  testWidgets('GlassContainer renders its child', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: const Scaffold(
          body: GlassContainer(
            child: Text('hello'),
          ),
        ),
      ),
    );

    expect(find.text('hello'), findsOneWidget);
  });

  testWidgets('AnimatedWaveform builds the expected number of bars',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AnimatedWaveform(isPlaying: true, barCount: 4),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(AnimatedContainer), findsNWidgets(4));
  });
}
