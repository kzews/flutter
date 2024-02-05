import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:fluttersrc/screens/table.dart';
import 'package:http/http.dart' as http;

import '../appBar.dart';
import '../environment.dart';
import '../objects/userDto.dart';
import '../services/backButton.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key, required this.userDto}) : super(key: key);
  final UserDto userDto;

  @override
  _HomePageState createState() => _HomePageState();
}

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
  DateTime? currentBackPressTime;

  @override
  void initState() {
    super.initState();
    fetchItems();
  }

  Future<void> fetchItems() async {
    final response = await http.get(Uri.parse('$API_URL/api/items'));

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
        Uri.parse('$API_URL/api/items'),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('Лицензия успешно добавлена'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        if (response.statusCode == 400) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.red,
              content: Text('Неверный формат даты'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        throw Exception('Failed to add item');
      }
    }
  }

  // Function to show date picker
  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != DateTime.now()) {
      _expiryDateController.text =
          "${picked.year}/${picked.month}/${picked.day}";
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return backButton(context);
      },
      child: Scaffold(
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
                    decoration:
                        const InputDecoration(labelText: 'Тип лицензии'),
                    items: const [
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
                      DropdownMenuItem(
                        value: 4,
                        child: Text('Сервер с кодом подтверждения'),
                      ),
                      DropdownMenuItem(
                        value: 6,
                        child: Text('Клиент с кодом подтверждения'),
                      ),
                      DropdownMenuItem(
                        value: 5,
                        child: Text('Мост с кодом подтверждения'),
                      ),
                    ],
                    onChanged: (value) {
                      // Обработка выбора значения
                      _licenseTypeController.text = value.toString();
                    },
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: FormBuilderTextField(
                          onTap: () {
                            _selectDate(context);
                          },
                          name: 'expiry_date',
                          controller: _expiryDateController,
                          decoration: const InputDecoration(
                            labelText: 'Срок действия (гггг/мм/дд)',
                          ),
                          readOnly: true,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _expiryDateController.clear();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () {
                          _selectDate(context);
                        },
                      ),
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
      ),
    );
  }
}
