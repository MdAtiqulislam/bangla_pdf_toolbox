import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../constants/app_constants.dart';

class AdmobService extends GetxService {
  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdLoaded = false;
  bool _isInitialized = false;

  Future<AdmobService> init() async {
    try {
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        await MobileAds.instance.initialize();
        _isInitialized = true;
        _loadInterstitialAd();
      }
    } catch (e) {
      debugPrint('AdMob initialization error: $e');
    }
    return this;
  }

  bool get isInitialized => _isInitialized;

  String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return AppConstants.testBannerIdAndroid;
    } else if (Platform.isIOS) {
      return AppConstants.testBannerIdIOS;
    }
    return AppConstants.testBannerIdAndroid;
  }

  String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return AppConstants.testInterstitialIdAndroid;
    } else if (Platform.isIOS) {
      return AppConstants.testInterstitialIdIOS;
    }
    return AppConstants.testInterstitialIdAndroid;
  }

  void _loadInterstitialAd() {
    if (!_isInitialized) return;

    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdLoaded = true;
          debugPrint('AdMob Interstitial Ad Loaded successfully');
        },
        onAdFailedToLoad: (error) {
          _isInterstitialAdLoaded = false;
          _interstitialAd = null;
          debugPrint('AdMob Interstitial Ad Failed to Load: $error');
        },
      ),
    );
  }

  /// Show Interstitial Ad if available, then optionally invoke the callback
  void showInterstitialAd({VoidCallback? onComplete}) {
    if (_isInterstitialAdLoaded && _interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _isInterstitialAdLoaded = false;
          _loadInterstitialAd();
          onComplete?.call();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _isInterstitialAdLoaded = false;
          _loadInterstitialAd();
          onComplete?.call();
        },
      );
      _interstitialAd!.show();
    } else {
      // Ad wasn't loaded or offline, proceed immediately
      _loadInterstitialAd();
      onComplete?.call();
    }
  }

  @override
  void onClose() {
    _interstitialAd?.dispose();
    super.onClose();
  }
}
