import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../config/theme.dart';

/// Terminal-style code block widget with language label, line numbers, and copy button
class CodeBlockView extends StatelessWidget {
  final String code;
  final String? language;
  const CodeBlockView({super.key, required this.code, this.language});

  @override
  Widget build(BuildContext context) {
    final lines = code.split('\n');
    final lineCount = lines.length;
    final gutterWidth = lineCount > 99 ? 40.0 : lineCount > 9 ? 32.0 : 24.0;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF21262D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Terminal header bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: const BoxDecoration(
              color: Color(0xFF161B22),
              borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
              border: Border(bottom: BorderSide(color: Color(0xFF21262D))),
            ),
            child: Row(
              children: [
                // Terminal dots
                Row(children: [
                  _dot(const Color(0xFFFF5F56)),
                  const SizedBox(width: 6),
                  _dot(const Color(0xFFFFBD2E)),
                  const SizedBox(width: 6),
                  _dot(const Color(0xFF27C93F)),
                ]),
                const SizedBox(width: 12),
                if (language != null && language!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _langColor(language!).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      language!.toUpperCase(),
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: _langColor(language!), letterSpacing: 0.5),
                    ),
                  ),
                const Spacer(),
                Text('${lines.length} lines', style: const TextStyle(fontSize: 9, color: Color(0xFF484F58))),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied!'), duration: Duration(seconds: 1), behavior: SnackBarBehavior.floating),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: const Color(0xFF21262D), borderRadius: BorderRadius.circular(4)),
                    child: const Icon(Icons.copy_rounded, size: 12, color: Color(0xFF8B949E)),
                  ),
                ),
              ],
            ),
          ),
          // Code body with line numbers
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: lines.length > 20 ? 400 : double.infinity),
            child: SingleChildScrollView(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: IntrinsicWidth(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: List.generate(lines.length, (i) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Line number gutter
                          Container(
                            width: gutterWidth,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                            alignment: Alignment.centerRight,
                            color: const Color(0xFF0D1117),
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Color(0xFF484F58), height: 1.55),
                            ),
                          ),
                          Container(width: 1, color: const Color(0xFF21262D)),
                          // Code line
                          Flexible(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
                              child: Text(
                                lines[i].isEmpty ? ' ' : lines[i],
                                style: TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                  color: _syntaxColor(lines[i]),
                                  height: 1.55,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _dot(Color c) => Container(width: 10, height: 10, decoration: BoxDecoration(color: c, shape: BoxShape.circle));

  Color _langColor(String lang) {
    switch (lang.toLowerCase()) {
      case 'dart': return const Color(0xFF00B4AB);
      case 'js': case 'javascript': case 'jsx': return const Color(0xFFF7DF1E);
      case 'ts': case 'typescript': case 'tsx': return const Color(0xFF3178C6);
      case 'html': return const Color(0xFFE34F26);
      case 'css': case 'scss': return const Color(0xFF563D7C);
      case 'py': case 'python': return const Color(0xFF3776AB);
      case 'java': return const Color(0xFFB07219);
      case 'kotlin': return const Color(0xFFA97BFF);
      case 'swift': return const Color(0xFFFA7343);
      case 'json': return const Color(0xFF5B5EA6);
      case 'yaml': case 'yml': return const Color(0xFFCB171E);
      case 'xml': return const Color(0xFF0060AC);
      case 'sql': return const Color(0xFFE38C00);
      case 'sh': case 'bash': case 'shell': return const Color(0xFF89E051);
      case 'md': case 'markdown': return const Color(0xFF083FA1);
      case 'go': return const Color(0xFF00ADD8);
      case 'rust': case 'rs': return const Color(0xFFDEA584);
      case 'cpp': case 'c++': case 'c': return const Color(0xFF00599C);
      case 'ruby': case 'rb': return const Color(0xFFCC342D);
      case 'php': return const Color(0xFF777BB4);
      default: return const Color(0xFF8B949E);
    }
  }

  /// Basic syntax coloring based on line content
  Color _syntaxColor(String line) {
    final trimmed = line.trimLeft();
    if (trimmed.startsWith('//') || trimmed.startsWith('#') || trimmed.startsWith('<!--')) return const Color(0xFF6A737D);
    if (trimmed.startsWith('import ') || trimmed.startsWith('from ') || trimmed.startsWith('export ')) return const Color(0xFFFF7B72);
    if (trimmed.startsWith('class ') || trimmed.startsWith('interface ') || trimmed.startsWith('enum ')) return const Color(0xFFFFA657);
    if (trimmed.startsWith('func') || trimmed.startsWith('def ') || trimmed.startsWith('void ') || trimmed.startsWith('async ')) return const Color(0xFFD2A8FF);
    if (trimmed.startsWith('return ') || trimmed.startsWith('if ') || trimmed.startsWith('else') || trimmed.startsWith('for ') || trimmed.startsWith('while ')) return const Color(0xFFFF7B72);
    if (trimmed.startsWith('<') && trimmed.contains('>')) return const Color(0xFF7EE787);
    if (trimmed.startsWith('@')) return const Color(0xFFFFA657);
    return const Color(0xFFE6EDF3);
  }
}

/// Inline code span widget
class InlineCodeSpan extends StatelessWidget {
  final String code;
  const InlineCodeSpan({super.key, required this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF21262D)),
      ),
      child: Text(code, style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: Color(0xFFE6EDF3))),
    );
  }
}

