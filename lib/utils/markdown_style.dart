import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

MarkdownStyleSheet getMarkDownStyle(BuildContext context) {
  final textTheme = Theme.of(context).textTheme;
  final isDark = Theme.of(context).brightness == Brightness.dark;

  // Define colors based on theme
  final primaryTextColor = isDark ? Colors.white : Colors.black87;
  final secondaryTextColor = isDark ? Colors.white70 : Colors.black54;
  final accentColor = Theme.of(context).primaryColor;
  final codeBackgroundColor =
      isDark ? const Color(0xFF2D3748) : const Color(0xFFF7FAFC);
  final blockquoteBackgroundColor =
      isDark ? const Color(0xFF1A202C) : const Color(0xFFF0F4F8);
  final borderColor = isDark ? Colors.white24 : Colors.black12;

  return MarkdownStyleSheet(
    // Headers with proper hierarchy and spacing
    h1:
        textTheme.headlineLarge?.copyWith(
          color: primaryTextColor,
          fontWeight: FontWeight.bold,
          fontSize: 28,
          height: 1.3,
        ) ??
        TextStyle(
          color: primaryTextColor,
          fontWeight: FontWeight.bold,
          fontSize: 28,
          height: 1.3,
        ),

    h2:
        textTheme.headlineMedium?.copyWith(
          color: primaryTextColor,
          fontWeight: FontWeight.bold,
          fontSize: 24,
          height: 1.35,
        ) ??
        TextStyle(
          color: primaryTextColor,
          fontWeight: FontWeight.bold,
          fontSize: 24,
          height: 1.35,
        ),

    h3:
        textTheme.headlineSmall?.copyWith(
          color: primaryTextColor,
          fontWeight: FontWeight.w600,
          fontSize: 20,
          height: 1.4,
        ) ??
        TextStyle(
          color: primaryTextColor,
          fontWeight: FontWeight.w600,
          fontSize: 20,
          height: 1.4,
        ),

    h4:
        textTheme.titleLarge?.copyWith(
          color: primaryTextColor,
          fontWeight: FontWeight.w600,
          fontSize: 18,
          height: 1.4,
        ) ??
        TextStyle(
          color: primaryTextColor,
          fontWeight: FontWeight.w600,
          fontSize: 18,
          height: 1.4,
        ),

    h5:
        textTheme.titleMedium?.copyWith(
          color: primaryTextColor,
          fontWeight: FontWeight.w500,
          fontSize: 16,
          height: 1.4,
        ) ??
        TextStyle(
          color: primaryTextColor,
          fontWeight: FontWeight.w500,
          fontSize: 16,
          height: 1.4,
        ),

    h6:
        textTheme.titleSmall?.copyWith(
          color: secondaryTextColor,
          fontWeight: FontWeight.w500,
          fontSize: 14,
          height: 1.4,
        ) ??
        TextStyle(
          color: secondaryTextColor,
          fontWeight: FontWeight.w500,
          fontSize: 14,
          height: 1.4,
        ),

    // Body text with proper line height for readability
    p: TextStyle(
      color: primaryTextColor,
      fontSize: 16,
      height: 1.6, // Better line spacing for mobile reading
      letterSpacing: 0.2,
    ),

    // Strong and emphasis
    strong: TextStyle(color: primaryTextColor, fontWeight: FontWeight.bold),

    em: TextStyle(color: primaryTextColor, fontStyle: FontStyle.italic),

    // Lists with proper spacing
    listBullet: TextStyle(color: primaryTextColor, fontSize: 16, height: 1.5),

    listBulletPadding: const EdgeInsets.only(right: 8.0),

    // Links
    a: TextStyle(
      color: accentColor,
      fontSize: 16,
      decoration: TextDecoration.underline,
      decorationColor: accentColor.withValues(alpha: .7),
    ),

    // Inline code
    code: TextStyle(
      color: accentColor,
      backgroundColor: codeBackgroundColor,
      fontFamily: 'monospace',
      fontSize: 14,
      letterSpacing: 0.5,
    ),

    // Code blocks with better styling
    codeblockDecoration: BoxDecoration(
      color: codeBackgroundColor,
      borderRadius: const BorderRadius.all(Radius.circular(8)),
      border: Border.all(color: borderColor, width: 1),
    ),

    codeblockPadding: const EdgeInsets.all(16),

    // Blockquotes with left border accent
    blockquote: TextStyle(
      color: secondaryTextColor,
      fontStyle: FontStyle.italic,
      fontSize: 16,
      height: 1.5,
    ),

    blockquoteDecoration: BoxDecoration(
      color: blockquoteBackgroundColor,
      borderRadius: const BorderRadius.all(Radius.circular(4)),
      border: Border(left: BorderSide(color: accentColor, width: 4)),
    ),

    blockquotePadding: const EdgeInsets.fromLTRB(16, 12, 16, 12),

    // Tables
    tableHead: TextStyle(
      color: primaryTextColor,
      fontWeight: FontWeight.w600,
      fontSize: 15,
    ),

    tableBody: TextStyle(color: primaryTextColor, fontSize: 15, height: 1.4),

    tableHeadAlign: TextAlign.left,
    tableBorder: TableBorder.all(color: borderColor, width: 1),

    tableColumnWidth: const FlexColumnWidth(),
    tableCellsPadding: const EdgeInsets.all(8),
    tableCellsDecoration: BoxDecoration(
      color: isDark ? Colors.transparent : Colors.grey[50],
    ),

    // Horizontal rule
    horizontalRuleDecoration: BoxDecoration(
      border: Border(top: BorderSide(color: borderColor, width: 1)),
    ),

    // Spacing between block elements
    h1Padding: const EdgeInsets.only(top: 24, bottom: 16),
    h2Padding: const EdgeInsets.only(top: 20, bottom: 12),
    h3Padding: const EdgeInsets.only(top: 16, bottom: 8),
    h4Padding: const EdgeInsets.only(top: 12, bottom: 6),
    h5Padding: const EdgeInsets.only(top: 12, bottom: 6),
    h6Padding: const EdgeInsets.only(top: 8, bottom: 4),
    pPadding: const EdgeInsets.only(bottom: 12),
    blockSpacing: 16.0,
    listIndent: 24.0,
  );
}

// Optional: Helper method for custom syntax highlighting
MarkdownStyleSheet getMarkdownStyleWithCustomSyntax(
  BuildContext context, {
  Color? syntaxHighlightColor,
}) {
  final baseStyle = getMarkDownStyle(context);

  return baseStyle.copyWith(
    code: baseStyle.code?.copyWith(
      color: syntaxHighlightColor ?? Theme.of(context).colorScheme.secondary,
    ),
  );
}
