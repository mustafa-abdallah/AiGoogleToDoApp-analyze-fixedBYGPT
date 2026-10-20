import 'package:flutter_test/flutter_test.dart';
import 'package:knowledge_app/services/notification_service.dart';

void main() {
  group('NotificationService (المرحلة 9 — الإشعارات والتذكيرات)', () {
    late LocalNotificationService service;

    setUp(() async {
      service = LocalNotificationService();
      await service.init();
    });

    test('توليد معرف عددي فريد وثابت من UUID', () {
      final id1 = LocalNotificationService.idForTask('task-uuid-1234');
      final id2 = LocalNotificationService.idForTask('task-uuid-1234');
      final id3 = LocalNotificationService.idForTask('task-uuid-5678');

      expect(id1, equals(id2));
      expect(id1, isNonNegative);
      expect(id1, isNot(equals(id3)));
    });

    test('جدولة تذكير لمهمة في المستقبل', () async {
      final futureTime = DateTime.now().add(const Duration(hours: 2));
      await service.scheduleTaskReminder(
        taskId: 'task-1',
        title: 'مراجعة التقرير الأسبوعي',
        remindAt: futureTime,
      );

      expect(service.hasReminder('task-1'), isTrue);
      expect(service.reminderTime('task-1'), equals(futureTime));
    });

    test('تجاهل جدولة تذكير لموعد انقضى في الماضي', () async {
      final pastTime = DateTime.now().subtract(const Duration(hours: 1));
      await service.scheduleTaskReminder(
        taskId: 'task-past',
        title: 'مهمة قديمة',
        remindAt: pastTime,
      );

      expect(service.hasReminder('task-past'), isFalse);
    });

    test('إلغاء تذكير عند إكمال المهمة أو حذفها', () async {
      final futureTime = DateTime.now().add(const Duration(days: 1));
      await service.scheduleTaskReminder(
        taskId: 'task-2',
        title: 'شراء المستلزمات',
        remindAt: futureTime,
      );
      expect(service.hasReminder('task-2'), isTrue);

      await service.cancelTaskReminder('task-2');
      expect(service.hasReminder('task-2'), isFalse);
    });

    test('إلغاء كل التذكيرات دفعة واحدة', () async {
      final t1 = DateTime.now().add(const Duration(days: 1));
      final t2 = DateTime.now().add(const Duration(days: 2));
      await service.scheduleTaskReminder(taskId: 'task-a', title: 'A', remindAt: t1);
      await service.scheduleTaskReminder(taskId: 'task-b', title: 'B', remindAt: t2);

      expect(service.hasReminder('task-a'), isTrue);
      expect(service.hasReminder('task-b'), isTrue);

      await service.cancelAll();
      expect(service.hasReminder('task-a'), isFalse);
      expect(service.hasReminder('task-b'), isFalse);
    });
  });
}
