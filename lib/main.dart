import 'package:flutter/material.dart';

import 'app/app.dart';
import 'services/push_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PushNotificationService.initialize();
  runApp(const GlaziaHomeSecureApp());
}
