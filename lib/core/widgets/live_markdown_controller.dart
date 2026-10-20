import 'package:flutter/material.dart';

/// وحدة تحكم مخصصة للمحرر الحي الذكي (Live In-Place Markdown)
/// تقوم بتنسيق العناوين والخط العريض والرموز فورياً داخل TextField
/// مع كشف ذكي لاتجاه النصوص العربية وثنائية اللغة (RTL/BiDi).
class LiveMarkdownTextEditingController extends TextEditingController {
  LiveMarkdownTextEditingController({super.text});

  TextDirection direction = TextDirection.rtl;

  void toggleDirection() {
    direction = direction == TextDirection.rtl ? TextDirection.ltr : TextDirection.rtl;
    notifyListeners();
  }

  /// كشف اتجاه أول حرف قوي (عربي أم لاتيني)
  static TextDirection detectDirection(String text) {
    final arabicRegex = RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]');
    final latinRegex = RegExp(r'[a-zA-Z]');
    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      if (arabicRegex.hasMatch(char)) return TextDirection.rtl;
      if (latinRegex.hasMatch(char)) return TextDirection.ltr;
    }
    return TextDirection.rtl;
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final List<TextSpan> spans = [];
    final lines = text.split('\n');
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final isLastLine = i == lines.length - 1;
      final suffix = isLastLine ? '' : '\n';

      // 1. عناوين H1
      if (line.startsWith('# ')) {
        spans.add(TextSpan(
          text: '# ',
          style: (style ?? const TextStyle()).copyWith(
            color: colorScheme.primary.withValues(alpha: 0.5),
            fontWeight: FontWeight.bold,
          ),
        ));
        spans.add(TextSpan(
          text: '${line.substring(2)}$suffix',
          style: (style ?? const TextStyle()).copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: colorScheme.onSurface,
          ),
        ));
        continue;
      }

      // 2. عناوين H2
      if (line.startsWith('## ')) {
        spans.add(TextSpan(
          text: '## ',
          style: (style ?? const TextStyle()).copyWith(
            color: colorScheme.primary.withValues(alpha: 0.5),
            fontWeight: FontWeight.bold,
          ),
        ));
        spans.add(TextSpan(
          text: '${line.substring(3)}$suffix',
          style: (style ?? const TextStyle()).copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ));
        continue;
      }

      // 3. عناوين H3
      if (line.startsWith('### ')) {
        spans.add(TextSpan(
          text: '### ',
          style: (style ?? const TextStyle()).copyWith(
            color: colorScheme.primary.withValues(alpha: 0.5),
            fontWeight: FontWeight.bold,
          ),
        ));
        spans.add(TextSpan(
          text: '${line.substring(4)}$suffix',
          style: (style ?? const TextStyle()).copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ));
        continue;
      }

      // 4. مربعات المهام (- [ ] و - [x])
      if (line.startsWith('- [ ] ') || line.startsWith('- [x] ')) {
        final isChecked = line.startsWith('- [x] ');
        spans.add(TextSpan(
          text: isChecked ? '- [x] ' : '- [ ] ',
          style: TextStyle(
            color: isChecked ? Colors.green : Colors.amber.shade700,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ));
        spans.add(TextSpan(
          text: '${line.substring(6)}$suffix',
          style: (style ?? const TextStyle()).copyWith(
            decoration: isChecked ? TextDecoration.lineThrough : null,
            color: isChecked ? theme.hintColor : colorScheme.onSurface,
          ),
        ));
        continue;
      }

      // 5. الاقتباسات (> أو > )
      if (line.startsWith('>')) {
        final hasSpace = line.startsWith('> ');
        final content = hasSpace ? line.substring(2) : line.substring(1);
        final dark = colorScheme.brightness == Brightness.dark;
        spans.add(const TextSpan(
          text: '▍ ',
          style: TextStyle(
            color: Color(0xFFF59E0B),
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ));
        spans.add(_parseInlineSpans(
          '$content$suffix',
          (style ?? const TextStyle()).copyWith(
            fontWeight: FontWeight.w600,
            color: dark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
          ),
          colorScheme,
        ));
        continue;
      }

      // 6. معالجة النصوص العادية والوسوم المضمنة (**عريض**، [[ويكي]])
      spans.add(_parseInlineSpans(line + suffix, style, colorScheme));
    }

    return TextSpan(style: style, children: spans);
  }

  TextSpan _parseInlineSpans(String line, TextStyle? baseStyle, ColorScheme colorScheme) {
    final List<TextSpan> children = [];
    final pattern = RegExp(r'(\*\*.*?\*\*|\[\[.*?\]\]|`.*?`)');
    int lastIndex = 0;

    for (final match in pattern.allMatches(line)) {
      if (match.start > lastIndex) {
        children.add(TextSpan(
          text: line.substring(lastIndex, match.start),
          style: baseStyle,
        ));
      }

      final token = match.group(0)!;
      if (token.startsWith('**') && token.endsWith('**')) {
        children.add(TextSpan(
          text: token,
          style: (baseStyle ?? const TextStyle()).copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ));
      } else if (token.startsWith('[[') && token.endsWith(']]')) {
        children.add(TextSpan(
          text: token,
          style: TextStyle(
            color: colorScheme.primary,
            fontWeight: FontWeight.w600,
            backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
          ),
        ));
      } else if (token.startsWith('`') && token.endsWith('`')) {
        children.add(TextSpan(
          text: token,
          style: const TextStyle(
            fontFamily: 'monospace',
            backgroundColor: Color(0x15000000),
          ),
        ));
      }
      lastIndex = match.end;
    }

    if (lastIndex < line.length) {
      children.add(TextSpan(text: line.substring(lastIndex), style: baseStyle));
    }

    return TextSpan(children: children);
  }
}
