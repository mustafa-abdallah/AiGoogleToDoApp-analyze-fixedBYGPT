import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format.dart';
import '../../../core/widgets/prompt.dart';
import '../../../repositories/providers.dart';
import '../../../services/backup_service.dart';
import '../providers/settings_providers.dart';

const _tableLabels = {
  'notes': 'ملاحظات',
  'tasks': 'مهام',
  'habits': 'عادات',
  'habitLogs': 'سجلات العادات',
  'folders': 'مجلدات',
  'tags': 'وسوم',
  'projects': 'تصنيفات',
};

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _toast(BuildContext context, String msg) => ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text(msg)));

  static String _fileName() {
    final n = DateTime.now();
    String t(int v) => v.toString().padLeft(2, '0');
    return 'knowledge-backup-${n.year}-${t(n.month)}-${t(n.day)}-${t(n.hour)}${t(n.minute)}.json';
  }

  // ---------- التصدير ----------

  Future<void> _exportFile(BuildContext context, WidgetRef ref) async {
    try {
      final text = await ref.read(backupServiceProvider).exportJson();
      final bytes = Uint8List.fromList(utf8.encode(text));
      final uri = await FilePicker.saveFile(
        dialogTitle: 'اختر مكان حفظ النسخة الاحتياطية',
        fileName: _fileName(),
        bytes: bytes,
        mimeType: 'application/json',
      );
      if (uri == null) {
        if (context.mounted) _toast(context, 'لم تُحفظ النسخة');
        return;
      }
      await ref.read(settingsRepositoryProvider).markExported();
      if (context.mounted) {
        _toast(context, 'حُفظت النسخة (${(bytes.length / 1024).ceil()} ك.ب)');
      }
    } catch (e) {
      if (context.mounted) _toast(context, 'تعذّر الحفظ: $e');
    }
  }

  Future<void> _exportClipboard(BuildContext context, WidgetRef ref) async {
    try {
      final text = await ref.read(backupServiceProvider).exportJson();
      await Clipboard.setData(ClipboardData(text: text));
      if (context.mounted) {
        _toast(context,
            'نُسخت البيانات إلى الحافظة (${(text.length / 1024).ceil()} ك.ب). الصقها في مكان آمن.');
      }
    } catch (e) {
      if (context.mounted) _toast(context, 'تعذّر التصدير: $e');
    }
  }

  // ---------- الاستعادة ----------

  /// يفحص النسخة ويعرض ملخصها، ثم يستعيدها بعد اختيار المستخدم (دمج أو استبدال).
  Future<void> _inspectAndRestore(BuildContext context, WidgetRef ref, String text) async {
    final svc = ref.read(backupServiceProvider);
    final BackupInfo info;
    try {
      info = svc.inspect(text);
    } on FormatException catch (e) {
      _toast(context, e.message);
      return;
    }
    if (!context.mounted) return;

    final lines = <String>[
      'التاريخ: ${info.exportedAt == null ? 'غير معروف' : formatDateTime(info.exportedAt!)}',
      info.verified
          ? 'سلامة الملف: تم التحقق ✓'
          : 'سلامة الملف: نسخة قديمة بلا مجموع اختباري',
      for (final e in _tableLabels.entries)
        if ((info.counts[e.key] ?? 0) > 0) '${e.value}: ${info.counts[e.key]}',
    ];
    final mode = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('استعادة نسخة احتياطية'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final l in lines) Text(l),
            const SizedBox(height: 12),
            const Text('دمج: يضيف ما في النسخة ولا يحذف شيئًا.\n'
                'استبدال: يمسح كل ما في التطبيق الآن ويضع محتوى النسخة.'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, 'replace'), child: const Text('استبدال')),
          FilledButton(onPressed: () => Navigator.pop(ctx, 'merge'), child: const Text('دمج')),
        ],
      ),
    );
    if (mode == null || !context.mounted) return;

    if (mode == 'replace') {
      final ok = await confirm(context,
          title: 'استبدال كل البيانات؟',
          message: 'سيُحذف كل ما في التطبيق الآن ويُستبدل بمحتوى النسخة. لا يمكن التراجع.',
          action: 'استبدال');
      if (!ok || !context.mounted) return;
    }
    try {
      final n = await svc.importJson(text, replace: mode == 'replace');
      if (context.mounted) _toast(context, 'تمت الاستعادة: $n سجلًا');
    } on FormatException catch (e) {
      if (context.mounted) _toast(context, e.message);
    }
  }

  Future<void> _importFile(BuildContext context, WidgetRef ref) async {
    final String text;
    try {
      final f = await FilePicker.pickFile(dialogTitle: 'اختر ملف النسخة الاحتياطية');
      if (f == null) return;
      text = utf8.decode(await f.readAsBytes());
    } on FormatException {
      if (context.mounted) _toast(context, 'الملف ليس نسخة احتياطية نصية صالحة');
      return;
    } catch (e) {
      if (context.mounted) _toast(context, 'تعذّرت قراءة الملف: $e');
      return;
    }
    if (context.mounted) await _inspectAndRestore(context, ref, text);
  }

  Future<void> _importClipboard(BuildContext context, WidgetRef ref) async {
    final c = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('استيراد من نص'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: c,
            maxLines: 6,
            decoration: const InputDecoration(
                hintText: 'الصق النسخة الاحتياطية هنا', border: OutlineInputBorder()),
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              icon: const Icon(Icons.content_paste, size: 18),
              label: const Text('لصق من الحافظة'),
              onPressed: () async {
                final d = await Clipboard.getData(Clipboard.kTextPlain);
                if (d?.text != null) c.text = d!.text!;
              },
            ),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(ctx, c.text), child: const Text('متابعة')),
        ],
      ),
    );
    if (text == null || text.trim().isEmpty || !context.mounted) return;
    await _inspectAndRestore(context, ref, text);
  }

  // ---------- سلامة قاعدة البيانات ----------

  Future<void> _checkIntegrity(BuildContext context, WidgetRef ref) async {
    try {
      final r = await ref.read(databaseProvider).integrityCheck();
      if (!context.mounted) return;
      _toast(context, r == 'ok' ? 'قاعدة البيانات سليمة ✓' : 'رُصدت مشكلة: $r');
    } catch (e) {
      if (context.mounted) _toast(context, 'تعذّر الفحص: $e');
    }
  }

  Future<void> _rebuildIndex(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(databaseProvider).rebuildSearchIndex();
      if (context.mounted) _toast(context, 'أُعيد بناء فهرس البحث');
    } catch (e) {
      if (context.mounted) _toast(context, 'تعذّرت إعادة البناء: $e');
    }
  }

  Widget _header(BuildContext context, String t) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(t, style: Theme.of(context).textTheme.titleSmall),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final last = ref.watch(lastBackupProvider);
    final lastText = last.when(
      data: (d) => d == null ? 'لم تُؤخذ نسخة بعد' : formatDateTime(d),
      loading: () => '…',
      error: (_, __) => 'غير معروف',
    );

    final dark = Theme.of(context).brightness == Brightness.dark;

    Widget cardGroup(List<Widget> children) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: dark ? const Color(0xFF181B26) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: dark ? const Color(0xFF282D3F) : const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(children: children),
          ),
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات والنسخ الاحتياطي', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          // كارت الخصوصية
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: dark
                    ? [const Color(0xFF1E2230), const Color(0xFF141722)]
                    : [Colors.white, const Color(0xFFF0FDF4)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF10B981).withAlpha(dark ? 60 : 80),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withAlpha(30),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.shield_rounded, color: Color(0xFF10B981), size: 24),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'بياناتك ملكك بالكامل (Local-First)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'لا خوادم سحابية ولا تتبع. يتم تخزين كل شيء على جهازك مباشرة باستخدام SQLite.',
                        style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          _header(context, 'النسخ الاحتياطي والاستعادة'),
          cardGroup([
            ListTile(
              leading: const Icon(Icons.history_rounded, color: Color(0xFFF59E0B)),
              title: const Text('آخر نسخة احتياطية', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              subtitle: Text(lastText, style: const TextStyle(fontSize: 12)),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.download_rounded, color: Color(0xFF38BDF8)),
              title: const Text('حفظ نسخة احتياطية في ملف', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              subtitle: const Text('احفظ ملف JSON في التنزيلات أو Google Drive', style: TextStyle(fontSize: 12)),
              onTap: () => _exportFile(context, ref),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.upload_file_rounded, color: Color(0xFF10B981)),
              title: const Text('استعادة من ملف', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              subtitle: const Text('يُفحص الملف ويُعرض ملخصه قبل أي تغيير', style: TextStyle(fontSize: 12)),
              onTap: () => _importFile(context, ref),
            ),
            const Divider(height: 1),
            ExpansionTile(
              leading: const Icon(Icons.content_copy_rounded, color: Colors.grey),
              title: const Text('عبر الحافظة (للنصوص والبيانات السريعة)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              children: [
                ListTile(
                  title: const Text('نسخ البيانات إلى الحافظة', style: TextStyle(fontSize: 13)),
                  onTap: () => _exportClipboard(context, ref),
                ),
                ListTile(
                  title: const Text('استعادة من نص ملصوق', style: TextStyle(fontSize: 13)),
                  onTap: () => _importClipboard(context, ref),
                ),
              ],
            ),
          ]),

          const SizedBox(height: 10),
          _header(context, 'سلامة قاعدة البيانات وفهرس البحث'),
          cardGroup([
            ListTile(
              leading: const Icon(Icons.verified_rounded, color: Color(0xFF10B981)),
              title: const Text('فحص سلامة قاعدة البيانات', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              subtitle: const Text('فحص تكامل الجداول والمفاتيح المحلية', style: TextStyle(fontSize: 12)),
              onTap: () => _checkIntegrity(context, ref),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.manage_search_rounded, color: Color(0xFFF59E0B)),
              title: const Text('إعادة بناء فهرس البحث', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              subtitle: const Text('استعادة دقة البحث اللحظي في النصوص والملاحظات', style: TextStyle(fontSize: 12)),
              onTap: () => _rebuildIndex(context, ref),
            ),
          ]),

          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Text(
              'تذكير أمان: بما أن التطبيق يحترم خصوصيتك ولا يرفع بياناتك لأي سيرفر، تأكد دائماً من تصدير نسخة احتياطية دورية للاحتفاظ بمهامك وملاحظاتك عند تبديل الهاتف.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
