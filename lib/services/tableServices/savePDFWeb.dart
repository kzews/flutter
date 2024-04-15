import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pdf;

import 'package:universal_html/html.dart' as universal;

Future<void> savePDFWeb(Map<String, dynamic> licenseData) async {
  final pdfDoc = pdf.Document();
  final ttf = await rootBundle.load("fonts/Roboto-Regular.ttf");

  pdfDoc.addPage(
    pdf.Page(
      build: (context) => pdf.Center(
        child: pdf.Column(
          mainAxisAlignment: pdf.MainAxisAlignment.center,
          children: [
            pdf.Text(
              'Информация о лицензии',
              style: pdf.TextStyle(
                fontSize: 20,
                font: pdf.Font.ttf(ttf),
              ),
            ),
            pdf.SizedBox(height: 20),
            pdf.Text(
              'Владелец: ${licenseData['name']}',
              style: pdf.TextStyle(
                font: pdf.Font.ttf(ttf),
              ),
            ),
            pdf.Text(
              'срок: ${licenseData['expiry_date']}',
              style: pdf.TextStyle(
                font: pdf.Font.ttf(ttf),
              ),
            ),
            pdf.Text(
              'Пропускная способность: ${licenseData['max_bandwidth'] == '0' ? 'без ограничений' : licenseData['max_bandwidth']}',
              style: pdf.TextStyle(
                font: pdf.Font.ttf(ttf),
              ),
            ),
            pdf.Text(
              'max_users: ${licenseData['max_users'] == '0' ? 'без ограничений' : licenseData['max_users']}',
              style: pdf.TextStyle(
                font: pdf.Font.ttf(ttf),
              ),
            ),
            pdf.Text(
              'License: ${licenseData['license_key']}',
              style: pdf.TextStyle(
                font: pdf.Font.ttf(ttf),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  final bytes = await pdfDoc.save();
  final blob = universal.Blob([Uint8List.fromList(bytes)]);
  final url = universal.Url.createObjectUrlFromBlob(blob);
  // final anchor = universal.AnchorElement(href: url)
  //   ..setAttribute("download", "license_data.pdf")
  //   ..click();

  universal.Url.revokeObjectUrl(url);
}
