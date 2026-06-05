import 'dart:io';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
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
  // iOS: ATT 許可状態を確認してから AdMob を初期化する。
  // 未決定（初回）の場合は onboarding で requestTrackingAuthorization を呼ぶため
  // ここでは待たずに initialize だけ先行させる（非個人化広告として配信される）。
  if (Platform.isIOS) {
    final status =
        await AppTrackingTransparency.trackingAuthorizationStatus;
    debugLog('ATT status: $status');
  }
  await MobileAds.instance.initialize();
  debugLog('runApp PriceMateApp');
  runApp(const PriceMateApp());
}
