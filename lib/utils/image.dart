import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:image/image.dart' as image_util;

part 'image.freezed.dart';

final loadedImagesProvider = StateNotifierProvider.family<LoadedImagesNotifier,
    List<LoadedImage>, ImageCollectionType>((ref, collectionType) {
  return LoadedImagesNotifier([]);
});

final decodedImagesProvider =
    FutureProvider.family<List<DecodedImage>, ImageCollectionType>(
        (ref, collectionType) {
  final loadedImages = ref.watch(loadedImagesProvider(collectionType));
  return _decodeLoadedImages(loadedImages);
});

final displayImagesProvider =
    FutureProvider.family<List<LoadedImage>, ImageCollectionType>(
        (ref, collectionType) async {
  final images = await ref.watch(decodedImagesProvider(collectionType).future);
  return images.map((image) {
    final trimMode = collectionType.displayTrimMode;
    return _getTrimmedDisplayImage(image, trimMode);
  }).toList();
});

LoadedImage _getTrimmedDisplayImage(
    DecodedImage inputImage, image_util.TrimMode? trimMode) {
  final trimmedImage = trimMode == null
      ? inputImage.image
      : image_util.trim(inputImage.image, mode: trimMode);

  return LoadedImage(
      fileName: inputImage.fileName,
      bytes: Uint8List.fromList(image_util.encodePng(trimmedImage)));
}

enum PaletteImageType { full, display }

// 256 pixels wide because colours are 0-255
const _paletteWidth = 256;

final defaultPaletteProvider = FutureProvider<List<int>>((ref) async {
  final inputImages =
      await ref.watch(decodedImagesProvider(ImageCollectionType.input).future);

  if (inputImages.isEmpty) return [];

  // Extract all unique pixels from all loaded images
  List<int> uniquePixels = [];
  for (final inputImage in inputImages) {
    for (final pixel in inputImage.image.data) {
      final opaquePixel = _discardPixelAlpha(pixel);

      // Only add pixel to list if the same colour isn't already there
      if (uniquePixels.contains(opaquePixel)) continue;
      uniquePixels.add(opaquePixel);
    }
  }

  return uniquePixels;
});

final defaultPaletteImageProvider =
    FutureProvider.family<LoadedImage?, PaletteImageType>((ref, type) async {
  final uniquePixels = await ref.watch(defaultPaletteProvider.future);

  if (uniquePixels.isEmpty) return null;

  // Create colour palette image
  final writeImage =
      image_util.Image(_paletteWidth, 1, channels: image_util.Channels.rgb);

  // Write palette colours into image
  for (int i = 0; i < uniquePixels.length.clamp(0, _paletteWidth); i++) {
    writeImage.setPixel(i, 0, uniquePixels[i]);
  }

  // Process palette image as desired
  final image_util.Image displayImage;
  switch (type) {
    case PaletteImageType.full:
      displayImage = writeImage;
      break;
    case PaletteImageType.display:
      displayImage = image_util.trim(writeImage,
          mode: image_util.TrimMode.bottomRightColor);
      break;
  }

  final bytes = Uint8List.fromList(image_util.encodePng(displayImage));
  return LoadedImage(
    fileName: '[generated]',
    bytes: bytes,
  );
});

final outputImagesProvider =
    FutureProvider.family<List<LoadedImage>, ImageCollectionType>(
        (ref, collectionType) async {
  final inputImages =
      await ref.watch(decodedImagesProvider(ImageCollectionType.input).future);
  final palette = await ref.watch(defaultPaletteProvider.future);

  List<LoadedImage> outputImages = [];

  for (final inputImage in inputImages) {
    // New image to operate on in
    final outputImage = inputImage.copyWith(
        image: image_util.Image(
      inputImage.image.width,
      inputImage.image.height,
      channels: inputImage.image.channels,
    ));

    for (int i = 0; i < inputImage.image.data.length; i++) {
      // Read pixel from INPUT image
      final pixel = inputImage.image.data[i];
      final opaquePixel = _discardPixelAlpha(pixel);

      // Get index of pixel in palette. Should always succeed since
      // palette is generated from input images
      final paletteIndex = palette.indexOf(opaquePixel);

      // New pixel is encoded with palette index
      final alpha = image_util.getAlpha(pixel);
      final newPixel = image_util.getColor(paletteIndex, 0, 0, alpha);

      // Write new pixel into OUTPUT image
      outputImage.image.setPixel(i, 0, newPixel);
    }

    // Add image to output list after pixels transformed
    final add =
        _getTrimmedDisplayImage(outputImage, collectionType.displayTrimMode);
    outputImages.add(add);
  }

  return outputImages;
});

final previewImageProvider = FutureProvider<LoadedImage?>((ref) async {
  final images =
      await ref.watch(displayImagesProvider(ImageCollectionType.input).future);
  if (images.isEmpty) return null;

  // TODO: Display selected
  return images[0];
});

int _discardPixelAlpha(int pixel) {
  final red = image_util.getRed(pixel);
  final green = image_util.getGreen(pixel);
  final blue = image_util.getBlue(pixel);
  return image_util.getColor(red, green, blue);
}

Future<List<DecodedImage>> _decodeLoadedImages(List<LoadedImage> images) async {
  final processedImages = await Future.wait(images.map((loadedImage) async {
    final image = await compute(image_util.decodeImage, loadedImage.bytes);
    if (image == null) return null;
    return DecodedImage(
      fileName: loadedImage.fileName,
      image: image,
    );
  }));

  final successfulImages = processedImages.whereType<DecodedImage>();
  return successfulImages.toList();
}

enum ImageCollectionType {
  input(displayTrimMode: image_util.TrimMode.transparent),
  palette(displayTrimMode: image_util.TrimMode.bottomRightColor),
  outputPreview(displayTrimMode: image_util.TrimMode.transparent),
  outputSave;

  const ImageCollectionType({this.displayTrimMode});

  final image_util.TrimMode? displayTrimMode;
}

@freezed
class LoadedImage with _$LoadedImage {
  factory LoadedImage({
    required String fileName,
    required Uint8List bytes,
  }) = _LoadedImage;
}

class LoadedImagesNotifier extends StateNotifier<List<LoadedImage>> {
  LoadedImagesNotifier(super.state);

  void update(List<LoadedImage> images) {
    state = images;
  }

  void clear() {
    state = [];
  }
}

@freezed
class DecodedImage with _$DecodedImage {
  factory DecodedImage({
    required String fileName,
    required image_util.Image image,
  }) = _DecodedImage;
}
