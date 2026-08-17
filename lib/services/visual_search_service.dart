import 'dart:convert';

import 'package:mime/mime.dart';

class VisualSearchException implements Exception {
  const VisualSearchException(this.message);

  final String message;

  @override
  String toString() => message;
}

class VisualSearchService {
  static const maxImageBytes = 20 * 1024 * 1024;

  String createUploadPage({
    required List<int> bytes,
    required String filename,
  }) {
    if (bytes.isEmpty) {
      throw const VisualSearchException('La photo sélectionnée est vide.');
    }
    if (bytes.length > maxImageBytes) {
      throw const VisualSearchException(
        'Cette photo est trop volumineuse. Choisissez une image de moins de 20 Mo.',
      );
    }

    final mimeType = lookupMimeType(filename, headerBytes: bytes);
    if (mimeType == null || !mimeType.startsWith('image/')) {
      throw const VisualSearchException(
        'Ce fichier ne semble pas être une image compatible.',
      );
    }

    final endpoint = Uri.https('lens.google.com', '/v3/upload', {
      'ep': 'cntpubb',
      'hl': 'fr',
      'st': DateTime.now().millisecondsSinceEpoch.toString(),
      're': 'df',
      's': '4',
      'ucbcb': '1',
    });
    final encodedImage = base64Encode(bytes);
    final encodedFilename = jsonEncode(
      filename.isEmpty ? 'photo-produit.jpg' : filename,
    );
    final encodedMimeType = jsonEncode(mimeType);

    return '''
<!doctype html>
<html lang="fr">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Recherche visuelle</title>
  <style>
    :root { color-scheme: light; }
    * { box-sizing: border-box; }
    body {
      margin: 0;
      min-height: 100vh;
      display: grid;
      place-items: center;
      padding: 28px;
      background: #f7f7fb;
      color: #202124;
      font: 16px system-ui, sans-serif;
      text-align: center;
    }
    .spinner {
      width: 46px;
      height: 46px;
      margin: 0 auto 20px;
      border: 5px solid #d9dce8;
      border-top-color: #0d8f87;
      border-radius: 50%;
      animation: spin .8s linear infinite;
    }
    h1 { margin: 0 0 8px; font-size: 22px; }
    p { margin: 0; color: #5f6368; line-height: 1.5; }
    @keyframes spin { to { transform: rotate(360deg); } }
  </style>
</head>
<body>
  <main>
    <div class="spinner" aria-hidden="true"></div>
    <h1>Analyse de la photo…</h1>
    <p>Google Lens recherche les produits et images similaires.</p>
  </main>
  <form id="lens-form" action="${endpoint.toString().replaceAll('&', '&amp;')}"
        method="post" enctype="multipart/form-data" hidden>
    <input id="lens-image" type="file" name="encoded_image">
  </form>
  <script>
    (() => {
      const raw = atob('$encodedImage');
      const data = new Uint8Array(raw.length);
      for (let index = 0; index < raw.length; index++) {
        data[index] = raw.charCodeAt(index);
      }
      const file = new File([data], $encodedFilename, {type: $encodedMimeType});
      const transfer = new DataTransfer();
      transfer.items.add(file);
      document.getElementById('lens-image').files = transfer.files;
      document.getElementById('lens-form').submit();
    })();
  </script>
</body>
</html>
''';
  }
}
