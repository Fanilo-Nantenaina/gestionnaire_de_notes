import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';
import '../models/note.dart';

class PdfService {
  static Future<String?> exportNotesToPdf(List<Note> notes, {String? title}) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.only(bottom: 16),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(color: PdfColors.grey300, width: 2),
                    ),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        title ?? 'Mes Notes',
                        style: pw.TextStyle(
                          fontSize: 28,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey800,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Généré le ${_formatDate(DateTime.now())}',
                        style: pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.grey600,
                          fontStyle: pw.FontStyle.italic,
                        ),
                      ),
                      pw.Text(
                        '${notes.length} note${notes.length > 1 ? 's' : ''} exportée${notes.length > 1 ? 's' : ''}',
                        style: pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 24),

                pw.Expanded(
                  child: pw.ListView.builder(
                    itemCount: notes.length,
                    itemBuilder: (context, index) {
                      final note = notes[index];
                      return pw.Container(
                        margin: const pw.EdgeInsets.only(bottom: 20),
                        padding: const pw.EdgeInsets.all(16),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.grey50,
                          border: pw.Border.all(color: PdfColors.grey300),
                          borderRadius: pw.BorderRadius.circular(8),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Expanded(
                                  child: pw.Text(
                                    note.title.isEmpty ? 'Sans titre' : note.title,
                                    style: pw.TextStyle(
                                      fontSize: 18,
                                      fontWeight: pw.FontWeight.bold,
                                      color: PdfColors.grey800,
                                    ),
                                  ),
                                ),
                                if (note.isFavorite)
                                  pw.Container(
                                    padding: const pw.EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: pw.BoxDecoration(
                                      color: PdfColors.amber100,
                                      borderRadius: pw.BorderRadius.circular(12),
                                    ),
                                    child: pw.Text(
                                      '⭐ Favori',
                                      style: pw.TextStyle(
                                        fontSize: 10,
                                        color: PdfColors.amber800,
                                        fontWeight: pw.FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),

                            pw.SizedBox(height: 12),

                            pw.Row(
                              children: [
                                pw.Container(
                                  padding: const pw.EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: pw.BoxDecoration(
                                    color: PdfColors.blue100,
                                    borderRadius: pw.BorderRadius.circular(4),
                                  ),
                                  child: pw.Text(
                                    note.category,
                                    style: pw.TextStyle(
                                      fontSize: 10,
                                      color: PdfColors.blue800,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                ),
                                pw.SizedBox(width: 12),
                                pw.Text(
                                  'Modifié le ${_formatDate(note.updatedAt)}',
                                  style: pw.TextStyle(
                                    fontSize: 10,
                                    color: PdfColors.grey600,
                                  ),
                                ),
                              ],
                            ),

                            if (note.tags.isNotEmpty) ...[
                              pw.SizedBox(height: 8),
                              pw.Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: note.tags.map((tag) => pw.Container(
                                  padding: const pw.EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: pw.BoxDecoration(
                                    color: PdfColors.green100,
                                    borderRadius: pw.BorderRadius.circular(4),
                                  ),
                                  child: pw.Text(
                                    '#$tag',
                                    style: pw.TextStyle(
                                      fontSize: 9,
                                      color: PdfColors.green800,
                                    ),
                                  ),
                                )).toList(),
                              ),
                            ],

                            pw.SizedBox(height: 12),
                            pw.Divider(color: PdfColors.grey300),
                            pw.SizedBox(height: 12),

                            if (note.content.isNotEmpty)
                              pw.Text(
                                note.content,
                                style: pw.TextStyle(
                                  fontSize: 12,
                                  color: PdfColors.grey700,
                                  lineSpacing: 1.4,
                                ),
                              )
                            else
                              pw.Text(
                                'Aucun contenu',
                                style: pw.TextStyle(
                                  fontSize: 12,
                                  color: PdfColors.grey500,
                                  fontStyle: pw.FontStyle.italic,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                pw.Container(
                  margin: const pw.EdgeInsets.only(top: 20),
                  padding: const pw.EdgeInsets.only(top: 16),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      top: pw.BorderSide(color: PdfColors.grey300),
                    ),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'Généré par Gestionnaire de Notes - ${_formatDate(DateTime.now())}',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey500,
                        fontStyle: pw.FontStyle.italic,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );

      return await _savePdfAndOpen(pdf, title ?? 'notes');

    } catch (e) {
      throw Exception('Erreur PDF: $e');
    }
  }

  static Future<String?> _savePdfAndOpen(pw.Document pdf, String filename) async {
    try {
      final output = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${output.path}/${filename}_$timestamp.pdf');

      await file.writeAsBytes(await pdf.save());

      final result = await OpenFile.open(file.path);

      if (result.type == ResultType.done) {
        return file.path;
      } else {
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Export de mes notes',
        );
        return file.path;
      }
    } catch (e) {
      throw Exception('Erreur lors de la sauvegarde: $e');
    }
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  static Future<String?> exportSingleNote(Note note) async {
    return await exportNotesToPdf([note], title: note.title);
  }
}
