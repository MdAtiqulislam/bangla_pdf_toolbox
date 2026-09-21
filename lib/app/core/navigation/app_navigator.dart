import 'package:get/get.dart';
import '../../routes/app_routes.dart';

class AppNavigator {
  static void toHome() => Get.offAllNamed(AppRoutes.home);
  static void toImageToPdf() => Get.toNamed(AppRoutes.imageToPdf);
  static void toPdfToImage() => Get.toNamed(AppRoutes.pdfToImage);
  static void toMergePdf() => Get.toNamed(AppRoutes.mergePdf);
  static void toSettings() => Get.toNamed(AppRoutes.settings);
  static void back() => Get.back();
}
