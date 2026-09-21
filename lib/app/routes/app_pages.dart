import 'package:get/get.dart';
import '../modules/compress_pdf/bindings/compress_pdf_binding.dart';
import '../modules/compress_pdf/views/compress_pdf_view.dart';
import '../modules/extract_text_pdf/bindings/extract_text_pdf_binding.dart';
import '../modules/extract_text_pdf/views/extract_text_pdf_view.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/image_to_pdf/bindings/image_to_pdf_binding.dart';
import '../modules/image_to_pdf/views/image_to_pdf_view.dart';
import '../modules/lock_pdf/bindings/lock_pdf_binding.dart';
import '../modules/lock_pdf/views/lock_pdf_view.dart';
import '../modules/merge_pdf/bindings/merge_pdf_binding.dart';
import '../modules/merge_pdf/views/merge_pdf_view.dart';
import '../modules/metadata_pdf/bindings/metadata_pdf_binding.dart';
import '../modules/metadata_pdf/views/metadata_pdf_view.dart';
import '../modules/organize_pdf/bindings/organize_pdf_binding.dart';
import '../modules/organize_pdf/views/organize_pdf_view.dart';
import '../modules/page_number_pdf/bindings/page_number_pdf_binding.dart';
import '../modules/page_number_pdf/views/page_number_pdf_view.dart';
import '../modules/pdf_to_image/bindings/pdf_to_image_binding.dart';
import '../modules/pdf_to_image/views/pdf_to_image_view.dart';
import '../modules/pdf_viewer/bindings/pdf_viewer_binding.dart';
import '../modules/pdf_viewer/views/pdf_viewer_view.dart';
import '../modules/result/bindings/result_binding.dart';
import '../modules/result/views/result_view.dart';
import '../modules/settings/bindings/settings_binding.dart';
import '../modules/settings/views/settings_view.dart';
import '../modules/signature_pdf/bindings/signature_pdf_binding.dart';
import '../modules/signature_pdf/views/signature_pdf_view.dart';
import '../modules/splash/bindings/splash_binding.dart';
import '../modules/splash/views/splash_view.dart';
import '../modules/split_pdf/bindings/split_pdf_binding.dart';
import '../modules/split_pdf/views/split_pdf_view.dart';
import '../modules/text_to_pdf/bindings/text_to_pdf_binding.dart';
import '../modules/text_to_pdf/views/text_to_pdf_view.dart';
import '../modules/watermark_pdf/bindings/watermark_pdf_binding.dart';
import '../modules/watermark_pdf/views/watermark_pdf_view.dart';
import 'app_routes.dart';

class AppPages {
  static const initial = AppRoutes.splash;

  static final routes = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashView(),
      binding: SplashBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeView(),
      binding: HomeBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.imageToPdf,
      page: () => const ImageToPdfView(),
      binding: ImageToPdfBinding(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: AppRoutes.pdfToImage,
      page: () => const PdfToImageView(),
      binding: PdfToImageBinding(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: AppRoutes.mergePdf,
      page: () => const MergePdfView(),
      binding: MergePdfBinding(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: AppRoutes.splitPdf,
      page: () => const SplitPdfView(),
      binding: SplitPdfBinding(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: AppRoutes.lockPdf,
      page: () => const LockPdfView(),
      binding: LockPdfBinding(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: AppRoutes.compressPdf,
      page: () => const CompressPdfView(),
      binding: CompressPdfBinding(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: AppRoutes.signaturePdf,
      page: () => const SignaturePdfView(),
      binding: SignaturePdfBinding(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: AppRoutes.organizePdf,
      page: () => const OrganizePdfView(),
      binding: OrganizePdfBinding(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: AppRoutes.watermarkPdf,
      page: () => const WatermarkPdfView(),
      binding: WatermarkPdfBinding(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: AppRoutes.pageNumberPdf,
      page: () => const PageNumberPdfView(),
      binding: PageNumberPdfBinding(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: AppRoutes.textToPdf,
      page: () => const TextToPdfView(),
      binding: TextToPdfBinding(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: AppRoutes.extractTextPdf,
      page: () => const ExtractTextPdfView(),
      binding: ExtractTextPdfBinding(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: AppRoutes.metadataPdf,
      page: () => const MetadataPdfView(),
      binding: MetadataPdfBinding(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: AppRoutes.pdfViewer,
      page: () => const PdfViewerView(),
      binding: PdfViewerBinding(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: AppRoutes.result,
      page: () => const ResultView(),
      binding: ResultBinding(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsView(),
      binding: SettingsBinding(),
      transition: Transition.rightToLeftWithFade,
    ),
  ];
}
