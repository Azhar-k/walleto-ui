// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'dart:typed_data';

final _blobUrls = <String, String>{};

void registerPdfViewFactory(String viewId, Uint8List pdfBytes) {
  final blob = html.Blob([pdfBytes], 'application/pdf');
  final blobUrl = html.Url.createObjectUrlFromBlob(blob);
  _blobUrls[viewId] = blobUrl;

  ui_web.platformViewRegistry.registerViewFactory(viewId, (int _) {
    return html.IFrameElement()
      ..src = blobUrl
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%';
  });
}

void revokeBlobUrlByViewId(String viewId) {
  final blobUrl = _blobUrls.remove(viewId);
  if (blobUrl != null) {
    html.Url.revokeObjectUrl(blobUrl);
  }
}

void triggerBrowserDownload(List<int> bytes, String fileName) {
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
}
