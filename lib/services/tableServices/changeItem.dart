// import 'dart:convert';
// import 'dart:math';
//
// import 'package:flutter/material.dart';
// import 'package:flutter_form_builder/flutter_form_builder.dart';
//
// import '../../environment.dart';
// import 'fetchItemsPage.dart';
//
//
// TextEditingController nameFilterController = TextEditingController();
// TextEditingController licenseTypeFilterController = TextEditingController();
// TextEditingController licenseNumberFilterController = TextEditingController();
// TextEditingController licenseKeyFilterController = TextEditingController();
// TextEditingController pageController = TextEditingController();
// TextEditingController pageSizeController = TextEditingController();
//
// Future<void> changeItem(BuildContext context, int itemId, Map<String, dynamic> item) async {
//   String generatePassword() {
//     final random = Random.secure();
//     const alphabet = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
//     const numbers = '0123456789';
//
//     // Генерируем пароль, включая хотя бы одну букву и одну цифру
//     String password = alphabet[random.nextInt(alphabet.length)] +
//         numbers[random.nextInt(numbers.length)];
//
//     // Добавляем еще 4 случайных символа
//     for (int i = 0; i < 4; i++) {
//       String charSet = random.nextBool() ? alphabet : numbers;
//       password += charSet[random.nextInt(charSet.length)];
//     }
//
//     // Перемешиваем символы пароля
//     List<String> passwordCharacters = password.split('');
//     passwordCharacters.shuffle();
//
//     return passwordCharacters.join('');
//   }
//
//   // Создаем глобальный ключ для доступа к состоянию формы
//
//
//   // Отображаем диалоговое окно для ввода данных
//   Map<String, String?>? newData = await showDialog(
//     context: context,
//     builder: (BuildContext context) {
//       // Создаем текстовые контроллеры для полей ввода
//       TextEditingController nameController = TextEditingController(text: '${item['name']}');
//       TextEditingController keyController = TextEditingController(text: '${item['key']}');
//       TextEditingController dateShippingController = TextEditingController(text: '${item['date_shipping']}');
//       TextEditingController dogovorController = TextEditingController(text: '${item['dogovor']}');
//       TextEditingController unnOrUnpController = TextEditingController(text: '${item['UNNorUNP']}');
//       TextEditingController remarkController = TextEditingController(text: '${item['remark']}');
//       final TextEditingController _passwordBiosController = TextEditingController();
//       final TextEditingController _passwordRootController = TextEditingController();
//       final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();
//
//
//       return AlertDialog(
//         title: const Text('Изменение элемента'),
//         content: SingleChildScrollView(
//           child: FormBuilder(
//             key: _formKey,
//             child: Column(
//               children: [
//                 TextField(
//                   controller: nameController,
//                   decoration: const InputDecoration(labelText: 'Владелец'),
//                 ),
//                 TextField(
//                   controller: unnOrUnpController,
//                   decoration: const InputDecoration(labelText: 'УНН/УНП'),
//                 ),
//                 TextField(
//                   controller: dateShippingController,
//                   decoration: const InputDecoration(labelText: 'Дата отгрузки'),
//                 ),
//                 TextField(
//                   controller: dogovorController,
//                   decoration: const InputDecoration(labelText: 'Договор'),
//                 ),
//                 TextField(
//                   controller: keyController,
//                   decoration: const InputDecoration(labelText: 'Серийный номер'),
//                 ),
//                 FormBuilderTextField(
//                   name: 'Пароль BIOS',
//                   controller: _passwordBiosController,
//                   decoration: InputDecoration(
//                     labelText: 'Пароль BIOS',
//                     suffixIcon: IconButton(
//                       icon: const Icon(Icons.lock),
//                       onPressed: () {
//                         setState(() {
//                           _passwordBiosController.text = generatePassword();
//                         });
//                       },
//                     ),
//                   ),
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Пароль BIOS не может быть пустым';
//                     } else if (value.length < 6) {
//                       return 'Пароль BIOS должен содержать не менее 6 символов';
//                     } else if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d).+$').hasMatch(value)) {
//                       return 'Пароль BIOS должен содержать как минимум одну букву и одну цифру';
//                     }
//                     return null;
//                   },
//                 ),
//                 FormBuilderTextField(
//                   name: 'Пароль ROOT',
//                   controller: _passwordRootController,
//                   decoration: InputDecoration(
//                     labelText: 'Пароль ROOT',
//                     suffixIcon: IconButton(
//                       icon: const Icon(Icons.lock),
//                       onPressed: () {
//                         setState(() {
//                           _passwordRootController.text = generatePassword();
//                         });
//                       },
//                     ),
//                   ),
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Пароль ROOT не может быть пустым';
//                     } else if (value.length < 6) {
//                       // print('Пароль ROOT должен содержать не менее 6 символов');
//                       return 'Пароль ROOT должен содержать не менее 6 символов';
//                     } else if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d).+$').hasMatch(value)) {
//                       return 'Пароль ROOT должен содержать как минимум одну букву и одну цифру';
//                     }
//                     return null;
//                   },
//                 ),
//                 TextField(
//                   controller: remarkController,
//                   decoration: const InputDecoration(labelText: 'Примечание'),
//                 ),
//               ],
//             ),
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () {
//               if (_formKey.currentState!.validate()) {
//                 // Прошли валидацию
//                 Navigator.of(context).pop({
//                   'name': nameController.text,
//                   'UNNorUNP': unnOrUnpController.text,
//                   'date_shipping': dateShippingController.text,
//                   'dogovor': dogovorController.text,
//                   'key': keyController.text,
//                   'passwordBIOS': _passwordBiosController.text,
//                   'passwordRoot': _passwordRootController.text,
//                   'remark': remarkController.text,
//                 });
//               }
//               // print(_formKey.currentState!.validate().toString().toString());
//               // print('bad validation');
//             },
//             child: const Text('Сохранить'),
//           ),
//           TextButton(
//             onPressed: () {
//               Navigator.of(context).pop(null);
//             },
//             child: const Text('Отмена'),
//           ),
//         ],
//       );
//     },
//   );
//
//   if (newData != null) {
//     final response = await http.put(
//       Uri.parse('$API_URL/api/items/$itemId'),
//       body: jsonEncode(newData),
//       headers: {'Content-Type': 'application/json'},
//     );
//
//     if (response.statusCode == 200) {
//       await   fetchItemsPage(context, (List<Map<String, dynamic>> itemsList) {
//         setState(() {
//           items = itemsList;
//         });
//       });
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           backgroundColor: Colors.green,
//           content: Text('Элемент успешно изменен'),
//           duration: Duration(seconds: 2),
//         ),
//       );
//     } else {
//       showDialog(
//         context: context,
//         builder: (BuildContext context) {
//           return AlertDialog(
//             title: const Text('Ошибка изменения'),
//             content: const Text('Не удалось изменить элемент.'),
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