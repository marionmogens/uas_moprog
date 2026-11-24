import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../data/help_content.dart';

class HelpPdfService {
  HelpPdfService._();

  static Future<Uint8List> build({List<String>? sectionIds}) async {
    final doc = pw.Document(title: 'Panduan Penggunaan PadelBook');
    final sections = sectionIds == null
        ? helpSections
        : helpSections.where((s) => sectionIds.contains(s.id)).toList();

    final accent = PdfColor.fromInt(0xFFF06292);

    pw.Widget h1(String t) => pw.Padding(
      padding: const pw.EdgeInsets.only(top: 18, bottom: 6),
      child: pw.Text(t,
          style: pw.TextStyle(
              fontSize: 15, fontWeight: pw.FontWeight.bold, color: accent)),
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        footer: (ctx) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text('PadelBook - halaman ${ctx.pageNumber}/${ctx.pagesCount}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
        ),
        build: (ctx) => [
          pw.Text('Panduan Penggunaan PadelBook',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text('Aplikasi reservasi lapangan dan kelas padel',
              style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
          pw.Divider(),
          for (final s in sections) ...[
            h1(s.title),
            pw.Text(s.intro,
                style: const pw.TextStyle(fontSize: 10.5, color: PdfColors.grey800)),
            pw.SizedBox(height: 6),
            for (final step in s.steps)
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 7),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(step.title,
                        style: pw.TextStyle(
                            fontSize: 11, fontWeight: pw.FontWeight.bold)),
                    pw.Text(step.body, style: const pw.TextStyle(fontSize: 10.5)),
                  ],
                ),
              ),
          ],
          h1('Pertanyaan yang Sering Diajukan (FAQ)'),
          for (final f in faqItems)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 7),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('T: ${f.question}',
                      style: pw.TextStyle(
                          fontSize: 11, fontWeight: pw.FontWeight.bold)),
                  pw.Text('J: ${f.answer}', style: const pw.TextStyle(fontSize: 10.5)),
                ],
              ),
            ),
        ],
      ),
    );
    return doc.save();
  }

  static Future<void> share({List<String>? sectionIds}) async {
    final bytes = await build(sectionIds: sectionIds);
    await Printing.sharePdf(bytes: bytes, filename: 'Panduan_PadelBook.pdf');
  }
}