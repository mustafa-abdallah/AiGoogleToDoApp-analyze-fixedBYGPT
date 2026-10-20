import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../repositories/notes_repository.dart';
import '../../../repositories/providers.dart';
import '../../notes/providers/notes_providers.dart';
import 'folders_screen.dart';
import 'tags_screen.dart';

/// شاشة المكتبة والتنظيم الحديثة: الملاحظات، المجلدات، الوسوم، والمحذوفات
class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  void _setFilter(BuildContext context, WidgetRef ref, NotesFilter f) {
    ref.read(notesFilterProvider.notifier).state = f;
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final allNotes = ref.watch(notesRepositoryProvider).watch(const NotesFilter());
    final trashNotes = ref.watch(notesRepositoryProvider).watch(const NotesFilter(trash: true));
    final tagCounts = ref.watch(tagCountsProvider);
    final folders = ref.watch(folderChildrenProvider(null));

    return Scaffold(
      appBar: AppBar(
        title: const Text('المكتبة والتنظيم', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // شريط توضيحي علوي
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: dark
                    ? [const Color(0xFF1E2230), const Color(0xFF141722)]
                    : [Colors.white, const Color(0xFFFFFBEB)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: dark ? kAmber.withAlpha(50) : kAmber.withAlpha(80),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: kAmber.withAlpha(30),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.auto_stories_rounded, color: kAmber, size: 24),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'مستودع المعرفة',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'نظّم ملاحظاتك عبر المجلدات الهرمية والوسوم الحرة.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // شبكة البلاطات
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 1.15,
            children: [
              _LibraryCard(
                icon: Icons.article_rounded,
                title: 'كل الملاحظات',
                subtitle: 'عرض القائمة الكاملة',
                color: kAmber,
                countStream: allNotes.map((l) => l.length),
                onTap: () => _setFilter(context, ref, const NotesFilter()),
              ),
              _LibraryCard(
                icon: Icons.folder_copy_rounded,
                title: 'المجلدات',
                subtitle: 'تنظيم شجري هرمي',
                color: kSky,
                countStream: folders.when(
                  data: (l) => Stream.value(l.length),
                  loading: () => Stream.value(0),
                  error: (_, __) => Stream.value(0),
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FoldersScreen()),
                ),
              ),
              _LibraryCard(
                icon: Icons.tag_rounded,
                title: 'الوسوم (Tags)',
                subtitle: 'ربط حر بالمواضيع',
                color: kEmerald,
                countStream: tagCounts.when(
                  data: (l) => Stream.value(l.length),
                  loading: () => Stream.value(0),
                  error: (_, __) => Stream.value(0),
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TagsScreen()),
                ),
              ),
              _LibraryCard(
                icon: Icons.delete_outline_rounded,
                title: 'المحذوفات',
                subtitle: 'الملاحظات المؤرشفة',
                color: kRose,
                countStream: trashNotes.map((l) => l.length),
                onTap: () => _setFilter(
                  context,
                  ref,
                  const NotesFilter(trash: true, label: 'المحذوفات'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LibraryCard extends StatelessWidget {
  const _LibraryCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    required this.countStream,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final Stream<int> countStream;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

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
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withAlpha(dark ? 35 : 25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 22),
                    ),
                    StreamBuilder<int>(
                      stream: countStream,
                      builder: (context, snapshot) {
                        final count = snapshot.data ?? 0;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withAlpha(30),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$count',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 10,
                        color: dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
