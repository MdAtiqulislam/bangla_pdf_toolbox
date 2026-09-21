import 'package:get/get.dart';
import '../controllers/text_to_pdf_controller.dart';

class TextToPdfBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TextToPdfController>(() => TextToPdfController());
  }
}
