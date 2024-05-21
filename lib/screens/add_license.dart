import 'dart:convert';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:fluttersrc/screens/table.dart';
import 'package:fluttersrc/screens/table2.dart';
import 'package:http/http.dart' as http;
import 'package:page_transition/page_transition.dart';

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
  final TextEditingController _dateShippingController = TextEditingController();
  final TextEditingController _dogovorController = TextEditingController();
  final TextEditingController _UNNorUNPController = TextEditingController();
  final TextEditingController _maxVpnSessionsController =
      TextEditingController(text: '0');
  final TextEditingController _maxBandwidthController =
      TextEditingController(text: '0');
  final TextEditingController _maxUsersController =
      TextEditingController(text: '0');
  final TextEditingController _keyController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController(text: '1');
  final TextEditingController _passwordBiosController = TextEditingController();
  final TextEditingController _passwordRootController = TextEditingController();
  final TextEditingController remarkController = TextEditingController();



  List<Map<String, dynamic>> items = [];
  String? dateSend;
  String? expireDateForBase;
  DateTime? currentBackPressTime;
  bool _increaseValue = false;
  int _selectedValue = 0;
  bool _isBiosPasswordValid = false;
  bool _isRootPasswordValid = false;

  // int _parseToInt(String? value) {
  //   return value != null ? int.parse(value) : 0;
  // }

  @override
  void initState() {
    super.initState();
    fetchItems();
  }

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
          'nameCreator': widget.userDto.login,
          'DateCreate': DateTime.now().toString().split('.').first,
          'name': _nameController.text,
          'license_type': int.parse(_licenseTypeController.text),
          'expiry_date': dateSend.toString(),
          'date_shipping': _dateShippingController.text,
          'dogovor': _dogovorController.text,
          'UNNorUNP': _UNNorUNPController.text,
          'max_vpn_sessions': int.parse(_maxVpnSessionsController.text),
          'max_bandwidth': _maxBandwidthController.text,
          'max_users': int.parse(_maxUsersController.text),
          'key': _keyController.text,
          'qty': int.parse(_qtyController.text),
          'passwordBIOS': _passwordBiosController.text,
          'passwordRoot': _passwordRootController.text,
          'remark': remarkController.text,
          'expireDateForBase': expireDateForBase.toString(),
        }),
      );



      if (response.statusCode == 201) {
        fetchItems(); // Обновите список после добавления элемента
        _formKey.currentState!.reset();

        // Сбросить значения контроллеров текстовых полей на "0"
        _maxVpnSessionsController.text = '0';
        _maxBandwidthController.text = '0';
        _maxUsersController.text = '0';
        _expiryDateController.text = '';
        // Сбросить значения контроллеров для "Владелец" и "Серийный номер"
        _nameController.text = '';
        _keyController.text = '';
        _qtyController.text = '1';
        _dogovorController.text = '';
        _dateShippingController.text = '';
        _UNNorUNPController.text = '';
        _passwordBiosController.text ='';
        _passwordRootController.text = '';
        remarkController.text = '';

        // Сбросить значения для FormBuilderDropdown
        setState(() {
          _selectedValue = 0;
          _increaseValue = false;
          _licenseTypeController.text = _selectedValue.toString();
        });
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
      String month = picked.month.toString().padLeft(2, '0');
      _expiryDateController.text = "${picked.day}-$month-${picked.year}";
      expireDateForBase = _expiryDateController.text;
      dateSend ="${picked.year}/${picked.month}/${picked.day}";
    }
  }

