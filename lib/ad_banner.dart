// AdMob バナー広告の設定と共通ウィジェット。

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

// ─── 広告ユニット ID ──────────────────────────────────────────────────────────

class AdConfig {
  AdConfig._();

  // ★ AdMob コンソールで発行した本番広告ユニット ID
  static const String _androidBanner =
      'ca-app-pub-4185372678326421/3407753389'; // ← Android 用に差し替え
  static const String _iosBanner =
      'ca-app-pub-4185372678326421/7155426703'; // ← iOS 用に差し替え

  static String get bannerUnitId =>
      Platform.isIOS ? _iosBanner : _androidBanner;
}

// ─── バナー広告ウィジェット ───────────────────────────────────────────────────

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    final ad = BannerAd(
      adUnitId: AdConfig.bannerUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _ad = ad as BannerAd;
            _loaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint(
            'BannerAd failed: code=${error.code} '
            'domain=${error.domain} message=${error.message}',
          );
          ad.dispose();
        },
      ),
    );
    ad.load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _ad == null) {
      return const SizedBox(height: 50);
    }
    return SizedBox(
      width: double.infinity,
      height: _ad!.size.height.toDouble(),
      child: AdWidget(ad: _ad!),
    );
  }
}
