import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../services/isar_service.dart';

final isarProvider = FutureProvider<Isar>((ref) => openIsar());
