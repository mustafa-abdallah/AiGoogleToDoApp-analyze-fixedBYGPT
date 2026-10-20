import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format.dart';
import '../../../core/habit_schedule.dart';
import '../../../core/habit_stats.dart';
import '../../../database/database.dart';
import '../providers/habits_providers.dart';

const _dayNames = ['الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
const _dayLetters = ['ن', 'ث', 'ر', 'خ', 'ج', 'س', 'ح'];

/// إحصاءات عادة واحدة: التسلسل، نسبة الالتزام، أفضل الأيام، وخريطة السنة.
/// تراعي الجدول التاريخي (تغيير الأيام والإيقاف المؤقت) وأيام الإجازة والإنجاز الجزئي.
class HabitDetailScreen extends ConsumerWidget {
  const HabitDetailScreen({super.key, required this.habitId});
  final String habitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(habitsProvider).valueOrNull ?? const <Habit>[];
    final logs = ref.watch(habitLogsProvider).valueOrNull ?? const <HabitLog>[];
    final schedules =
        ref.watch(habitSchedulesProvider).valueOrNull ?? const <String, List<HabitSchedule>>{};

    Habit? habit;
    for (final h in habits) {
      if (h.id == habitId) habit = h;
    }
    if (habit == null) {
      return Scaffold(
          appBar: AppBar(), body: const Center(child: Text('العادة غير موجودة')));
    }

    final spans = spansOf(schedules[habitId]);
    final days = habitDaysFor(logs.where((l) => l.habitId == habitId), habit.targetValue);
    final now = DateTime.now();
    final stats = computeHabitStats(days.done, now,
        since: habit.createdAt,
        windowDays: habitLogWindowDays,
        scheduledOn: (d) => scheduledOnDate(spans, d),
        excused: days.excused,
        partial: days.partial);

    final paused = habit.pausedAt != null;
    final mask = currentMaskOf(spans);
    final unit = habit.unit ?? '';
    final goal = habit.kind == 'check'
        ? 'عادة نعم/لا'
        : 'الهدف اليومي: ${formatNumber(habit.targetValue)} $unit'.trim();
    final from30 = formatDate(DateTime(now.year, now.month, now.day - 29));
    final total30 = days.values.entries
        .where((e) => e.key.compareTo(from30) >= 0)
        .fold<double>(0, (a, e) => a + e.value);

    return Scaffold(
      appBar: AppBar(title: Text(habit.name)),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 32), children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF181B26)
                : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF282D3F)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(
                  goal,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              if (paused)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.amber.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.pause_circle_outline, size: 14, color: Colors.amber),
                      SizedBox(width: 4),
                      Text('متوقفة مؤقتاً', style: TextStyle(fontSize: 10, color: Colors.amber)),
                    ],
                  ),
                ),
            ]),
            const SizedBox(height: 10),
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (var i = 0; i < 7; i++)
                if (mask & (1 << i) != 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF97316).withAlpha(30),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _dayNames[i],
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF97316),
                      ),
                    ),
                  ),
            ]),
          ]),
        ),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _Stat('${stats.currentStreak}', 'التسلسل الحالي', Icons.local_fire_department)),
          const SizedBox(width: 10),
          Expanded(child: _Stat('${stats.bestStreak}', 'أفضل تسلسل', Icons.emoji_events_outlined)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _Stat(_pct(stats.rate30), 'آخر 30 يومًا', Icons.calendar_month_outlined)),
          const SizedBox(width: 10),
          Expanded(child: _Stat(_pct(stats.rateAll), 'منذ البداية', Icons.insights_outlined)),
        ]),
        if (habit.kind != 'check') ...[
          const SizedBox(height: 10),
          _Stat('${formatNumber(total30)} $unit'.trim(), 'إجمالي آخر 30 يومًا', Icons.functions),
        ],
        const SizedBox(height: 20),
        Text('أفضل الأيام', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _WeekdayBars(counts: stats.weekdayDone),
        const SizedBox(height: 20),
        Text('آخر سنة', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _YearHeatmap(
            done: days.done,
            partial: days.partial.keys.toSet(),
            excused: days.excused,
            today: now),
        const SizedBox(height: 8),
        Text('${stats.doneInWindow} يوم إنجاز في آخر سنة',
            style: Theme.of(context).textTheme.bodySmall),
      ]),
    );
  }

  static String _pct(double r) => '${(r * 100).round()}%';
}

