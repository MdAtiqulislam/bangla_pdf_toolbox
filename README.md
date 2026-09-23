# Bangla PDF Toolbox (bangla_pdf_toolbox)

All-in-one Bangla-friendly PDF toolkit — merge, compress, convert, sign and organize PDFs on device.

## Features

- Merge, compress and organize PDFs
- Image-to-PDF and PDF-to-image conversion
- Text extraction, page numbers and metadata editing
- Lock PDFs, digital signatures and PDF viewer
- Settings, result screens and splash flow

## Tech Stack

- Flutter (Dart)
- GetX for state management and routing
- On-device PDF processing

## Getting Started

```bash
flutter pub get
flutter run
```

Build a release APK:

```bash
flutter build apk --release
```

## Project Structure

```
lib/
├── app/modules/   # Home + one module per PDF tool
├── services/      # File/PDF services
└── main.dart      # App entry point
```

## Notes

- App label: "PDF Tool" (Android)
- No secrets, keystores or Firebase configs are committed to this repository.
