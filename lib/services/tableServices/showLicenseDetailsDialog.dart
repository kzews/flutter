import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttersrc/services/tableServices/savePDF.dart';
import 'package:fluttersrc/services/tableServices/savePDFWeb.dart';
import 'package:fluttersrc/services/tableServices/sendItemIdToServer.dart';
import 'package:fluttersrc/services/tableServices/showActivationDialog.dart';
import 'package:fluttersrc/services/tableServices/showHistoryDialog.dart';
import 'dart:io' as io;

import '../../objects/userDto.dart';

Future<void> showLicenseDetailsDialog(
    BuildContext context, Map<String, dynamic> item, UserDto userDto) async {
  var licenseTypes = {
    1: "Сервер",
    2: "Мост",
    3: "Клиент",
    4: "Сервер с КП",
    5: "Мост с КП",
    6: "Клиент с КП",
    101: "Сервер без физического источника случайности",
    102: "Мост без физического источника случайности",
    103: "Клиент без физического источника случайности",
    104: "Сервер без физического источника случайности с КП",
    105: "Мост без физического источника случайности с КП",
    106: "Клиент без физического источника случайности с КП",
  };
  await showDialog(
    context: context,
    builder: (BuildContext context) {
      bool isActivationButtonVisible = !(item['license_type'] == 1 ||
          item['license_type'] == 2 ||
          item['license_type'] == 3 || item['license_type'] == 101 || item['license_type'] == 102 || item['license_type'] == 103 ||
          userDto.role == 'guest');
      return AlertDialog(
        scrollable: true,

        title: const Text('Данные лицензии'),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Владелец: ${item['name']}'),
            Text('УНН/УНП: ${item['UNNorUNP']}'),
            Text('Дата отгрузки: ${item['date_shipping']}'),
            Text('№ договора: ${item['dogovor']}'),
            Text('Серийный номер: ${item['key']}'),
            SelectableText(
              'Лицензия: ${item['license_key']}',
              onTap: () {
                Clipboard.setData(ClipboardData(text: item['license_key']));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    behavior: SnackBarBehavior.floating,
                    margin: EdgeInsets.all(150),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                    backgroundColor: Colors.grey,
                    content: Text('текст скопирован'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
            Text(
                'Срок: ${item['expiry_date']== 0 ? 'бессрочная' : item['expiry_date']}'),
            Text(
                'Пропускная способность: ${item['max_bandwidth'] == '0' ? 'без ограничений' : item['max_bandwidth']}'),
            Text(
                'Максимальное количество пользователей: ${item['max_users'] == 0 ? 'без ограничений' : item['max_users']}'),
            Text(
                'Максимальное количество сессий: ${item['max_vpn_sessions'] == 0 ? 'без ограничений' : item['max_vpn_sessions']}'),
            Text(
              'Тип лицензии: ${licenseTypes[item['license_type']] ?? item['license_type']}',
            ),
            Text('Номер лицензии: ${item['license_number']}'),
            Text('Создатель: ${item['nameCreator'] ?? 'неизвестно'}'),
            Text('Дата создания: ${item['DateCtrate'] ?? 'неизвестно'}'),
            if (userDto.role != 'guest') ...[
              Text(
                'Пароль BIOS: ${item['passwordBIOS'] ?? 'не задано'}',
              ),
              Text(
                'Пароль Root: ${item['passwordRoot'] ?? 'не задано'}',
              ),
              Text(
                'Примечание: ${item['remark'] ?? ''}',
              ),
              Text(
                'Код активации: ${item['generate_key'] ?? ''}',
              ),
            ],
          ],
        ),
        actions: [
          // TextButton(
          //   onPressed: () {
          //     if (kIsWeb) {
          //       savePDFWeb(item); //your web page with web package import in it
          //     } else if (!kIsWeb && io.Platform.isWindows) {
          //       savePDF(
          //           item); //your window page with window package import in it
          //     }
          //   },
          //   child: const Text('В PDF-формате'),
          // ),
          Visibility(
            visible: isActivationButtonVisible,
            child: TextButton(
              onPressed: () {
                showActivationDialog(context, item);
              },
              child: const Text('Активировать лицензию'),
            ),
          ),
          // TextButton(
          //   onPressed: () {
          //     sendItemIdToServer(context, item['id']); // Send item ID to server
          //   },
          //   child: const Text('Получить файл с сервера'), // New button
          // ),
          TextButton(
            onPressed: () {
              showHistoryDialog(context, item['id']);
            },
            child: const Text('Посмотреть историю изменений'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      );
      // );
    },
  );
}
