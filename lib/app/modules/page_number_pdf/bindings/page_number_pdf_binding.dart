import 'package:get/get.dart';
import '../controllers/page_number_pdf_controller.dart';

class PageNumberPdfBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PageNumberPdfController>(() => PageNumberPdfController());
  }
}