// Function to show date picker for shipping date
  Future<void> _selectDateShipping(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != DateTime.now()) {
      String month = picked.month.toString().padLeft(2, '0');
      _dateShippingController.text =
          "${picked.day}-$month-${picked.year}";
    }
  }

  Future<void> _condirmBackToTable() async {
     await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Подтверждение отмены'),
          content: const Text(
              'Вы уверены, что хотите отменить добавление лицензии?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  PageTransition(
                    type: PageTransitionType.leftToRight,
                    child: TablePage(userDto: widget.userDto),
                  ),
                ); // Пользователь подтвердил удаление
              },
              child: const Text('Да'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Пользователь отменил удаление
              },
              child: const Text('Нет'),
            ),
          ],
        );
      },
    );
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
        body: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width > 1000
                    ? 0.3 * MediaQuery.of(context).size.width
                    : MediaQuery.of(context).size.width < 750
                        ? 20
                        : 300,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FormBuilder(
                    key: _formKey,
                    // autovalidateMode: AutovalidateMode.disabled,
                    child: Column(
                      children: [
                        FormBuilderTextField(
                          name: 'Владелец',
                          controller: _nameController,
                          decoration:
                              const InputDecoration(labelText: 'Владелец'),
                        ),
                        FormBuilderTextField(
                          name: 'UNNorUNP',
                          controller: _UNNorUNPController,
                          decoration:
                              const InputDecoration(labelText: 'УНН/УНП'),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: FormBuilderTextField(
                                onTap: () {
                                  _selectDateShipping(
                                      context); // Выбор даты отгрузки
                                },
                                name: 'date_shipping',
                                controller: _dateShippingController,
                                decoration: const InputDecoration(
                                  labelText: 'Дата отгрузки',
                                ),
                                readOnly: true,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _dateShippingController.clear();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.calendar_today),
                              onPressed: () {
                                _selectDateShipping(context);
                              },
                            ),
                          ],
                        ),
                        FormBuilderTextField(
                          name: 'dogovor',
                          controller: _dogovorController,
                          decoration:
                              const InputDecoration(labelText: 'Договор'),
                        ),
                        FormBuilderTextField(
                          name: 'Серийный номер',
                          controller: _keyController,
                          decoration: const InputDecoration(
                              labelText: 'Серийный номер'),
                        ),
                        FormBuilderTextField(
                          name: 'Количество лицензий',
                          controller: _qtyController,
                          decoration: const InputDecoration(
                              labelText: 'Количество продуктов'),
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
                            setState(() {
                              _selectedValue = value ?? 0;
                              if (_increaseValue) {
                                _selectedValue += 100;
                              }
                              _licenseTypeController.text =
                                  _selectedValue.toString();
                            });
                          },
                        ),
                        CheckboxListTile(
                          title: const Text('Без физического источника случайности'),
                          contentPadding: EdgeInsets.zero,
                          value: _increaseValue,
                          onChanged: (newValue) {
                            setState(() {
                              _increaseValue = newValue!;
                              if (_increaseValue) {
                                _selectedValue += 100;
                              } else {
                                _selectedValue -=
                                    100; // Уменьшаем значение на 100, если чекбокс был отключен
                              }
                              _licenseTypeController.text =
                                  _selectedValue.toString();
                            });
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
                              labelText: 'Максимальное кол-во впн сессий'),
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
                              labelText:
                                  'Максимальное количество пользователей'),
                        ),
                        FormBuilderTextField(
                          name: 'Пароль BIOS',
                          controller: _passwordBiosController,
                          decoration: InputDecoration(
                            labelText: 'Пароль BIOS',
                            suffixIcon: IconButton(
                              icon: Icon(Icons.lock),
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
                              icon: Icon(Icons.lock),
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
                              return 'Пароль ROOT должен содержать не менее 6 символов';
                            } else if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d).+$').hasMatch(value)) {
                              return 'Пароль ROOT должен содержать как минимум одну букву и одну цифру';
                            }
                            return null;
                          },
                        ),
                        FormBuilderTextField(
                          name: 'Примечание',
                          controller: remarkController,
                          decoration: const InputDecoration(
                              labelText: 'Примечание'),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width > 1500
                          ? 200
                          : MediaQuery.of(context).size.width > 1000
                          ? 50
                          : 50,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded( // Добавляем Expanded
                          child: ElevatedButton(
                            onPressed: () {
                              if (_formKey.currentState?.validate() ?? false) {
                                // Прошли валидацию
                                addItem();
                              }
                              print('bad validation');
                              // Не прошли валидацию
                            },
                            child: const Text('Сгенерировать лицензию(и)'),
                          ),
                        ),
                        const SizedBox(width: 8), // Add spacing between buttons
                        Expanded( // Добавляем Expanded
                          child: ElevatedButton(
                            onPressed: () async {
                              _condirmBackToTable();
                            },
                            child: const Text('Переход к таблице'),
                          ),
                        ),
                      ],
                    ),
                  ),

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
