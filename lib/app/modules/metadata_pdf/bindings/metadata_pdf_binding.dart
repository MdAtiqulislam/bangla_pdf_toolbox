import 'package:get/get.dart';
import '../controllers/metadata_pdf_controller.dart';

class MetadataPdfBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MetadataPdfController>(() => MetadataPdfController());
  }
}
