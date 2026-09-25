import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../models/media_item.dart';

Future<Isar> openIsar() async {
  final dir = await getApplicationDocumentsDirectory();
  return Isar.open(
    [MediaItemSchema],
    directory: dir.path,
    inspector: false,
  );
}
