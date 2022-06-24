import 'dart:typed_data';
import 'dart:isolate';

import 'package:image/image.dart' as image_util;

Future<List<LoadedImage>> processLoadedImages(List<LoadedImage> images,
    {image_util.TrimMode? trimMode}) async {
  final processedImages = await Future.wait(images.map((loadedImage) async {
    final bytes =
        await _processLoadedImage(loadedImage.bytes, trimMode: trimMode);
    if (bytes == null) return null;
    return LoadedImage(
      fileName: loadedImage.fileName,
      bytes: bytes,
    );
  }));

  final successfulImages = processedImages.whereType<LoadedImage>();
  return successfulImages.toList();
}

Future<Uint8List?> _processLoadedImage(Uint8List bytes,
    {image_util.TrimMode? trimMode}) async {
  var receivePort = ReceivePort();

  // Spawn isolate to decode image so we don't stall the UI thread
  await Isolate.spawn(
      _decodeIsolate, _DecodeParam(bytes, receivePort.sendPort));

  // Get the processed image from the isolate.
  var image = await receivePort.first as image_util.Image?;
  if (image != null && trimMode != null) {
    image = image_util.trim(image, mode: trimMode);
  }

  if (image == null) return null;

  return Uint8List.fromList(image_util.encodePng(image));
}

class LoadedImage {
  final String fileName;
  final Uint8List bytes;

  const LoadedImage({
    required this.fileName,
    required this.bytes,
  });
}

void _decodeIsolate(_DecodeParam param) {
  var image = image_util.decodeImage(param.bytes);
  param.sendPort.send(image);
}

class _DecodeParam {
  final Uint8List bytes;
  final SendPort sendPort;
  _DecodeParam(this.bytes, this.sendPort);
}
