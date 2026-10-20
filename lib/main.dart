import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'database/database.dart';
import 'repositories/providers.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // تُفتح قاعدة البيانات مرة واحدة، ولا يُعاد إنشاؤها عند كل تشغيل.
  final db = AppDatabase(driftDatabase(name: 'knowledge'));
  final notifications = LocalNotificationService();
  await notifications.init();

  runApp(ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      notificationServiceProvider.overrideWithValue(notifications),
    ],
    child: const KnowledgeApp(),
  ));
}
