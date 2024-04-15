import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:fluttersrc/appBar.dart';
import 'package:http/http.dart' as http;
import 'package:page_transition/page_transition.dart';

import '../environment.dart';
import '../objects/userDto.dart';
import '../services/backButton.dart';
import '../services/tableServices/deleteItem.dart';
import '../services/tableServices/fetchItemsPage.dart';
import '../services/tableServices/showLicenseDetailsDialog.dart';
import 'add_license.dart';

class VerticalTextCell extends StatelessWidget {
  final String text;

  const VerticalTextCell(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return RotatedBox(
      quarterTurns: -1,
      child: Text(text),
    );
  }
}

class TablePage extends StatefulWidget {
  const TablePage({Key? key, required this.userDto}) : super(key: key);
  final UserDto userDto;

  @override
  _TablePageState createState() => _TablePageState();
}

final List<IconData> columnIcons = [
  Icons.access_alarm,
  Icons.date_range,
  Icons.timer,
  Icons.network_check,
  Icons.people,
  Icons.vpn_lock,
  Icons.description,
  Icons.credit_card,
  Icons.settings,
];

class _TablePageState extends State<TablePage> {



  List<Map<String, dynamic>> filteredItems = [];
  bool _sortAscending = true;
  int _sortColumnIndex = 0;
  DateTime? currentBackPressTime;

