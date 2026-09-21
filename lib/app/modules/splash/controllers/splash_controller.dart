import 'package:get/get.dart';
import '../../../core/services/file_intent_service.dart';
import '../../../routes/app_routes.dart';

class SplashController extends GetxController {
  @override
  void onReady() {
    super.onReady();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(milliseconds: 1000));
    Get.offAllNamed(AppRoutes.home);
    if (Get.isRegistered<FileIntentService>()) {
      final intentService = Get.find<FileIntentService>();
      if (intentService.hasPendingPdf) {
        intentService.openPendingPdf();
      }
    }
  }
}
