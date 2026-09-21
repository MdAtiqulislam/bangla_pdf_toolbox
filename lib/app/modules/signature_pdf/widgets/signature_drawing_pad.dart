import 'package:get/get.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';

class SignatureDrawingPad extends StatefulWidget {
  final Function(Uint8List) onSignatureSaved;

  const SignatureDrawingPad({super.key, required this.onSignatureSaved});

  @override
  State<SignatureDrawingPad> createState() => _SignatureDrawingPadState();
}

class _SignatureDrawingPadState extends State<SignatureDrawingPad> {
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];
  Color _selectedColor = Colors.black;
  double _strokeWidth = 3.5;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.drawSignature.tr,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.undo_rounded),
                    tooltip: 'Undo',
                    onPressed: _strokes.isNotEmpty
                        ? () {
                            setState(() {
                              _strokes.removeLast();
                            });
                          }
                        : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded),
                    tooltip: AppStrings.clearSignature.tr,
                    onPressed: () {
                      setState(() {
                        _strokes.clear();
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Drawing Canvas
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: GestureDetector(
                  onPanStart: (details) {
                    setState(() {
                      _currentStroke = [details.localPosition];
                      _strokes.add(_currentStroke);
                    });
                  },
                  onPanUpdate: (details) {
                    setState(() {
                      _currentStroke.add(details.localPosition);
                    });
                  },
                  child: CustomPaint(
                    painter: _SignaturePainter(strokes: _strokes, color: _selectedColor, strokeWidth: _strokeWidth),
                    size: Size.infinite,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Color Palette & Pen Size
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _buildColorDot(Colors.black),
                  const SizedBox(width: 8),
                  _buildColorDot(const Color(0xFF1E40AF)), // Blue
                  const SizedBox(width: 8),
                  _buildColorDot(const Color(0xFFDC2626)), // Red
                ],
              ),
              Expanded(
                child: Slider(
                  value: _strokeWidth,
                  min: 1.5,
                  max: 8.0,
                  activeColor: AppColors.primary,
                  onChanged: (val) => setState(() => _strokeWidth = val),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Save Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _strokes.isEmpty ? null : () => _exportSignature(),
            child: Text(
              AppStrings.applySignature.tr,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorDot(Color color) {
    final isSelected = _selectedColor == color;
    return GestureDetector(
      onTap: () => setState(() => _selectedColor = color),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.white,
            width: isSelected ? 3 : 1.5,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportSignature() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const canvasSize = Size(600, 300);

    final painter = _SignaturePainter(strokes: _strokes, color: _selectedColor, strokeWidth: _strokeWidth * 1.5);
    painter.paint(canvas, canvasSize);

    final picture = recorder.endRecording();
    final img = await picture.toImage(canvasSize.width.toInt(), canvasSize.height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

    if (byteData != null) {
      widget.onSignatureSaved(byteData.buffer.asUint8List());
      if (mounted) Navigator.pop(context);
    }
  }
}

class _SignaturePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final Color color;
  final double strokeWidth;

  _SignaturePainter({required this.strokes, required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.length < 2) continue;
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (int i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
