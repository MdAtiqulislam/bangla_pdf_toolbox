import 'package:get/get.dart';
import '../controllers/compress_pdf_controller.dart';

class CompressPdfBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CompressPdfController>(() => CompressPdfController());
  }
}
