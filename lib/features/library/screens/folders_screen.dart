import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/prompt.dart';
import '../../../database/database.dart';
import '../../../repositories/notes_repository.dart';
import '../../../repositories/providers.dart';
import '../../notes/providers/notes_providers.dart';

/// تصفّح المجلدات المتداخلة؛ كل مستوى يعرض مجلداته الفرعية.
class FoldersScreen extends ConsumerWidget {
  const FoldersScreen({super.key, this.folder});
  final Folder? folder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final children = ref.watch(folderChildrenProvider(folder?.id));
    final repo = ref.read(foldersRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: Text(folder?.name ?? 'المجلدات')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final name = await promptText(context,
              title: folder == null ? 'مجلد جديد' : 'مجلد فرعي جديد', hint: 'اسم المجلد');
          if (name != null) await repo.create(name, parentId: folder?.id);
        },
        child: const Icon(Icons.create_new_folder_outlined),
      ),
      body: Column(children: [
        if (folder != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                icon: const Icon(Icons.description_outlined),
                label: const Text('عرض ملاحظات هذا المجلد'),
                onPressed: () {
                  ref.read(notesFilterProvider.notifier).state =
                      NotesFilter(folderId: folder!.id, label: folder!.name);
                  Navigator.of(context).popUntil((r) => r.isFirst);
                },
              ),
            ),
          ),
        Expanded(
          child: children.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('تعذّر تحميل المجلدات\n$e')),
            data: (list) {
              if (list.isEmpty) {
                return Center(
                    child: Text(folder == null
                        ? 'لا توجد مجلدات بعد'
                        : 'لا توجد مجلدات فرعية'));
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final f = list[i];
                  final dark = Theme.of(context).brightness == Brightness.dark;
                  return Container(
                    decoration: BoxDecoration(
                      color: dark ? const Color(0xFF181B26) : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: dark ? const Color(0xFF282D3F) : const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    child: ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF38BDF8).withAlpha(dark ? 30 : 20),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.folder_rounded, color: Color(0xFF38BDF8), size: 20),
                      ),
                      title: Text(f.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => FoldersScreen(folder: f))),
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) async {
                          if (v == 'rename') {
                            final n = await promptText(context,
                                title: 'إعادة تسمية', initial: f.name);
                            if (n != null) await repo.rename(f.id, n);
                          } else if (v == 'delete') {
                            final ok = await confirm(context,
                                title: 'حذف المجلد؟',
                                message: 'ستنتقل ملاحظاته ومجلداته الفرعية إلى المجلد الأعلى.',
                                action: 'حذف');
                            if (ok) await repo.delete(f.id);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'rename', child: Text('إعادة تسمية')),
                          PopupMenuItem(value: 'delete', child: Text('حذف')),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }
}
