import 'dart:typed_data';
import 'dart:ui' as ui;

class ProfileImageException implements Exception {
  const ProfileImageException(this.message);

  final String message;
}

class ProfileImageService {
  ProfileImageService._();

  static const _maximumSourceSize = 20 * 1024 * 1024;
  static const _avatarSize = 512;

  static Future<Uint8List> prepare(Uint8List source) async {
    if (source.isEmpty || source.length > _maximumSourceSize) {
      throw const ProfileImageException(
        'Choisissez une image de moins de 20 Mo.',
      );
    }

    ui.Codec? codec;
    ui.Image? image;
    try {
      codec = await ui.instantiateImageCodec(
        source,
        targetWidth: _avatarSize,
        targetHeight: _avatarSize,
        allowUpscaling: false,
      );
      final frame = await codec.getNextFrame();
      image = frame.image;
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) {
        throw const ProfileImageException(
          'Impossible de préparer cette image.',
        );
      }
      return data.buffer.asUint8List();
    } on ProfileImageException {
      rethrow;
    } on Object {
      throw const ProfileImageException(
        'Ce fichier n’est pas une image compatible.',
      );
    } finally {
      image?.dispose();
      codec?.dispose();
    }
  }
}
