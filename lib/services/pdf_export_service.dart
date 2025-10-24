import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../domains/chat/entity/chat_message.dart';

/// Helper to sanitize text for PDF (remove unsupported Unicode characters)
String _sanitizeForPdf(String text) {
  // Replace common medical/scientific Unicode characters with ASCII equivalents
  return text
      .replaceAll('β', 'beta')
      .replaceAll('α', 'alpha')
      .replaceAll('γ', 'gamma')
      .replaceAll('δ', 'delta')
      .replaceAll('μ', 'mu')
      .replaceAll('°', ' degrees')
      .replaceAll('±', '+/-')
      .replaceAll('≥', '>=')
      .replaceAll('≤', '<=')
      .replaceAll('→', '->')
      .replaceAll('←', '<-')
      .replaceAll('•', '*')
      .replaceAll('–', '-')
      .replaceAll('—', '--')
      .replaceAll(''', "'")
      .replaceAll(''', "'")
      .replaceAll('"', '"')
      .replaceAll('"', '"')
      // Remove any remaining non-ASCII characters that might cause issues
      .replaceAll(RegExp(r'[^\x00-\x7F]'), '');
}

/// Service for exporting conversations to PDF
class PdfExportService {
  /// Export a conversation to PDF format (with proper multi-page handling)
  ///
  /// [conversationTitle] - Title of the conversation (usually the query)
  /// [messages] - List of chat messages to export
  /// [selectedPapers] - Optional list of PMIDs that were selected during chat
  ///
  /// Returns the PDF as bytes
  static Future<Uint8List> exportConversation({
    required String conversationTitle,
    required List<ChatMessage> messages,
    List<String>? selectedPapers,
  }) async {
    try {
      debugPrint('📄 [PDF] Starting export for: $conversationTitle');
      debugPrint('📄 [PDF] Messages count: ${messages.length}');

      final pdf = pw.Document();

      // Build all messages first
      debugPrint('📄 [PDF] Building message widgets...');
      final messageWidgets = _buildMessages(messages);
      debugPrint('📄 [PDF] Built ${messageWidgets.length} widgets');

      // Add first page with header, metadata, and start of messages
      debugPrint('📄 [PDF] Adding MultiPage...');
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(
            25,
          ), // Reduced from 40 to 25 for more space
          maxPages: 100, // Increase page limit from default 20 to 100
          header: (context) {
            debugPrint('📄 [PDF] Header - page: ${context.pageNumber}');
            return context.pageNumber == 1
                ? pw.SizedBox()
                : _buildPageHeader(conversationTitle);
          },
          footer: (context) {
            debugPrint(
              '📄 [PDF] Footer - page: ${context.pageNumber}, total: ${context.pagesCount}',
            );
            return _buildPageFooter(context.pageNumber, context.pagesCount);
          },
          build: (context) {
            debugPrint('📄 [PDF] Building page content...');
            return [
              // Header with metadata (only once at the start)
              _buildHeader(
                _sanitizeForPdf(conversationTitle),
                messages,
                selectedPapers,
              ),
              pw.SizedBox(height: 12), // Reduced from 20 to 12
              // Messages (no "Conversation" header to save space)
              ...messageWidgets,
            ];
          },
        ),
      );