/// Custom Markdown renderer that integrates CodeBlockView for fenced code
class AiMarkdownBody extends StatelessWidget {
  final String content;
  const AiMarkdownBody({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    // Parse content and build widgets for code blocks and markdown text
    final widgets = _parseContent(context, content);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  List<Widget> _parseContent(BuildContext context, String text) {
    final List<Widget> result = [];
    // Match fenced code blocks: ```lang\ncode\n```
    final codeBlockRegex = RegExp(r'```(\w*)\n([\s\S]*?)```', multiLine: true);
    int lastEnd = 0;

    for (final match in codeBlockRegex.allMatches(text)) {
      // Add markdown text before this code block
      if (match.start > lastEnd) {
        final mdText = text.substring(lastEnd, match.start).trim();
        if (mdText.isNotEmpty) {
          result.add(_buildMarkdownSection(context, mdText));
        }
      }
      // Add code block
      final lang = match.group(1) ?? '';
      final code = match.group(2) ?? '';
      result.add(CodeBlockView(code: code.trimRight(), language: lang.isNotEmpty ? lang : null));
      lastEnd = match.end;
    }

    // Add remaining markdown text
    if (lastEnd < text.length) {
      final mdText = text.substring(lastEnd).trim();
      if (mdText.isNotEmpty) {
        result.add(_buildMarkdownSection(context, mdText));
      }
    }

    // If nothing parsed (no code blocks), render entire text as markdown
    if (result.isEmpty) {
      result.add(_buildMarkdownSection(context, text));
    }

    return result;
  }

  Widget _buildMarkdownSection(BuildContext context, String mdText) {
    return MarkdownBody(
      data: mdText,
      selectable: true,
      shrinkWrap: true,
      styleSheet: MarkdownStyleSheet(
        p: const TextStyle(fontSize: 14, height: 1.5, color: AppColors.darkText),
        h1: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.darkText),
        h2: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkText),
        h3: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.darkText),
        h4: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.darkText),
        strong: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.darkText),
        em: const TextStyle(fontStyle: FontStyle.italic, color: AppColors.darkTextSecondary),
        code: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: Color(0xFFE6EDF3), backgroundColor: Color(0xFF161B22)),
        codeblockDecoration: BoxDecoration(
          color: const Color(0xFF0D1117),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF21262D)),
        ),
        codeblockPadding: const EdgeInsets.all(12),
        blockquoteDecoration: BoxDecoration(
          border: Border(left: BorderSide(color: AppColors.primary.withValues(alpha: 0.5), width: 3)),
        ),
        blockquotePadding: const EdgeInsets.only(left: 12, top: 4, bottom: 4),
        listBullet: const TextStyle(fontSize: 14, color: AppColors.accent),
        tableHead: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.darkText),
        tableBody: const TextStyle(fontSize: 13, color: AppColors.darkTextSecondary),
        tableBorder: TableBorder.all(color: AppColors.darkBorder, width: 0.5),
        tableHeadAlign: TextAlign.left,
        tableCellsPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        horizontalRuleDecoration: BoxDecoration(border: Border(top: BorderSide(color: AppColors.darkBorder.withValues(alpha: 0.5)))),
        a: const TextStyle(color: AppColors.accent, decoration: TextDecoration.underline),
      ),
    );
  }
}
