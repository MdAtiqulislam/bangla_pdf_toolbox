import 'package:get/get.dart';
import '../controllers/signature_pdf_controller.dart';

class SignaturePdfBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SignaturePdfController>(() => SignaturePdfController());
  }
}
