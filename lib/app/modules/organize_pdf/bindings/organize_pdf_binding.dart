import 'package:get/get.dart';
import '../controllers/organize_pdf_controller.dart';

class OrganizePdfBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OrganizePdfController>(() => OrganizePdfController());
  }
}
