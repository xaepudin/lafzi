import 'dart:typed_data';

/// Downloads are only exposed by the web build; native platforms share
/// through the system share sheet instead.
Future<bool> downloadImage(Uint8List bytes, {required String name}) async {
  throw UnsupportedError('Downloading images is only supported on the web');
}