      debugPrint('📄 [PDF] Saving document...');
      final bytes = await pdf.save();
      debugPrint('📄 [PDF] Document saved: ${bytes.length} bytes');
      return bytes;
    } catch (e, stackTrace) {
      debugPrint('❌ [PDF] Error during export: $e');
      debugPrint('❌ [PDF] Stack trace:\n$stackTrace');
      rethrow;
    }
  }

  static pw.Widget _buildHeader(
    String title,
    List<ChatMessage> messages,
    List<String>? selectedPapers,
  ) {
    final exportDate = DateTime.now();
    final messageCount = messages.length;
    final userMessages = messages.where((m) => m.isUser).length;
    final aiMessages = messages.where((m) => !m.isUser).length;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'MediCortex',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue700,
              ),
            ),
            pw.Text(
              'Research Report',
              style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
          ],
        ),
        pw.SizedBox(height: 6),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: PdfColors.blue50,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Title on the left
              pw.Expanded(
                child: pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: pw.TextOverflow.clip,
                ),
              ),
              pw.SizedBox(width: 12),
              // Metadata on the right
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Text(
                    'Exported: ${_formatDate(exportDate)}',
                    style: const pw.TextStyle(
                      fontSize: 7,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Messages: $messageCount ($userMessages Q, $aiMessages A)',
                    style: const pw.TextStyle(
                      fontSize: 7,
                      color: PdfColors.grey700,
                    ),
                  ),
                  if (selectedPapers != null && selectedPapers.isNotEmpty) ...[
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Papers: ${selectedPapers.length} PMIDs',
                      style: const pw.TextStyle(
                        fontSize: 7,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  static List<pw.Widget> _buildMessages(List<ChatMessage> messages) {
    final widgets = <pw.Widget>[];

    for (int i = 0; i < messages.length; i++) {
      final message = messages[i];
      final displayText = _sanitizeForPdf(message.text);

      // Wrap header and content together to prevent page breaks between them
      widgets.add(
        pw.Column(
          crossAxisAlignment:
              message.isUser
                  ? pw.CrossAxisAlignment.end
                  : pw.CrossAxisAlignment.start,
          children: [
            // Message header
            pw.Row(
              mainAxisAlignment:
                  message.isUser
                      ? pw.MainAxisAlignment.end
                      : pw.MainAxisAlignment.start,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: pw.BoxDecoration(
                    color:
                        message.isUser ? PdfColors.blue100 : PdfColors.grey200,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    message.isUser ? 'YOU' : 'AI ASSISTANT',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color:
                          message.isUser
                              ? PdfColors.blue800
                              : PdfColors.grey800,
                    ),
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Text(
                  _formatTimestamp(message.timestamp),
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey500,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 6),
            // Message content with markdown support
            ..._buildMarkdownParagraphs(displayText, message.isUser),
          ],
        ),
      );

      widgets.add(pw.SizedBox(height: 15));
    }

    return widgets;
  }

  /// Build markdown paragraphs as separate Text widgets to prevent pagination issues
  static List<pw.Widget> _buildMarkdownParagraphs(String text, bool isUser) {
    final widgets = <pw.Widget>[];
    final lines = text.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      // Skip empty lines
      if (line.trim().isEmpty) {
        widgets.add(pw.SizedBox(height: 4));
        continue;
      }

      // Check if this line starts a table
      if (line.trim().contains('|') && i + 1 < lines.length) {
        final nextLine = lines[i + 1];
        // If next line is a separator (|---|---|), it's a table
        if (nextLine.contains('|') && nextLine.contains('-')) {
          // Parse the table
          final tableResult = _parseMarkdownTable(lines, i);
          if (tableResult != null) {
            widgets.add(tableResult['widget'] as pw.Widget);
            widgets.add(pw.SizedBox(height: 8));
            i = tableResult['lastIndex'] as int; // Skip the lines we've processed
            continue;
          }
        }
      }

      // Handle headers (# Header, ## Header, etc.)
      if (line.startsWith('###')) {
        widgets.add(
          pw.Text(
            line.substring(3).trim(),
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
            textAlign: isUser ? pw.TextAlign.right : pw.TextAlign.left,
          ),
        );
        widgets.add(pw.SizedBox(height: 4));
      } else if (line.startsWith('##')) {
        widgets.add(
          pw.Text(
            line.substring(2).trim(),
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            textAlign: isUser ? pw.TextAlign.right : pw.TextAlign.left,
          ),
        );
        widgets.add(pw.SizedBox(height: 4));
      } else if (line.startsWith('#')) {
        widgets.add(
          pw.Text(
            line.substring(1).trim(),
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
            textAlign: isUser ? pw.TextAlign.right : pw.TextAlign.left,
          ),
        );
        widgets.add(pw.SizedBox(height: 4));
      }
      // Handle bullet points
      else if (line.trim().startsWith('- ') || line.trim().startsWith('* ')) {
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 12),
            child: _buildTextWithInlineFormatting(
              '- ${line.trim().substring(2)}',
              isUser,
              10,
            ),
          ),
        );
      }
      // Handle numbered lists
      else if (RegExp(r'^\d+\.').hasMatch(line.trim())) {
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 12),
            child: _buildTextWithInlineFormatting(line.trim(), isUser, 10),
          ),
        );
      }
      // Regular text with inline formatting
      else {
        widgets.add(_buildTextWithInlineFormatting(line, isUser, 10));
      }
    }

    return widgets;
  }

  /// Parse a markdown table and return a PDF Table widget
  static Map<String, dynamic>? _parseMarkdownTable(
    List<String> lines,
    int startIndex,
  ) {
    if (startIndex >= lines.length - 1) return null;

    final headerLine = lines[startIndex];
    final separatorLine = lines[startIndex + 1];

    // Verify it's a valid table
    if (!headerLine.contains('|') || !separatorLine.contains('|')) {
      return null;
    }

    // Parse header
    final headers = headerLine
        .split('|')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (headers.isEmpty) return null;

    // Parse data rows
    final dataRows = <List<String>>[];
    int currentIndex = startIndex + 2; // Skip header and separator

    while (currentIndex < lines.length) {
      final line = lines[currentIndex];
      if (!line.trim().contains('|')) break; // End of table

      final cells = line
          .split('|')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      if (cells.length == headers.length) {
        dataRows.add(cells);
      }

      currentIndex++;
    }

    // Build PDF table
    final table = pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      columnWidths: {
        for (int i = 0; i < headers.length; i++)
          i: const pw.FlexColumnWidth(),
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue50),
          children: headers
              .map(
                (header) => pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(
                    header,
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 9,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              )
              .toList(),
        ),
        // Data rows
        ...dataRows.map(
          (row) => pw.TableRow(
            children: row
                .map(
                  (cell) => pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(
                      _stripMarkdown(cell),
                      style: const pw.TextStyle(fontSize: 9),
                      textAlign: pw.TextAlign.left,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );

    return {
      'widget': table,
      'lastIndex': currentIndex - 1, // Last line that was part of the table
    };
  }

  /// Build text with inline formatting (bold, italic) using RichText for a single line
  static pw.Widget _buildTextWithInlineFormatting(
    String text,
    bool isUser,
    double fontSize,
  ) {
    final spans = <pw.InlineSpan>[];

    // Combined regex to match bold, italic, code, and links in order
    final regex = RegExp(
      r'\*\*(.+?)\*\*|' // Bold **text**
      r'\*(.+?)\*|' // Italic *text*
      r'`(.+?)`|' // Code `text`
      r'\[([^\]]+)\]\(([^)]+)\)', // Links [text](url)
    );

    int lastIndex = 0;
    for (final match in regex.allMatches(text)) {
      // Add text before match
      if (match.start > lastIndex) {
        spans.add(pw.TextSpan(text: text.substring(lastIndex, match.start)));
      }

      // Bold text **text**
      if (match.group(1) != null) {
        spans.add(
          pw.TextSpan(
            text: match.group(1),
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        );
      }
      // Italic text *text*
      else if (match.group(2) != null) {
        spans.add(
          pw.TextSpan(
            text: match.group(2),
            style: pw.TextStyle(fontStyle: pw.FontStyle.italic),
          ),
        );
      }
      // Code text `text`
      else if (match.group(3) != null) {
        spans.add(
          pw.TextSpan(
            text: match.group(3),
            style: pw.TextStyle(
              font: pw.Font.courier(),
              fontSize: fontSize - 1,
              color: PdfColors.blue900,
            ),
          ),
        );
      }
      // Links [text](url)
      else if (match.group(4) != null && match.group(5) != null) {
        spans.add(
          pw.TextSpan(
            text: '${match.group(4)} (${match.group(5)})',
            style: pw.TextStyle(
              color: PdfColors.blue700,
              decoration: pw.TextDecoration.underline,
            ),
          ),
        );
      }

      lastIndex = match.end;
    }

    // Add remaining text after last match
    if (lastIndex < text.length) {
      spans.add(pw.TextSpan(text: text.substring(lastIndex)));
    }

    // If no markdown found, just return plain text
    if (spans.isEmpty) {
      return pw.Text(
        text,
        style: pw.TextStyle(fontSize: fontSize),
        textAlign: isUser ? pw.TextAlign.right : pw.TextAlign.left,
      );
    }

    // Return RichText with formatted spans
    return pw.RichText(
      text: pw.TextSpan(
        children: spans,
        style: pw.TextStyle(fontSize: fontSize),
      ),
      textAlign: isUser ? pw.TextAlign.right : pw.TextAlign.left,
    );
  }

  /// Strip markdown formatting for plain text display
  static String _stripMarkdown(String text) {
    // Replace bold **text**
    text = text.replaceAllMapped(
      RegExp(r'\*\*(.+?)\*\*'),
      (match) => match.group(1) ?? '',
    );
    // Replace italic *text*
    text = text.replaceAllMapped(
      RegExp(r'\*(.+?)\*'),
      (match) => match.group(1) ?? '',
    );
    // Replace code `text`
    text = text.replaceAllMapped(
      RegExp(r'`(.+?)`'),
      (match) => match.group(1) ?? '',
    );
    // Replace links [text](url) with text (url)
    text = text.replaceAllMapped(
      RegExp(r'\[([^\]]+)\]\(([^)]+)\)'),
      (match) => '${match.group(1)} (${match.group(2)})',
    );
    return text;
  }

  static String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  static String _formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final hour =
        date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  static pw.Widget _buildPageHeader(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'MediCortex',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue700,
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              _sanitizeForPdf(title),
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
              textAlign: pw.TextAlign.right,
              maxLines: 1,
              overflow: pw.TextOverflow.clip,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPageFooter(int pageNumber, int? totalPages) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generated by MediCortex',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
          pw.Text(
            totalPages != null
                ? 'Page $pageNumber of $totalPages'
                : 'Page $pageNumber',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  /// Save and download the PDF (for web and mobile)
  static Future<void> saveAndDownload({
    required String conversationTitle,
    required List<ChatMessage> messages,
    List<String>? selectedPapers,
  }) async {
    final pdfBytes = await exportConversation(
      conversationTitle: conversationTitle,
      messages: messages,
      selectedPapers: selectedPapers,
    );

    // Use printing package to handle save/share across platforms
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'medicortex_${_sanitizeFilename(conversationTitle)}.pdf',
    );
  }

  static String _sanitizeFilename(String filename) {
    return filename
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase()
        .substring(0, filename.length > 50 ? 50 : filename.length);
  }
}
