import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'app.dart';
import 'core/debug.dart';
import 'firebase_options.dart';

const _googleServerClientId =
    '734452752206-im65vqqdfoq4clcs0nf6uja0264jku1q.apps.googleusercontent.com';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    final sb = StringBuffer();
    sb.writeln('FlutterError: ${details.exceptionAsString()}');
    sb.writeln('schedulerPhase=${SchedulerBinding.instance.schedulerPhase}');
    if (details.informationCollector != null) {
      for (final info in details.informationCollector!()) {
        sb.writeln(info.toStringDeep());
      }
    }
    debugLog(sb.toString());
    debugPrintStack(stackTrace: details.stack);
    FlutterError.presentError(details);
  };
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await GoogleSignIn.instance.initialize(
    serverClientId: _googleServerClientId,
  );
  await MobileAds.instance.initialize();
  debugLog('runApp PriceMateApp');
  runApp(const PriceMateApp());
}