  TextEditingController nameFilterController = TextEditingController();
  TextEditingController licenseTypeFilterController = TextEditingController();
  TextEditingController licenseNumberFilterController = TextEditingController();
  TextEditingController licenseKeyFilterController = TextEditingController();
  TextEditingController pageController = TextEditingController();
  TextEditingController pageSizeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchItemsPage(context, (List<Map<String, dynamic>> itemsList) {
      setState(() {
        items = itemsList;
      });
    });
  }

  // Future<void> savePDFWeb(Map<String, dynamic> licenseData) async {
  //   final pdfDoc = pdf.Document();
  //   final ttf = await rootBundle.load("fonts/Roboto-Regular.ttf");
  //
  //   pdfDoc.addPage(
  //     pdf.Page(
  //       build: (context) => pdfWidgets.Center(
  //         child: pdfWidgets.Column(
  //           mainAxisAlignment: pdfWidgets.MainAxisAlignment.center,
  //           children: [
  //             pdfWidgets.Text(
  //               'Информация о лицензии',
  //               style: pdfWidgets.TextStyle(
  //                 fontSize: 20,
  //                 font: pdfWidgets.Font.ttf(ttf),
  //               ),
  //             ),
  //             pdfWidgets.SizedBox(height: 20),
  //             pdfWidgets.Text(
  //               'Владелец: ${licenseData['name']}',
  //               style: pdfWidgets.TextStyle(
  //                 font: pdfWidgets.Font.ttf(ttf),
  //               ),
  //             ),
  //             pdfWidgets.Text(
  //               'срок: ${licenseData['expiry_date']}',
  //               style: pdfWidgets.TextStyle(
  //                 font: pdfWidgets.Font.ttf(ttf),
  //               ),
  //             ),
  //             pdfWidgets.Text(
  //               'Пропускная способность: ${licenseData['max_bandwidth'] == '0' ? 'без ограничений' : licenseData['max_bandwidth']}',
  //               style: pdfWidgets.TextStyle(
  //                 font: pdfWidgets.Font.ttf(ttf),
  //               ),
  //             ),
  //             pdfWidgets.Text(
  //               'max_users: ${licenseData['max_users'] == '0' ? 'без ограничений' : licenseData['max_users']}',
  //               style: pdfWidgets.TextStyle(
  //                 font: pdfWidgets.Font.ttf(ttf),
  //               ),
  //             ),
  //             pdfWidgets.Text(
  //               'License: ${licenseData['license_key']}',
  //               style: pdfWidgets.TextStyle(
  //                 font: pdfWidgets.Font.ttf(ttf),
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  //
  //   final bytes = await pdfDoc.save();
  //   final blob = universal.Blob([Uint8List.fromList(bytes)]);
  //   final url = universal.Url.createObjectUrlFromBlob(blob);
  //   // final anchor = universal.AnchorElement(href: url)
  //   //   ..setAttribute("download", "license_data.pdf")
  //   //   ..click();
  //
  //   universal.Url.revokeObjectUrl(url);
  // }

  // Future<void> savePDF(Map<String, dynamic> licenseData) async {
  //   final pdfDoc = pdf.Document();
  //   final ttf = await rootBundle.load("fonts/Roboto-Regular.ttf");
  //
  //   pdfDoc.addPage(
  //     pdf.Page(
  //       build: (context) => pdf.Center(
  //         child: pdf.Column(
  //           mainAxisAlignment: pdf.MainAxisAlignment.center,
  //           children: [
  //             pdf.Text(
  //               'Информация о лицензии',
  //               style: pdf.TextStyle(fontSize: 20, font: pdf.Font.ttf(ttf)),
  //             ),
  //             pdf.SizedBox(height: 20),
  //             pdf.Text(
  //               'Владелец: ${licenseData['name']}',
  //               style: pdf.TextStyle(font: pdf.Font.ttf(ttf)),
  //             ),
  //             pdf.Text(
  //               'срок: ${licenseData['expiry_date']}',
  //               style: pdf.TextStyle(font: pdf.Font.ttf(ttf)),
  //             ),
  //             pdf.Text(
  //               'Пропускная способность: ${licenseData['max_bandwidth'] == '0' ? 'без ограничений' : licenseData['max_bandwidth']}',
  //               style: pdf.TextStyle(font: pdf.Font.ttf(ttf)),
  //             ),
  //             pdf.Text(
  //               'max_users: ${licenseData['max_users'] == '0' ? 'без ограничений' : licenseData['max_users']}',
  //               style: const pdf.TextStyle(),
  //             ),
  //             pdf.Text(
  //               'License: ${licenseData['license_key']}',
  //               style: const pdf.TextStyle(),
  //             ),
  //             // Добавьте остальную информацию о лицензии здесь...
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  //
  //   final output = await getTemporaryDirectory();
  //   final fileName = "${output.path}/${new Uuid().v1()}.pdf";
  //   List<int> bytes = await pdfDoc.save(); // Ждем завершения сохранения PDF
  //   final file = io.File(fileName);
  //   await file
  //       .writeAsBytes(bytes.toList()); // Преобразуем Uint8List в List<int>
  //   OpenFile.open(fileName);
  // }

  // Future<void> _showLicenseDetailsDialog(
  //     BuildContext context, Map<String, dynamic> item, UserDto userDto) async {
  //   // bool shouldShowButtons = widget.userDto.role != "user";
  //   await showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       bool isActivationButtonVisible = !(item['license_type'] == 1 ||
  //           item['license_type'] == 2 ||
  //           item['license_type'] == 3);
  //       // return Scaffold(
  //       //   body:
  //       return AlertDialog(
  //         scrollable: true,
  //         // insetPadding: EdgeInsets.all(300),
  //         title: const Text('Данные лицензии'),
  //
  //         content: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Text('Владелец: ${item['name']}'),
  //             Text('УНН/УНП: ${item['UNNorUNP']}'),
  //             Text('Дата отгрузки: ${item['date_shipping']}'),
  //             Text('№ договора: ${item['dogovor']}'),
  //             Text('Серийный номер: ${item['key']}'),
  //             SelectableText(
  //               'Лицензия: ${item['license_key']}',
  //               onTap: () {
  //                 Clipboard.setData(ClipboardData(text: item['license_key']));
  //                 ScaffoldMessenger.of(context).showSnackBar(
  //                   const SnackBar(
  //                     behavior: SnackBarBehavior.floating,
  //                     margin: EdgeInsets.all(150),
  //                     shape: RoundedRectangleBorder(
  //                       borderRadius: BorderRadius.all(Radius.circular(20)),
  //                     ),
  //                     backgroundColor: Colors.grey,
  //                     content: Text('текст скопирован'),
  //                     duration: Duration(seconds: 1),
  //                   ),
  //                 );
  //               },
  //             ),
  //             Text(
  //                 'Срок: ${item['expiry_date'].toString().isEmpty ? 'бессрочно' : item['expiry_date']}'),
  //             Text(
  //                 'Пропускная способность: ${item['max_bandwidth'] == '0' ? 'без ограничений' : item['max_bandwidth']}'),
  //             Text(
  //                 'Максимальное количество пользователей: ${item['max_users'] == 0 ? 'без ограничений' : item['max_users']}'),
  //             Text(
  //                 'Максимальное количество сессий: ${item['max_vpn_sessions'] == 0 ? 'без ограничений' : item['max_vpn_sessions']}'),
  //             Text(
  //                 'Тип лицензии: ${item['license_type'] == 1 ? 'сервер' : item['license_type'] == 3 ? 'клиент' : item['license_type'] == 2 ? 'мост' : item['license_type']}'),
  //             Text('Номер лицензии: ${item['license_number']}'),
  //             Text(
  //                 'Создатель: ${item['nameCreator'] ?? 'неизвестно'}'),
  //             Text(
  //                 'Дата создания: ${item['DateCtrate'] ?? 'неизвестно'}'),
  //
  //             if (userDto.role != 'guest') ...[
  //               Text(
  //                 'Пароль BIOS: ${item['passwordBIOS'] ?? 'не задано'}',
  //               ),
  //               Text(
  //                 'Пароль Root: ${item['passwordRoot'] ?? 'не задано'}',
  //               ),
  //               Text(
  //                 'Примечание: ${item['remark'] ?? ''}',
  //               ),
  //             ],
  //           ],
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () {
  //               if (kIsWeb) {
  //                 savePDFWeb(
  //                     item); //your web page with web package import in it
  //               } else if (!kIsWeb && io.Platform.isWindows) {
  //                 savePDF(
  //                     item); //your window page with window package import in it
  //               }
  //             },
  //             child: const Text('В PDF-формате'),
  //           ),
  //           Visibility(
  //             visible: isActivationButtonVisible,
  //             child: TextButton(
  //               onPressed: () {
  //                 showActivationDialog(context, item);
  //               },
  //               child: const Text('Активировать лицензию'),
  //             ),
  //           ),
  //           TextButton(
  //             onPressed: () {
  //               sendItemIdToServer(context, item['id']); // Send item ID to server
  //             },
  //             child: const Text('Получить файл с сервера'), // New button
  //           ),
  //           TextButton(
  //             onPressed: () {
  //               showHistoryDialog(context, item['id']);
  //             },
  //             child: const Text('Посмотреть историю изменений'),
  //           ),
  //           TextButton(
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //             },
  //             child: const Text('OK'),
  //           ),
  //         ],
  //       );
  //       // );
  //     },
  //   );
  // }





  // Future<void> _showActivationDialog(Map<String, dynamic> item) async {
  //   String activationCode = '';
  //
  //   await showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         scrollable: true,
  //         // insetPadding: EdgeInsets.all(400),
  //         title: const Text('Введите код активации'),
  //         content: Column(
  //           children: [
  //             TextField(
  //               onChanged: (value) {
  //                 activationCode = value;
  //               },
  //               decoration: const InputDecoration(
  //                 labelText: 'Код установки',
  //               ),
  //             ),
  //           ],
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () {
  //               _activateLicense(item['license_type'], item['license_number'],
  //                   activationCode);
  //
  //               Navigator.of(context).pop();
  //             },
  //             child: const Text('Активировать'),
  //           ),
  //           TextButton(
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //             },
  //             child: const Text('Отмена'),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }
  //
  // Future<void> _activateLicense(
  //     int licenseType, int licenseNumber, String activationCode) async {
  //   final response = await http.post(
  //     Uri.parse('$API_URL/api/createCode'),
  //     headers: <String, String>{
  //       'Content-Type': 'application/json',
  //     },
  //     body: jsonEncode(<String, String>{
  //       'install_key': activationCode,
  //       // 'password': password,
  //       'license_type': licenseType.toString(),
  //       'license_number': licenseNumber.toString(),
  //     }),
  //   );
  //
  //   if (response.statusCode == 200) {
  //     final Map<String, dynamic> responseData = json.decode(response.body);
  //     showDialog(
  //       context: context,
  //       builder: (BuildContext context) {
  //         return AlertDialog(
  //           insetPadding: const EdgeInsets.all(400),
  //           title: const Text('Успешно активировано'),
  //           content: Text('Код подтверждения: ${responseData['install_code']}'),
  //           actions: [
  //             TextButton(
  //               onPressed: () {
  //                 Navigator.of(context).pop();
  //               },
  //               child: const Text('OK'),
  //             ),
  //           ],
  //         );
  //       },
  //     );
  //   } else {
  //     if (kDebugMode) {
  //       print(response.statusCode);
  //     }
  //     if (response.statusCode == 400) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(
  //           backgroundColor: Colors.red,
  //           content: Text('Ошибка'),
  //           duration: Duration(seconds: 2),
  //         ),
  //       );
  //     }
  //   }
  // }

  // Future<void> _deleteItem(int itemId) async {
  //   bool confirmDelete = await showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: const Text('Подтверждение удаления'),
  //         content: const Text('Вы уверены, что хотите удалить запись?'),
  //         actions: [
  //           TextButton(
  //             onPressed: () {
  //               Navigator.of(context)
  //                   .pop(true); // Пользователь подтвердил удаление
  //             },
  //             child: const Text('Да'),
  //           ),
  //           TextButton(
  //             onPressed: () {
  //               Navigator.of(context)
  //                   .pop(false); // Пользователь отменил удаление
  //             },
  //             child: const Text('Нет'),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  //
  //   if (confirmDelete) {
  //     final response = await http.delete(
  //       Uri.parse('$API_URL/api/items/$itemId'),
  //     );
  //
  //     if (response.statusCode == 200) {
  //       await fetchItemsPage(context);
  //
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(
  //           backgroundColor: Colors.green,
  //           content: Text('Элемент успешно удален'),
  //           duration: Duration(seconds: 2),
  //         ),
  //       );
  //     } else {
  //       showDialog(
  //         context: context,
  //         builder: (BuildContext context) {
  //           return AlertDialog(
  //             title: const Text('Ошибка удаления'),
  //             content: const Text('Не удалось удалить элемент.'),
  //             actions: [
  //               TextButton(
  //                 onPressed: () {
  //                   Navigator.of(context).pop();
  //                 },
  //                 child: const Text('OK'),
  //               ),
  //             ],
  //           );
  //         },
  //       );
  //     }
  //   }
  // }

  Future<void> _changeItem(int itemId, Map<String, dynamic> item) async {
    String generatePassword() {
      final random = Random.secure();
      const alphabet = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
      const numbers = '0123456789';

      // Генерируем пароль, включая хотя бы одну букву и одну цифру
      String password = alphabet[random.nextInt(alphabet.length)] +
          numbers[random.nextInt(numbers.length)];

      // Добавляем еще 4 случайных символа
      for (int i = 0; i < 4; i++) {
        String charSet = random.nextBool() ? alphabet : numbers;
        password += charSet[random.nextInt(charSet.length)];
      }

      // Перемешиваем символы пароля
      List<String> passwordCharacters = password.split('');
      passwordCharacters.shuffle();

      return passwordCharacters.join('');
    }

    // Создаем глобальный ключ для доступа к состоянию формы


    // Отображаем диалоговое окно для ввода данных
    Map<String, String?>? newData = await showDialog(
      context: context,
      builder: (BuildContext context) {
        // Создаем текстовые контроллеры для полей ввода
        TextEditingController nameController = TextEditingController(text: '${item['name']}');
        TextEditingController keyController = TextEditingController(text: '${item['key']}');
        TextEditingController dateShippingController = TextEditingController(text: '${item['date_shipping']}');
        TextEditingController dogovorController = TextEditingController(text: '${item['dogovor']}');
        TextEditingController unnOrUnpController = TextEditingController(text: '${item['UNNorUNP']}');
        TextEditingController remarkController = TextEditingController(text: '${item['remark']}');
        final TextEditingController _passwordBiosController = TextEditingController();
        final TextEditingController _passwordRootController = TextEditingController();
        final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();


        return AlertDialog(
          title: const Text('Изменение элемента'),
          content: SingleChildScrollView(
            child: FormBuilder(
              key: _formKey,
              child: Column(
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Владелец'),
                  ),
                  TextField(
                    controller: unnOrUnpController,
                    decoration: const InputDecoration(labelText: 'УНН/УНП'),
                  ),
                  TextField(
                    controller: dateShippingController,
                    decoration: const InputDecoration(labelText: 'Дата отгрузки'),
                  ),
                  TextField(
                    controller: dogovorController,
                    decoration: const InputDecoration(labelText: 'Договор'),
                  ),
                  TextField(
                    controller: keyController,
                    decoration: const InputDecoration(labelText: 'Серийный номер'),
                  ),
                  FormBuilderTextField(
                    name: 'Пароль BIOS',
                    controller: _passwordBiosController,
                    decoration: InputDecoration(
                      labelText: 'Пароль BIOS',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.lock),
                        onPressed: () {
                          setState(() {
                            _passwordBiosController.text = generatePassword();
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Пароль BIOS не может быть пустым';
                      } else if (value.length < 6) {
                        return 'Пароль BIOS должен содержать не менее 6 символов';
                      } else if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d).+$').hasMatch(value)) {
                        return 'Пароль BIOS должен содержать как минимум одну букву и одну цифру';
                      }
                      return null;
                    },
                  ),
                  FormBuilderTextField(
                    name: 'Пароль ROOT',
                    controller: _passwordRootController,
                    decoration: InputDecoration(
                      labelText: 'Пароль ROOT',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.lock),
                        onPressed: () {
                          setState(() {
                            _passwordRootController.text = generatePassword();
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Пароль ROOT не может быть пустым';
                      } else if (value.length < 6) {
                        // print('Пароль ROOT должен содержать не менее 6 символов');
                        return 'Пароль ROOT должен содержать не менее 6 символов';
                      } else if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d).+$').hasMatch(value)) {
                        return 'Пароль ROOT должен содержать как минимум одну букву и одну цифру';
                      }
                      return null;
                    },
                  ),
                  TextField(
                    controller: remarkController,
                    decoration: const InputDecoration(labelText: 'Примечание'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  // Прошли валидацию
                  Navigator.of(context).pop({
                    'name': nameController.text,
                    'UNNorUNP': unnOrUnpController.text,
                    'date_shipping': dateShippingController.text,
                    'dogovor': dogovorController.text,
                    'key': keyController.text,
                    'passwordBIOS': _passwordBiosController.text,
                    'passwordRoot': _passwordRootController.text,
                    'remark': remarkController.text,
                  });
                }
                // print(_formKey.currentState!.validate().toString().toString());
                // print('bad validation');
              },
              child: const Text('Сохранить'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(null);
              },
              child: const Text('Отмена'),
            ),
          ],
        );
      },
    );

    if (newData != null) {
      final response = await http.put(
        Uri.parse('$API_URL/api/items/$itemId'),
        body: jsonEncode(newData),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        await   fetchItemsPage(context, (List<Map<String, dynamic>> itemsList) {
          setState(() {
            items = itemsList;
          });
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('Элемент успешно изменен'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Ошибка изменения'),
              content: const Text('Не удалось изменить элемент.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    }
  }


  // Future<void> fetchItemsPage() async {
  //   try {
  //     final response = await http.get(Uri.parse(
  //         '$API_URL/api/fetchItems?page=$currentPage&size=$pageSize'));
  //
  //     if (response.statusCode == 200) {
  //       // ScaffoldMessenger.of(context).showSnackBar(
  //       //   const SnackBar(
  //       //     backgroundColor: Colors.green,
  //       //     content: Text('Загружено успешно'),
  //       //     duration: Duration(seconds: 2), // Длительность отображения Snackbar
  //       //   ),
  //       // );
  //       final List<dynamic> responseData = json.decode(response.body);
  //       final List<Map<String, dynamic>> itemsList =
  //           List<Map<String, dynamic>>.from(responseData);
  //
  //       setState(() {
  //         items = itemsList;
  //       });
  //     } else {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(
  //           backgroundColor: Colors.red,
  //           content: Text('Загрузка не удалась'),
  //           duration: Duration(seconds: 2), // Длительность отображения Snackbar
  //         ),
  //       );
  //       throw Exception('Failed to load items');
  //     }
  //   } catch (error) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         backgroundColor: Colors.red,
  //         content: Text('Произошла ошибка: $error'),
  //         duration: const Duration(seconds: 2),
  //       ),
  //     );
  //     throw Exception('Failed to load items: $error');
  //   }
  // }

  Future<void> fetchItems() async {
    try {
      final response = await http.get(Uri.parse('$API_URL/api/items'));

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('Загружено успешно'),
            duration: Duration(seconds: 2), // Длительность отображения Snackbar
          ),
        );
        final List<dynamic> responseData = json.decode(response.body);
        final List<Map<String, dynamic>> itemsList =
            List<Map<String, dynamic>>.from(responseData);
        setState(() {
          items = itemsList;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text('Загрузка не удалась'),
            duration: Duration(seconds: 2), // Длительность отображения Snackbar
          ),
        );
        throw Exception('Failed to load items');
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Произошла ошибка: $error'),
          duration: const Duration(seconds: 2),
        ),
      );
      throw Exception('Failed to load items: $error');
    }
  }

  void _sort<T>(Comparable<T> Function(Map<String, dynamic> d) getField,
      int columnIndex, bool ascending) {
    filteredItems.sort((a, b) {
      final aValue = getField(a);
      final bValue = getField(b);
      return ascending
          ? Comparable.compare(aValue, bValue)
          : Comparable.compare(bValue, aValue);
    });
    items.sort((a, b) {
      final aValue = getField(a);
      final bValue = getField(b);
      return ascending
          ? Comparable.compare(aValue, bValue)
          : Comparable.compare(bValue, aValue);
    });
  }

  Future<void> _filterItems(int pageSize, int pageNumber) async {
    final nameFilter = nameFilterController.text.toLowerCase();
    final licenseTypeFilter = licenseTypeFilterController.text.toLowerCase();
    final licenseNumberFilter =
        licenseNumberFilterController.text.toLowerCase();
    final licenseKeyFilter = licenseKeyFilterController.text.toLowerCase();

    final url = Uri.parse('$API_URL/api/filterItems');
    final response = await http.post(
      url,
      body: jsonEncode({
        'name': nameFilter,
        'license_type': licenseTypeFilter,
        'license_key': licenseKeyFilter,
        'pageSize': pageSize, // Добавляем размер страницы в параметры запроса
        'pageNumber': pageNumber,
      }),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> responseData = json.decode(response.body);
      final List<Map<String, dynamic>> itemsList =
          List<Map<String, dynamic>>.from(responseData);

      setState(() {
        items = itemsList;
      });
    } else {
      // Обработка ошибки, если запрос не удался
      // Например, отображение сообщения об ошибке пользователю
      print('Request failed with status: ${response.statusCode}');
    }

    setState(() {
      fetchItemsPage(context, (List<Map<String, dynamic>> itemsList) {
        setState(() {
          items = itemsList;
        });
      });
      filteredItems = items.where((item) {
        final name = item['name'].toString().toLowerCase();
        final licenseType = item['license_type'].toString().toLowerCase();
        final licenseNumber = item['license_number'].toString().toLowerCase();
        final licenseKey = item['license_key'].toString().toLowerCase();
        return name.contains(nameFilter) &&
            licenseType.contains(licenseTypeFilter) &&
            licenseNumber.contains(licenseNumberFilter) &&
            licenseKey.contains(licenseKeyFilter);
      }).toList();
    });
  }

  Widget _buildColumnLabel(String tooltip, IconData icon) {
    return (kIsWeb || defaultTargetPlatform == TargetPlatform.windows)
        ? Center(
            child: Text(
              tooltip,
              style: const TextStyle(fontSize: 14.0, color: Colors.white),
              textAlign: TextAlign.right,
              selectionColor: Colors.white,
            ),
          )
        : Icon(icon);
  }

  List<DataColumn> buildDataColumns() {
    List<DataColumn> columns = [
      DataColumn(
        label: _buildColumnLabel('Владелец', Icons.account_box),
        tooltip: 'Владелец',
        onSort: (columnIndex, ascending) {
          setState(() {
            _sortAscending = ascending;
            _sortColumnIndex = columnIndex;
            _sort((item) => item['name'], columnIndex, ascending);
          });
        },
      ),
      DataColumn(
        label: _buildColumnLabel('   УНН/УНП', Icons.password),
        tooltip: 'УНН/УНП',
        onSort: (columnIndex, ascending) {
          setState(() {
            _sortAscending = ascending;
            _sortColumnIndex = columnIndex;
            _sort((item) => item['UNNorUNP'], columnIndex, ascending);
          });
        },
      ),

      DataColumn(
        label: _buildColumnLabel('   Дата отгрузки', Icons.password),
        tooltip: 'Дата отгрузки',
        onSort: (columnIndex, ascending) {
          setState(() {
            _sortAscending = ascending;
            _sortColumnIndex = columnIndex;
            _sort((item) => item['date_shipping'], columnIndex, ascending);
          });
        },
      ),

      DataColumn(
        label: _buildColumnLabel('   Договор', Icons.password),
        tooltip: 'Договор',
        onSort: (columnIndex, ascending) {
          setState(() {
            _sortAscending = ascending;
            _sortColumnIndex = columnIndex;
            _sort((item) => item['dogovor'], columnIndex, ascending);
          });
        },
      ),
      DataColumn(
        label: _buildColumnLabel('   Серийный номер', Icons.numbers),
        tooltip: '  Серийный номер',
        onSort: (columnIndex, ascending) {
          setState(() {
            _sortAscending = ascending;
            _sortColumnIndex = columnIndex;
            _sort((item) => item['key'], columnIndex, ascending);
          });
        },
      ),
      DataColumn(
        label: _buildColumnLabel('  Лицензия', Icons.text_fields),
        tooltip: 'Лицензия',
        onSort: (columnIndex, ascending) {
          setState(() {
            _sortAscending = ascending;
            _sortColumnIndex = columnIndex;
            _sort((item) => item['license_key'], columnIndex, ascending);
          });
        },
      ),
      DataColumn(
        label: _buildColumnLabel(
            '   Тип лицензии', Icons.format_list_numbered_rounded),
        tooltip: 'Тип лицензии',
        onSort: (columnIndex, ascending) {
          setState(() {
            _sortAscending = ascending;
            _sortColumnIndex = columnIndex;
            _sort((item) => item['license_type'], columnIndex, ascending);
          });
        },
      ),
      DataColumn(
        label: _buildColumnLabel('   Срок', Icons.date_range),
        tooltip: 'срок',
        onSort: (columnIndex, ascending) {
          setState(() {
            _sortAscending = ascending;
            _sortColumnIndex = columnIndex;
            _sort((item) => item['expiry_date'], columnIndex, ascending);
          });
        },
      ),
      DataColumn(
        label:
            _buildColumnLabel('  Пропускная\nспособность', Icons.network_check),
        tooltip: 'Пропускная\nспособность',
        onSort: (columnIndex, ascending) {
          setState(() {
            _sortAscending = ascending;
            _sortColumnIndex = columnIndex;
            _sort((item) => item['max_bandwidth'], columnIndex, ascending);
          });
        },
      ),
      DataColumn(
        label: _buildColumnLabel('  Макс кол-во\nпользователей', Icons.people),
        tooltip: 'Макс кол-во\nпользователей',
        onSort: (columnIndex, ascending) {
          setState(() {
            _sortAscending = ascending;
            _sortColumnIndex = columnIndex;
            _sort((item) => item['max_users'], columnIndex, ascending);
          });
        },
      ),
      DataColumn(
        label: _buildColumnLabel('  Макс кол-во\nсессий', Icons.account_tree),
        tooltip: 'Макс кол-во\nсессий',
        onSort: (columnIndex, ascending) {
          setState(() {
            _sortAscending = ascending;
            _sortColumnIndex = columnIndex;
            _sort((item) => item['max_vpn_sessions'], columnIndex, ascending);
          });
        },
      ),

      DataColumn(
        label: _buildColumnLabel('   Код активации', Icons.password),
        tooltip: 'Код активации',
        onSort: (columnIndex, ascending) {
          setState(() {
            _sortAscending = ascending;
            _sortColumnIndex = columnIndex;
            _sort((item) => item['generate_key'], columnIndex, ascending);
          });
        },
      ),

      // Другие DataColumn здесь...
    ];

    // Проверяем роль пользователя и добавляем колонку с кнопкой удаления, если роль не 'user'.
    if (widget.userDto.role == 'admin') {
      columns.add(
        const DataColumn(
          label: Icon(
            Icons.delete_outline_outlined,
            color: Colors.greenAccent,
          ),
        ),
      );
    }
    if (widget.userDto.role != 'guest') {
      columns.add(
        const DataColumn(
          label: Icon(
            Icons.edit,
            color: Colors.greenAccent,
          ),
        ),
      );
    }
    return columns;
  }

  @override
  Widget build(BuildContext context) {
    var licenseTypes = {
      1: "Сервер",
      2: "Мост",
      3: "Клиент",
      4: "Сервер с КП",
      5: "Мост с КП",
      6: "Клиент с КП",
      101: "Сервер без случайности",
      102: "Мост без случайности",
      103: "Клиент без случайности",
      104: "Сервер без случайности с КП",
      105: "Мост без случайности с КП",
      106: "Клиент без случайности с КП",
      100: "[htym"
    };
    // var licenseTypeMap = {
    //   1: "Сервер",
    //   2: "Мост",
    //   3: "Клиент",
    // };

    bool shouldShowButtons = widget.userDto.role != "guest";
    return WillPopScope(
      onWillPop: () async {
        return backButton(context);
      },
      
      child: Scaffold(

        appBar: CustomAppBar(userDto: widget.userDto),
        drawer: AppDrawer(userDto: widget.userDto),
        body: SingleChildScrollView(

          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: nameFilterController,
                      onChanged: (value) {
                        _filterItems(pageSize, currentPage);
                        setState(() {});
                      },
                      decoration: const InputDecoration(
                        labelText: 'Фильтр по владельцу',
                      ),
                    ),
                    TextField(
                      controller: licenseTypeFilterController,
                      onChanged: (value) {
                        _filterItems(pageSize, currentPage);
                        setState(() {});
                      },
                      decoration: const InputDecoration(
                        labelText: 'Фильтр по типу лицензии',
                      ),
                    ),
                    TextField(
                      controller: licenseKeyFilterController,
                      onChanged: (value) {
                        _filterItems(pageSize, currentPage);
                        setState(() {});
                      },
                      decoration: const InputDecoration(
                        labelText: 'Фильтр по лицензии',
                      ),
                    ),
                  ],
                ),
              ),
              LayoutBuilder(builder: (context, constraints) {
                double availableWidth = constraints.maxWidth;
                if (availableWidth > 1250) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width,
                        child: DataTable(
                          showCheckboxColumn: false,
                          headingRowColor: MaterialStateColor.resolveWith(
                              (Set<MaterialState> states) {
                            return Colors.blue;
                          }),
                          border: TableBorder.all(
                            width: 2.0,
                            color: Colors.black45,
                          ),
                          columnSpacing: 1,
                          sortAscending: _sortAscending,
                          sortColumnIndex: _sortColumnIndex,
                          columns: buildDataColumns(),
                          rows: (nameFilterController.text.isEmpty &&
                                  licenseTypeFilterController.text.isEmpty &&
                                  licenseNumberFilterController.text.isEmpty &&
                                  licenseKeyFilterController.text.isEmpty)
                              ? items.map(
                                  (item) {
                                    List<DataCell> cells = [
                                      DataCell(
                                        Center(
                                          child: Text(item['name']),
                                        ),
                                      ),
                                      DataCell(
                                        Center(
                                          child: Text(
                                            item['UNNorUNP'] == null
                                                ? '-' // or any other symbol or text
                                                : item['UNNorUNP'].toString(),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Center(
                                          child: Text(
                                            item['date_shipping'] == null
                                                ? '-' // or any other symbol or text
                                                : item['date_shipping']
                                                    .toString(),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Center(
                                          child: Text(
                                            item['dogovor'] == null
                                                ? '-' // or any other symbol or text
                                                : item['dogovor'].toString(),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Center(
                                          child: Text(item['key']),
                                        ),
                                      ),
                                      DataCell(
                                        Center(
                                          child: Text(
                                            item['license_key'].toString(),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Center(
                                          child: Text(
                                            licenseTypes[
                                                item['license_type']]!,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Center(
                                          child: Text(
                                            item['expiry_date']
                                                    .toString()
                                                    .isEmpty
                                                ? 'бессрочно'
                                                : item['expiry_date']
                                                    .toString(),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Center(
                                          child: Text(
                                            item['max_bandwidth'] == '0'
                                                ? '∞' // or any other symbol or text
                                                : item['max_bandwidth']
                                                    .toString(),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Center(
                                          child: Text(
                                            item['max_users'] == 0
                                                ? '∞' // or any other symbol or text
                                                : item['max_users'].toString(),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Center(
                                          child: Text(
                                            item['max_vpn_sessions'] == 0
                                                ? '∞' // or any other symbol or text
                                                : item['max_vpn_sessions']
                                                    .toString(),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Center(
                                          child: Text(
                                            item['generate_key'] == null
                                                ? '-' // or any other symbol or text
                                                : item['generate_key']
                                                    .toString(),
                                          ),
                                        ),
                                      ),
                                    ];
                                    // Добавляем DataCell с кнопкой удаления только если роль пользователя не "user"
                                    if (widget.userDto.role == 'admin') {
                                      cells.add(
                                        DataCell(
                                          Center(
                                            child: ElevatedButton(
                                              onPressed: () {
                                                deleteItem(context, item['id'], () {
                                                  fetchItemsPage(context, (List<Map<String, dynamic>> itemsList) {
                                                    setState(() {
                                                      items = itemsList;
                                                    });
                                                  });
                                                });
                                              },
                                              child: const Icon(
                                                Icons.delete,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                    if (widget.userDto.role != 'guest') {
                                      cells.add(
                                        DataCell(
                                          Center(
                                            child: ElevatedButton(
                                              onPressed: () {
                                                _changeItem(item['id'], item);
                                              },
                                              child: const Icon(
                                                Icons.edit,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                    return DataRow(
                                      onSelectChanged: (selected) {
                                        if (selected != null && selected) {
                                          showLicenseDetailsDialog(
                                              context, item, widget.userDto);
                                        }
                                      },
                                      cells: cells,
                                    );
                                  },
                                ).toList()
                              : filteredItems.map(
                                  (item) {
                                    List<DataCell> cells = [

                                      DataCell(
                                        Center(
                                          child: Text(item['name']),
                                        ),
                                      ),
                                      DataCell(
                                        Center(
                                          child: Text(
                                            item['UNNorUNP'] == null
                                                ? '-' // or any other symbol or text
                                                : item['UNNorUNP'].toString(),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Center(
                                          child: Text(
                                            item['date_shipping'] == null
                                                ? '-' // or any other symbol or text
                                                : item['date_shipping']
                                                .toString(),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Center(
                                          child: Text(
                                            item['dogovor'] == null
                                                ? '-' // or any other symbol or text
                                                : item['dogovor'].toString(),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Center(
                                          child: Text(item['key']),
                                        ),
                                      ),
                                      DataCell(
                                        Center(
                                          child: Text(
                                            item['license_key'].toString(),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Center(
                                          child: Text(
                                            licenseTypes[
                                            item['license_type']]!,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Center(
                                          child: Text(
                                            item['expiry_date']
                                                .toString()
                                                .isEmpty
                                                ? 'бессрочно'
                                                : item['expiry_date']
                                                .toString(),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Center(
                                          child: Text(
                                            item['max_bandwidth'] == '0'
                                                ? '∞' // or any other symbol or text
                                                : item['max_bandwidth']
                                                .toString(),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Center(
                                          child: Text(
                                            item['max_users'] == 0
                                                ? '∞' // or any other symbol or text
                                                : item['max_users'].toString(),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Center(
                                          child: Text(
                                            item['max_vpn_sessions'] == 0
                                                ? '∞' // or any other symbol or text
                                                : item['max_vpn_sessions']
                                                .toString(),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Center(
                                          child: Text(
                                            item['generate_key'] == null
                                                ? '-' // or any other symbol or text
                                                : item['generate_key']
                                                .toString(),
                                          ),
                                        ),
                                      ),
                                    ];

                                    // Добавляем DataCell с кнопкой удаления только если роль пользователя не "user"
                                    if (widget.userDto.role != 'user') {
                                      cells.add(
                                        DataCell(
                                          Center(
                                            child: ElevatedButton(
                                              onPressed: () {
                                                deleteItem(context, item['id'], () {
                                                  fetchItemsPage(context, (List<Map<String, dynamic>> itemsList) {
                                                    setState(() {
                                                      items = itemsList;
                                                    });
                                                  });
                                                });
                                              },
                                              child: const Icon(
                                                Icons.delete,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                    if (widget.userDto.role != 'guest') {
                                      cells.add(
                                        DataCell(
                                          Center(
                                            child: ElevatedButton(
                                              onPressed: () {
                                                _changeItem(item['id'], item);
                                              },
                                              child: const Icon(
                                                Icons.edit,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                    return DataRow(
                                      onSelectChanged: (selected) {
                                        if (selected != null && selected) {
                                          showLicenseDetailsDialog(
                                              context, item, widget.userDto);
                                        }
                                      },
                                      cells: cells,
                                    );
                                  },
                                ).toList(),
                        ),
                      ),
                    ),
                  );
                } else {
                  // int columnCount = availableWidth > 600 ? 2 : 1;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: (nameFilterController.text.isEmpty &&
                            licenseTypeFilterController.text.isEmpty &&
                            licenseKeyFilterController.text.isEmpty)
                        ? items.map((item) {
                            return InkWell(
                              onTap: () {
                                showLicenseDetailsDialog(
                                    context, item, widget.userDto);
                              },
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Название: ${item['name']}'),
                                      Text('Срок: ${item['expiry_date']}'),
                                      Text(
                                          'пропускная способность: ${item['max_bandwidth']}'),
                                      Text(
                                          'пользователи: ${item['max_users']}'),
                                      Text(
                                          'сессии: ${item['max_vpn_sessions']}'),
                                      Text(
                                          'тип лицензии: ${item['license_type']}'),
                                      Text(
                                          'лицензионный ключ: ${item['license_key']}'),
                                      // Text(
                                      //     'ключ активации: ${item['generate_key']}'),
                                      // Добавьте другие поля по мере необходимости
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList()
                        : filteredItems.map((item) {
                            return InkWell(
                              onTap: () {
                                showLicenseDetailsDialog(
                                    context, item, widget.userDto);
                              },
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Название: ${item['name']}'),
                                      Text('Срок: ${item['expiry_date']}'),
                                      Text(
                                          'пропускная способность: ${item['max_bandwidth']}'),
                                      Text(
                                          'пользователи: ${item['max_users']}'),
                                      Text(
                                          'сессии: ${item['max_vpn_sessions']}'),
                                      Text(
                                          'тип лицензии: ${item['license_type']}'),
                                      Text(
                                          'лицензионный ключ: ${item['license_key']}'),
                                      // Text(
                                      //     'ключ активации: ${item['generate_key']}'),
                                      // Добавьте другие поля по мере необходимости
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                  );
                }
              }),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Кнопка для перехода на предыдущую страницу
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: currentPage > 1
                        ? () {
                            setState(() {
                              currentPage--;
                              pageController.text = currentPage.toString();
                              fetchItemsPage(context, (List<Map<String, dynamic>> itemsList) {
                                setState(() {
                                  items = itemsList;
                                });
                              });
                              _filterItems(pageSize,
                                  currentPage); // Загружаем предыдущую страницу
                            });
                          }
                        : null,
                  ),
                  const Text('Страница: '),
                  // Поле ввода для номера страницы
                  SizedBox(
                    width: 50, // Ширина поля TextField
                    child: TextField(
                      controller: pageController,
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        currentPage = value.isNotEmpty
                            ? int.tryParse(value) ?? currentPage
                            : 1;
                        fetchItemsPage(context, (List<Map<String, dynamic>> itemsList) {
                          setState(() {
                            items = itemsList;
                          });
                        });
                        _filterItems(pageSize, currentPage);
                      },
                    ),
                  ),

                  // Кнопка для перехода на следующую страницу
                  IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: () {
                      setState(() {
                        currentPage++;
                        pageController.text = currentPage
                            .toString(); // Обновляем значение в TextField
                        fetchItemsPage(context, (List<Map<String, dynamic>> itemsList) {
                          setState(() {
                            items = itemsList;
                          });
                        });
                        _filterItems(pageSize,
                            currentPage); // Загружаем следующую страницу
                      });
                    },
                  ),
                  const Text('Количество строк'),
                  // Бокс для ввода размера страницы
                  SizedBox(
                    width: 50, // Ширина поля TextField
                    child: TextField(
                      controller: pageSizeController,
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {
                          pageSize = int.tryParse(value) ?? 10;
                          // Обновляем значение pageSize
                          fetchItemsPage(context, (List<Map<String, dynamic>> itemsList) {
                            setState(() {
                              items = itemsList;
                            });
                          });
                          _filterItems(pageSize,
                              currentPage); // Перезагружаем текущую страницу с новым размером
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        floatingActionButton: shouldShowButtons
            ? FloatingActionButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(PageTransition(
                    type: PageTransitionType.leftToRight,
                    child: HomePage(userDto: widget.userDto),
                  ));
                },
                backgroundColor: Colors.greenAccent,
                child: const Icon(Icons.add), // Цвет кнопки
              )
            : Container(),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }
}
