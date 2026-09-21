import 'package:get/get.dart';
import '../controllers/pdf_to_image_controller.dart';

class PdfToImageBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PdfToImageController>(() => PdfToImageController());
  }
}
