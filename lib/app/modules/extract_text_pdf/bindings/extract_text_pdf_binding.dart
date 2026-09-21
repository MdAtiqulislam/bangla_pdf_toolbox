import 'package:get/get.dart';
import '../controllers/extract_text_pdf_controller.dart';

class ExtractTextPdfBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ExtractTextPdfController>(() => ExtractTextPdfController());
  }
}
