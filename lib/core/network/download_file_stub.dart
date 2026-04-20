import 'dart:typed_data';

Future<void> saveDownloadedFile(
  Uint8List bytes, {
  required String filename,
  required String contentType,
}) async {
  throw UnsupportedError(
    'File download is only implemented for Flutter Web right now.',
  );
}