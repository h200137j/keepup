import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Copies a picked image into the app's persistent documents directory
/// (image_picker's own path may live in a volatile cache/temp dir) and
/// returns the new, stable path.
Future<String> persistPickedImage(XFile picked) async {
  final docsDir = await getApplicationDocumentsDirectory();
  final imagesDir = Directory(p.join(docsDir.path, 'media_images'));
  if (!imagesDir.existsSync()) imagesDir.createSync(recursive: true);

  final ext = p.extension(picked.path).isEmpty ? '.jpg' : p.extension(picked.path);
  final destPath = p.join(imagesDir.path, '${_uuid.v4()}$ext');

  await File(picked.path).copy(destPath);
  return destPath;
}
