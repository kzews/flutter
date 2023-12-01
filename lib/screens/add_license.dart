import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:fluttersrc/screens/registration.dart';
import 'package:fluttersrc/screens/table.dart';
import 'package:fluttersrc/screens/test_page.dart';
import 'package:fluttersrc/screens/users_table.dart';
import 'package:http/http.dart' as http;
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';


import 'dart:convert';

import '../appBar.dart';
import '../objects/userDto.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key, required this.userDto}) : super(key: key);
  final UserDto userDto;

  @override
  _HomePageState createState() => _HomePageState();
}
//TODO придумать что-то с полем даты
class _HomePageState extends State<HomePage> {
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _licenseTypeController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  final TextEditingController _maxVpnSessionsController =
      TextEditingController();
  final TextEditingController _maxBandwidthController = TextEditingController();
  final TextEditingController _maxUsersController = TextEditingController();

  List<Map<String, dynamic>> items = [];

  @override
  void initState() {
    super.initState();
    fetchItems();
  }

  Future<void> fetchItems() async {
    final response =
        await http.get(Uri.parse('http://192.168.202.199:5000/api/items'));

    if (response.statusCode == 200) {
      final List<dynamic> responseData = json.decode(response.body);
      final List<Map<String, dynamic>> itemsList =
          List<Map<String, dynamic>>.from(responseData);

      setState(() {
        items = itemsList;
      });
    } else {
      throw Exception('Failed to load items');
    }
  }

  Future<void> addItem() async {
    if (_formKey.currentState!.validate()) {
      final response = await http.post(
        Uri.parse('http://192.168.202.199:5000/api/items'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'name': _nameController.text,
          'license_type': int.parse(_licenseTypeController.text),
          'expiry_date': _expiryDateController.text,
          'max_vpn_sessions': int.parse(_maxVpnSessionsController.text),
          'max_bandwidth': _maxBandwidthController.text,
          'max_users': int.parse(_maxUsersController.text),
        }),
      );

      if (response.statusCode == 201) {
        fetchItems(); // Обновите список после добавления элемента
        _formKey.currentState!.reset();
      } else {
        throw Exception('Failed to add item');
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final Object? userDto = ModalRoute.of(context)!.settings.arguments;
    return Scaffold(
      appBar: CustomAppBar(userDto: widget.userDto),
      drawer: AppDrawer(userDto: widget.userDto),
      body: Column(
        children: [
          FormBuilder(
            key: _formKey,
            child: Column(
              children: [
                FormBuilderTextField(
                  name: 'name',
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Владелец'),
                ),
                FormBuilderDropdown(
                  name: 'license_type',
                  decoration: const InputDecoration(labelText: 'Тип лицензии'),
                  items: [
                    DropdownMenuItem(
                      value: 1,
                      child: Text('Сервер'),
                    ),
                    DropdownMenuItem(
                      value: 3,
                      child: Text('Клиент'),
                    ),
                    DropdownMenuItem(
                      value: 2,
                      child: Text('Мост'),
                    ),
                  ],
                  onChanged: (value) {
                    // Обработка выбора значения
                    _licenseTypeController.text = value.toString();
                  },
                ),

                FormBuilderTextField(
                  name: 'expiry_date',
                  controller: _expiryDateController,
                  decoration: const InputDecoration(
                    labelText: 'Срок действия (гггг/мм/дд)',
                  ),
                  inputFormatters: [
                    _DateInputFormatter(),
                  ],
                ),
                FormBuilderTextField(
                  name: 'max_vpn_sessions',
                  controller: _maxVpnSessionsController,
                  decoration: const InputDecoration(
                      labelText: 'Максимальное количество VPN сессий'),
                ),
                FormBuilderTextField(
                  name: 'max_bandwidth',
                  controller: _maxBandwidthController,
                  decoration: const InputDecoration(
                      labelText: 'Максимальная пропускная способность'),
                ),
                FormBuilderTextField(
                  name: 'max_users',
                  controller: _maxUsersController,
                  decoration: const InputDecoration(
                      labelText: 'Максимальное количество пользователей'),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: addItem,
            child: const Text('Добавить элемент'),
          ),
          ElevatedButton(
            onPressed: () async {
              await Navigator.pushReplacement(
                context,
                CupertinoPageRoute(
                    builder: (context) => TablePage(userDto: widget.userDto)),
              );
            },
            child: const Text('переход к таблице'),
          ),
        ],
      ),
    );
  }
}
class _DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    var text = newValue.text;

    if (text.length == 4 || text.length == 7) {
      // User entered a forward slash, move to the next position
      text += '/';
    }

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}