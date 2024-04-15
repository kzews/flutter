import 'package:flutter/services.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pdf;
import 'dart:io' as io;

import 'package:uuid/uuid.dart';

Future<void> savePDF(Map<String, dynamic> licenseData) async {
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
              style: pdf.TextStyle(fontSize: 20, font: pdf.Font.ttf(ttf)),
            ),
            pdf.SizedBox(height: 20),
            pdf.Text(
              'Владелец: ${licenseData['name']}',
              style: pdf.TextStyle(font: pdf.Font.ttf(ttf)),
            ),
            pdf.Text(
              'срок: ${licenseData['expiry_date']}',
              style: pdf.TextStyle(font: pdf.Font.ttf(ttf)),
            ),
            pdf.Text(
              'Пропускная способность: ${licenseData['max_bandwidth'] == '0' ? 'без ограничений' : licenseData['max_bandwidth']}',
              style: pdf.TextStyle(font: pdf.Font.ttf(ttf)),
            ),
            pdf.Text(
              'max_users: ${licenseData['max_users'] == '0' ? 'без ограничений' : licenseData['max_users']}',
              style: const pdf.TextStyle(),
            ),
            pdf.Text(
              'License: ${licenseData['license_key']}',
              style: const pdf.TextStyle(),
            ),
            // Добавьте остальную информацию о лицензии здесь...
          ],
        ),
      ),
    ),
  );

  final output = await getTemporaryDirectory();
  final fileName = "${output.path}/${new Uuid().v1()}.pdf";
  List<int> bytes = await pdfDoc.save(); // Ждем завершения сохранения PDF
  final file = io.File(fileName);
  await file.writeAsBytes(bytes.toList()); // Преобразуем Uint8List в List<int>
  OpenFile.open(fileName);
}
