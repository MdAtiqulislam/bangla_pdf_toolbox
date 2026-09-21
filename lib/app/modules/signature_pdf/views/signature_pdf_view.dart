import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/ad_banner_widget.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../controllers/signature_pdf_controller.dart';
import '../widgets/signature_drawing_pad.dart';

class SignaturePdfView extends GetView<SignaturePdfController> {
  const SignaturePdfView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: CustomAppBar(
        title: AppStrings.signaturePdf.tr,
        showActions: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Obx(() {
                if (controller.isSigning.value) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: AppColors.primary),
                        SizedBox(height: 16),
                        Text('স্বাক্ষর যুক্ত করা হচ্ছে...', style: TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
                  );
                }

                if (controller.selectedPdf.value == null) {
                  return _buildFilePickerPlaceholder(context, isDark);
                }

                if (controller.isRendering.value) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: AppColors.primary),
                        SizedBox(height: 16),
                        Text('PDF পেজ লোড হচ্ছে...', style: TextStyle(fontSize: 13, color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return _buildInteractiveSignCanvas(context, isDark);
              }),
            ),

            // Bottom Signature Actions Bar
            Obx(() {
              if (controller.selectedPdf.value == null || controller.isSigning.value) {
                return const SizedBox.shrink();
              }

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  border: Border(top: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // If signature is selected, show scale slider
                    if (controller.signatureBytes.value != null) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            const Icon(Icons.format_size_rounded, size: 16, color: AppColors.primary),
                            const SizedBox(width: 6),
                            const Text('সাইজ:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 3,
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                                ),
                                child: Slider(
                                  value: (controller.sigNormW.value / 0.35).clamp(0.4, 2.2),
                                  min: 0.4,
                                  max: 2.2,
                                  activeColor: AppColors.primary,
                                  onChanged: (val) => controller.setScale(val),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => _openSignatureDrawingPad(context),
                            icon: const Icon(Icons.draw_rounded, size: 16),
                            label: Text(
                              AppStrings.drawSignature.tr,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.add_photo_alternate_rounded, color: AppColors.primary, size: 20),
                          tooltip: AppStrings.importSignature.tr,
                          onPressed: () => controller.importSignatureFromGallery(),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: controller.signatureBytes.value == null
                                ? null
                                : () => controller.applySignatureAndSave(),
                            icon: const Icon(Icons.check_rounded, size: 16),
                            label: const Text(
                              'সংরক্ষণ করুন',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),

            const AdBannerWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilePickerPlaceholder(BuildContext context, bool isDark) {
    return Center(
      child: GestureDetector(
        onTap: () => controller.pickPdfFile(),
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.draw_rounded, color: AppColors.primary, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                'স্বাক্ষর করার জন্য PDF বাছুন',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text('Select document to place digital signature', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInteractiveSignCanvas(BuildContext context, bool isDark) {
    final pageIdx = controller.selectedPageIndex.value;
    final total = controller.totalPages.value;

    if (controller.pageRasterImages.isEmpty || pageIdx >= controller.pageRasterImages.length) {
      return const Center(child: Text('No page preview available'));
    }

    final pageBytes = controller.pageRasterImages[pageIdx];

    return Column(
      children: [
        // Page Selector Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded, size: 16),
                onPressed: pageIdx > 0 ? () => controller.changePage(pageIdx - 1) : null,
              ),
              Text(
                'Page ${pageIdx + 1} of $total',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onPressed: pageIdx < total - 1 ? () => controller.changePage(pageIdx + 1) : null,
              ),
            ],
          ),
        ),

        // Interactive Page Canvas with Direct Positioned Signature Box
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: AspectRatio(
                aspectRatio: 1 / 1.414, // Standard A4 Aspect Ratio
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final parentW = constraints.maxWidth;
                    final parentH = constraints.maxHeight;

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // 1. Page Background Image
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(pageBytes, fit: BoxFit.contain),
                            ),
                          ),

                          // 2. Direct Positioned Signature Overlay
                          Obx(() {
                            final sig = controller.signatureBytes.value;
                            if (sig == null) return const SizedBox.shrink();

                            final left = controller.sigNormX.value * parentW;
                            final top = controller.sigNormY.value * parentH;
                            final sigW = controller.sigNormW.value * parentW;
                            final sigH = controller.sigNormH.value * parentH;

                            return Positioned(
                              left: left,
                              top: top,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  // Drag Body Box
                                  GestureDetector(
                                    onPanUpdate: (details) {
                                      final currentL = controller.sigNormX.value * parentW;
                                      final currentT = controller.sigNormY.value * parentH;
                                      final newL = currentL + details.delta.dx;
                                      final newT = currentT + details.delta.dy;
                                      controller.updateSignaturePosition(newL / parentW, newT / parentH);
                                    },
                                    child: Container(
                                      width: sigW,
                                      height: sigH,
                                      decoration: BoxDecoration(
                                        border: Border.all(color: AppColors.primary, width: 1.8),
                                        color: AppColors.primary.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Center(
                                        child: Image.memory(sig, fit: BoxFit.contain),
                                      ),
                                    ),
                                  ),

                                  // Top-Right Remove Button
                                  Positioned(
                                    top: -10,
                                    right: -10,
                                    child: GestureDetector(
                                      onTap: () => controller.removeSignature(),
                                      child: Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: const BoxDecoration(
                                          color: Colors.redAccent,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close_rounded, size: 12, color: Colors.white),
                                      ),
                                    ),
                                  ),

                                  // Bottom-Right Corner Resize Handle
                                  Positioned(
                                    bottom: -10,
                                    right: -10,
                                    child: GestureDetector(
                                      onPanUpdate: (details) {
                                        controller.updateSignatureSize(
                                          details.delta.dx,
                                          details.delta.dy,
                                          parentW,
                                          parentH,
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.open_in_full_rounded, size: 12, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),

        // Hint Bar
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            controller.signatureBytes.value != null
                ? 'স্বাক্ষর টেনে সরান অথবা কোণার বাটন দিয়ে বড়/ছোট করুন'
                : 'নিচের বাটন থেকে স্বাক্ষর আঁকুন বা ইমেজ আনুন',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ),
      ],
    );
  }

  void _openSignatureDrawingPad(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SignatureDrawingPad(
        onSignatureSaved: (bytes) => controller.setSignatureBytes(bytes),
      ),
    );
  }
}
