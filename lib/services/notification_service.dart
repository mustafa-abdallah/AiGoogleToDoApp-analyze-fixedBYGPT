import 'dart:async';

/// خدمة التنبيهات والإشعارات المحلية (Local Notifications)
/// تدير جدولة التذكيرات لمهام المستخدم وإلغائها عند الإنجاز أو الحذف.
abstract class NotificationService {
  Future<void> init();
  Future<bool> requestPermissions();
  Future<void> scheduleTaskReminder({
    required String taskId,
    required String title,
    required DateTime remindAt,
    String? body,
  });
  Future<void> cancelTaskReminder(String taskId);
  Future<void> cancelAll();
}

/// تنفيذ افتراضي آمن لا يعتمد على ملحقات المنصة أثناء الاختبارات أو عند غياب الإذن
class LocalNotificationService implements NotificationService {
  LocalNotificationService();

  final Map<String, ({String title, DateTime remindAt})> _scheduled = {};

  /// توليد معرف عددي ثابت من معرّف المهمة النصي (UUID)
  static int idForTask(String taskId) => taskId.hashCode.abs() % 100000;

  @override
  Future<void> init() async {}

  @override
  Future<bool> requestPermissions() async {
    return true;
  }

  @override
  Future<void> scheduleTaskReminder({
    required String taskId,
    required String title,
    required DateTime remindAt,
    String? body,
  }) async {
    if (remindAt.isBefore(DateTime.now())) return;
    _scheduled[taskId] = (title: title, remindAt: remindAt);
  }

  @override
  Future<void> cancelTaskReminder(String taskId) async {
    _scheduled.remove(taskId);
  }

  @override
  Future<void> cancelAll() async {
    _scheduled.clear();
  }

  /// فحص المهام المجدولة محلياً للاختبارات والمتابعة
  bool hasReminder(String taskId) => _scheduled.containsKey(taskId);
  DateTime? reminderTime(String taskId) => _scheduled[taskId]?.remindAt;
}
