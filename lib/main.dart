import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'core/theme/app_theme.dart';
import 'widgets/glass_nav_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lets audio keep playing with lock-screen/notification controls when
  // the app is backgrounded — essential for a media player.
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.bmplayer.audio.channel',
    androidNotificationChannelName: 'bmplayer playback',
    androidNotificationOngoing: true,
  );

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  runApp(const ProviderScope(child: BmPlayerApp()));
}

class BmPlayerApp extends StatelessWidget {
  const BmPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'bmplayer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      home: const GlassNavShell(),
    );
  }
}
