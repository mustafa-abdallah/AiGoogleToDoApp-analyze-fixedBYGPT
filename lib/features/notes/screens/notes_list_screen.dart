import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format.dart';
import '../../../database/database.dart';
import '../../../repositories/notes_repository.dart';
import '../../../repositories/providers.dart';
import '../../library/screens/library_screen.dart';
import '../providers/notes_providers.dart';
import 'note_editor_screen.dart';

class NotesListScreen extends ConsumerWidget {
  const NotesListScreen({super.key});

  Future<void> _open(BuildContext context, String id) => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => NoteEditorScreen(noteId: id)));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(visibleNotesProvider);
    final filter = ref.watch(notesFilterProvider);
    final searching = ref.watch(notesQueryProvider).trim().isNotEmpty;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: filter.trash
          ? null
          : FloatingActionButton(
              onPressed: () async {
                final repo = ref.read(notesRepositoryProvider);
                final id = await repo.create(folderId: filter.folderId);
                if (filter.tagId != null) await repo.attachTag(id, filter.tagId!);
                if (context.mounted) await _open(context, id);
              },
              child: const Icon(Icons.add),
            ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(
                'الملاحظات',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'مخزنة محلياً',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF59E0B),
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'المكتبة والوسوم',
                icon: const Icon(Icons.grid_view_rounded),
                onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LibraryScreen())),
              ),
            ]),
            const SizedBox(height: 8),
            TextField(
              onChanged: (v) => ref.read(notesQueryProvider.notifier).state = v,
              decoration: InputDecoration(
                hintText: 'ابحث في الملاحظات…',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: scheme.surface,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none),
              ),
            ),
            if (!filter.isDefault)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: InputChip(
                  avatar: Icon(filter.trash ? Icons.delete_outline : Icons.filter_alt_outlined, size: 18),
                  label: Text(filter.label),
                  onDeleted: () =>
                      ref.read(notesFilterProvider.notifier).state = const NotesFilter(),
                ),
              ),
          ]),
        ),
        Expanded(
          child: notes.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('تعذّر تحميل الملاحظات\n$e')),
            data: (list) {
              if (list.isEmpty) {
                return Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.edit_note, size: 56, color: scheme.primary),
                  const SizedBox(height: 8),
                  Text(searching
                      ? 'لا نتائج مطابقة'
                      : filter.trash
                          ? 'سلة المحذوفات فارغة'
                          : 'لا توجد ملاحظات هنا'),
                  if (!searching && !filter.trash) const Text('اضغط + لكتابة ملاحظة'),
                ]));
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final n = list[i];
                  final repo = ref.read(notesRepositoryProvider);
                  if (filter.trash) {
                    return _NoteTile(
                      note: n,
                      onTap: () {},
                      trailing: IconButton(
                        tooltip: 'استرجاع',
                        icon: const Icon(Icons.restore),
                        onPressed: () => repo.restore(n.id),
                      ),
                    );
                  }
                  final tile = _NoteTile(note: n, onTap: () => _open(context, n.id));
                  if (searching) return tile;
                  return Dismissible(
                    key: ValueKey(n.id),
                    direction: DismissDirection.horizontal,
                    background: Container(
                      decoration: BoxDecoration(
                          color: Colors.red.withAlpha(60),
                          borderRadius: BorderRadius.circular(20)),
                      alignment: Alignment.center,
                      child: const Icon(Icons.delete_outline),
                    ),
                    onDismissed: (_) async {
                      await repo.softDelete(n.id);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context)
                        ..clearSnackBars()
                        ..showSnackBar(SnackBar(
                          content: const Text('نُقلت الملاحظة إلى المحذوفات'),
                          action: SnackBarAction(
                              label: 'تراجع', onPressed: () => repo.restore(n.id)),
                        ));
                    },
                    child: tile,
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

class _NoteTile extends StatelessWidget {
  const _NoteTile({required this.note, required this.onTap, this.trailing});
  final Note note;
  final VoidCallback onTap;
  final Widget? trailing;

  String get _preview {
    var t = note.bodyMd
        .replaceAll(RegExp(r'^#+\s*', multiLine: true), '')
        .replaceAll(RegExp(r'^>\s*', multiLine: true), '')
        .replaceAll(RegExp(r'-\s*\[[ xX]\]\s*'), '')
        .replaceAll('**', '')
        .replaceAll('`', '')
        .replaceAll('[[', '')
        .replaceAll(']]', '')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
    return t.length > 90 ? '${t.substring(0, 90)}…' : t;
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    const kAmber = Color(0xFFF59E0B);

    return Container(
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF181B26) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: dark ? const Color(0xFF282D3F) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kAmber.withAlpha(dark ? 35 : 25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.description_outlined, color: kAmber, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note.title.isEmpty ? 'بدون عنوان' : note.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_preview.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          _preview,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 12,
                            color: dark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            formatDateTime(note.updatedAt),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: dark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
