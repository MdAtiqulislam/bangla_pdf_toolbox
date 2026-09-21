import 'package:get/get.dart';
import '../controllers/watermark_pdf_controller.dart';

class WatermarkPdfBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<WatermarkPdfController>(() => WatermarkPdfController());
  }
}
