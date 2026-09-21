import 'package:get/get.dart';
import '../controllers/lock_pdf_controller.dart';

class LockPdfBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LockPdfController>(() => LockPdfController());
  }
}
