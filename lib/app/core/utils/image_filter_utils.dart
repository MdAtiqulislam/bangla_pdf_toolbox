import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

enum DocFilterType {
  original,
  magicColor,
  blackAndWhite,
  grayscale,
  brighten,
}

extension DocFilterTypeExtension on DocFilterType {
  String get nameKey {
    switch (this) {
      case DocFilterType.original:
        return 'original';
      case DocFilterType.magicColor:
        return 'magic_color';
      case DocFilterType.blackAndWhite:
        return 'black_and_white';
      case DocFilterType.grayscale:
        return 'grayscale';
      case DocFilterType.brighten:
        return 'brighten';
    }
  }
}

class ImageFilterUtils {
  /// Apply CamScanner-style document filter to image bytes in background isolate
  static Future<Uint8List> applyFilter(Uint8List imageBytes, DocFilterType filter) async {
    if (filter == DocFilterType.original) {
      return imageBytes;
    }
    return compute(_processFilterIsolate, _FilterParam(imageBytes, filter));
  }

  /// Rotate image by 90, 180, or 270 degrees in background isolate
  static Future<Uint8List> rotateImage(Uint8List imageBytes, int angle) async {
    if (angle % 360 == 0) return imageBytes;
    return compute(_processRotateIsolate, _RotateParam(imageBytes, angle));
  }

  /// Process both rotation and filter in background isolate
  static Future<Uint8List> processImage(Uint8List imageBytes, {required DocFilterType filter, int angle = 0}) async {
    return compute(_processAllIsolate, _ProcessAllParam(imageBytes, filter, angle));
  }
}

class _FilterParam {
  final Uint8List bytes;
  final DocFilterType filter;
  _FilterParam(this.bytes, this.filter);
}

class _RotateParam {
  final Uint8List bytes;
  final int angle;
  _RotateParam(this.bytes, this.angle);
}

class _ProcessAllParam {
  final Uint8List bytes;
  final DocFilterType filter;
  final int angle;
  _ProcessAllParam(this.bytes, this.filter, this.angle);
}

Uint8List _processFilterIsolate(_FilterParam param) {
  final decoded = img.decodeImage(param.bytes);
  if (decoded == null) return param.bytes;

  final filtered = _applyFilterToImage(decoded, param.filter);
  return Uint8List.fromList(img.encodeJpg(filtered, quality: 90));
}

Uint8List _processRotateIsolate(_RotateParam param) {
  final decoded = img.decodeImage(param.bytes);
  if (decoded == null) return param.bytes;

  final rotated = img.copyRotate(decoded, angle: param.angle.toDouble());
  return Uint8List.fromList(img.encodeJpg(rotated, quality: 90));
}

Uint8List _processAllIsolate(_ProcessAllParam param) {
  img.Image? current = img.decodeImage(param.bytes);
  if (current == null) return param.bytes;

  if (param.angle % 360 != 0) {
    current = img.copyRotate(current, angle: param.angle.toDouble());
  }

  final filtered = _applyFilterToImage(current, param.filter);
  return Uint8List.fromList(img.encodeJpg(filtered, quality: 90));
}

img.Image _applyFilterToImage(img.Image src, DocFilterType filter) {
  switch (filter) {
    case DocFilterType.original:
      return src;

    case DocFilterType.magicColor:
      // Magic Color: Enhance contrast (+25%), slight brightness (+10%), color saturation (+15%), text sharpen
      img.Image enhanced = img.adjustColor(
        src,
        contrast: 1.25,
        brightness: 1.08,
        saturation: 1.15,
        gamma: 0.95,
      );
      // Subtle 3x3 unsharp mask / sharpen matrix to make letters pop crisp
      const sharpenKernel = [
        0.0, -0.4, 0.0,
        -0.4, 2.6, -0.4,
        0.0, -0.4, 0.0,
      ];
      enhanced = img.convolution(enhanced, filter: sharpenKernel, div: 1.0);
      return enhanced;

    case DocFilterType.blackAndWhite:
      // B&W / Document Mode: High contrast text on clean white paper
      // 1. Convert to grayscale
      img.Image gray = img.grayscale(src);
      // 2. Strong contrast boost & brightness adjustment to clear shadows
      img.Image bw = img.adjustColor(
        gray,
        contrast: 1.6,
        brightness: 1.18,
        gamma: 0.85,
      );
      return bw;

    case DocFilterType.grayscale:
      // Smooth Grayscale
      img.Image gray = img.grayscale(src);
      return img.adjustColor(gray, contrast: 1.15, brightness: 1.05);

    case DocFilterType.brighten:
      // Brighten / Shadow remover
      return img.adjustColor(
        src,
        brightness: 1.22,
        contrast: 1.15,
        gamma: 0.92,
      );
  }
}
