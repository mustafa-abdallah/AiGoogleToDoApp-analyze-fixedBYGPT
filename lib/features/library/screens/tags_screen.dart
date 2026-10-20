import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../repositories/notes_repository.dart';
import '../../notes/providers/notes_providers.dart';

class TagsScreen extends ConsumerWidget {
  const TagsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tags = ref.watch(tagCountsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('الوسوم')),
      body: tags.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('تعذّر تحميل الوسوم\n$e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('لا توجد وسوم بعد — أضفها من داخل أي ملاحظة'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final t = list[i];
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
                      color: const Color(0xFF10B981).withAlpha(dark ? 30 : 20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.tag_rounded, color: Color(0xFF10B981), size: 18),
                  ),
                  title: Text(t.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${t.count} ملاحظة',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                    ),
                  ),
                  onTap: () {
                    ref.read(notesFilterProvider.notifier).state =
                        NotesFilter(tagId: t.id, label: '#${t.name}');
                    Navigator.of(context).popUntil((r) => r.isFirst);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
