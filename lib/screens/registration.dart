import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:fluttersrc/objects/userDto.dart';
import 'package:fluttersrc/screens/users_table.dart';
import 'package:http/http.dart' as http;

import '../appBar.dart';

class RegisterPage extends StatefulWidget {
  RegisterPage({Key? key, required this.userDto}) : super(key: key);
  final UserDto userDto;

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

String? selectedRole;

class _RegisterPageState extends State<RegisterPage> {
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _passwordTypeController = TextEditingController();
  //final TextEditingController _roleController = TextEditingController();

  List<Map<String, dynamic>> items = [];

  Future<void> addItem() async {
    if (_formKey.currentState!.validate()) {
      final response = await http.post(
        Uri.parse('http://192.168.202.199:5000/api/register'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'login': _loginController.text,
          'password': _passwordTypeController.text,
          'role': selectedRole, // Используйте выбранную роль здесь
        }),
      );

      if (response.statusCode == 201) {
        // Обновите список после добавления элемента
        _formKey.currentState!.reset();
      } else {
        if (response.statusCode == 400) {
          print(response.statusCode);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.red,
              content:
              Text('Логин уже занят! Используйте другой логин'),
              duration: Duration(
                  seconds: 2), // Длительность отображения Snackbar
            ),
          );
          throw Exception('Failed to add item');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  name: 'login',
                  controller: _loginController,
                  decoration: const InputDecoration(labelText: 'Имя'),
                ),
                FormBuilderTextField(
                  name: 'password',
                  controller: _passwordTypeController,
                  decoration: const InputDecoration(labelText: 'Пароль'),
                ),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(labelText: 'Роль'),
                  value: selectedRole,
                  items: ['admin', 'user'].map((role) {
                    return DropdownMenuItem<String>(
                      value: role,
                      child: Text(role),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      selectedRole = newValue;
                    });
                  },
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: addItem,
            child: const Text('Добавить usera'),
          ),
          ElevatedButton(
            onPressed: () async {
              await Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => UsersPage(
                    userDto: widget.userDto,
                  ),
                ),
              );
            },
            child: const Text('Пользователи'),
          ),
        ],
      ),
    );
  }
}