class _Stat extends StatelessWidget {
  const _Stat(this.value, this.label, this.icon);
  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    const kAmber = Color(0xFFF59E0B);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF181B26) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: dark ? const Color(0xFF282D3F) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: kAmber.withAlpha(dark ? 30 : 20),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: kAmber, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            Text(label,
                style: TextStyle(
                  fontSize: 10,
                  color: dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                )),
          ]),
        ),
      ]),
    );
  }
}

class _WeekdayBars extends StatelessWidget {
  const _WeekdayBars({required this.counts});
  final List<int> counts;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final max = counts.fold<int>(0, (a, b) => b > a ? b : a);
    final bestIdx = max == 0 ? -1 : counts.indexOf(max);
    const maxH = 90.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 12),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF181B26) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: dark ? const Color(0xFF282D3F) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Column(children: [
        SizedBox(
          height: maxH + 20,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < 7; i++)
                Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                  Text('${counts[i]}', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 2),
                  Container(
                    width: 24,
                    height: max == 0 ? 4 : 4 + (maxH - 4) * counts[i] / max,
                    decoration: BoxDecoration(
                      color: i == bestIdx ? scheme.primary : scheme.primary.withAlpha(90),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ]),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          for (final l in _dayLetters)
            SizedBox(
                width: 24,
                child: Text(l,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall)),
        ]),
        if (bestIdx >= 0)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text('أكثر يوم تلتزم فيه: ${_dayNames[bestIdx]}',
                style: Theme.of(context).textTheme.bodySmall),
          ),
      ]),
    );
  }
}

/// خريطة حرارية: عمود لكل أسبوع (الأحدث عند الحافة الأولى)، وصف لكل يوم.
/// منجز = لون كامل، جزئي = لون خفيف، إجازة = لون ثانوي.
class _YearHeatmap extends StatelessWidget {
  const _YearHeatmap({
    required this.done,
    required this.partial,
    required this.excused,
    required this.today,
  });
  final Set<String> done;
  final Set<String> partial;
  final Set<String> excused;
  final DateTime today;

  static const _weeks = 53;
  static const _cell = 14.0;

  @override
  Widget build(BuildContext context) {
    final t = DateTime(today.year, today.month, today.day);
    final thisWeekStart = DateTime(t.year, t.month, t.day - (t.weekday - 1));

    Color colorOf(String key) {
      if (done.contains(key)) return scheme.primary;
      if (excused.contains(key)) return scheme.secondary.withAlpha(90);
      if (partial.contains(key)) return scheme.primary.withAlpha(110);
      return scheme.onSurface.withAlpha(25);
    }

    Widget cell(DateTime d) {
      final future = d.isAfter(t);
      return Container(
        width: _cell,
        height: _cell,
        margin: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          color: future ? Colors.transparent : colorOf(formatDate(d)),
        ),
      );
    }

    Widget legend(Color c, String label) => Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ]);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: scheme.surface, borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            for (var w = 0; w < _weeks; w++)
              Column(children: [
                for (var d = 0; d < 7; d++)
                  cell(DateTime(thisWeekStart.year, thisWeekStart.month,
                      thisWeekStart.day - 7 * w + d)),
              ]),
          ]),
        ),
        const SizedBox(height: 8),
        Wrap(spacing: 14, children: [
          legend(scheme.primary, 'منجز'),
          legend(scheme.primary.withAlpha(110), 'جزئي'),
          legend(scheme.secondary.withAlpha(90), 'إجازة'),
        ]),
      ]),
    );
  }
}
