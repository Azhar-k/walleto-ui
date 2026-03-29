import 'dart:typed_data';

void registerPdfViewFactory(String viewId, Uint8List pdfBytes) {
  // No-op for standard VM platforms
}

void revokeBlobUrlByViewId(String viewId) {
  // No-op for standard VM platforms
}

void triggerBrowserDownload(List<int> bytes, String fileName) {
  // No-op for standard VM platforms
}
