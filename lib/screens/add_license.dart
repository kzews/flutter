import 'dart:convert';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttersrc/screens/table.dart';
import 'package:fluttersrc/screens/table2.dart';
import 'package:http/http.dart' as http;
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:page_transition/page_transition.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

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
      TextEditingController(text: '');
  final TextEditingController _maxBandwidthController =
      TextEditingController(text: '');
  final TextEditingController _maxUsersController =
      TextEditingController(text: '');
  final TextEditingController _keyController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController(text: '1');
  final TextEditingController _passwordBiosController = TextEditingController();
  final TextEditingController _passwordRootController = TextEditingController();
  final TextEditingController remarkController = TextEditingController();
  var maskFormatter = new MaskTextInputFormatter(
      mask: '##.##.####',
      filter: { "#": RegExp(r'[0-9]') },
      type: MaskAutoCompletionType.lazy
  );


  List<Map<String, dynamic>> items = [];
  String? dateSend;
  String? expireDateForBase;
  DateTime? currentBackPressTime;
  bool _increaseValue = false;
  int _selectedValue = 0;
  int _lastLicenseNumber = 0;


  @override
  void initState() {
    super.initState();
    // fetchItems();
    fetchLastLicenseNumber().then((value) {
      setState(() {
        _lastLicenseNumber = value;
        _keyController.text = _formatLicenseKey(value, _selectedValue, _increaseValue);
      });
    });
    _expiryDateController.addListener(_updateDateSend);
  }

  Future<int> fetchLastLicenseNumber() async {
    final response = await http.get(Uri.parse('$API_URL/api/item'));

    if (response.statusCode == 200) {
      return int.parse(response.body)+1;
    } else {
      throw Exception('Failed to load last license number');
    }
  }

  String _formatLicenseKey(int licenseNumber, int licenseType, bool noRandomSource) {
    String formattedNumber = licenseNumber.toString().padLeft(6, '0');
    String type = '';
    String lastChar = '';

    if ([101, 1, 4, 104].contains(licenseType)) {
      type = 'SERVER';
      lastChar = noRandomSource ? '1' : '2';
    } else if ([2, 102, 5, 105].contains(licenseType)) {
      type = 'BRIDGE';
      lastChar = noRandomSource ? '1' : '2';
    } else if ([3, 103, 6, 106].contains(licenseType)) {
      type = 'CLIENT';
      lastChar = noRandomSource ? '1' : '2';
    }

    return '$formattedNumber-$type$lastChar';
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


  // Future<void> fetchItems() async {
  //   final response = await http.get(Uri.parse('$API_URL/api/items'));
  //
  //   if (response.statusCode == 200) {
  //     final List<dynamic> responseData = json.decode(response.body);
  //     final List<Map<String, dynamic>> itemsList =
  //         List<Map<String, dynamic>>.from(responseData);
  //
  //     setState(() {
  //       items = itemsList;
  //     });
  //   } else {
  //     throw Exception('Failed to load items');
  //   }
  // }

  bool _isLoading = false;

  String? _dateValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Поле не должно быть пустым';
    }
    try {
      DateTime date = DateFormat('dd.MM.yyyy').parseStrict(value);
      if (date.day > 31 || date.day < 1 || date.month > 12 || date.month < 1) {
        return 'Введите корректную дату';
      }
    } catch (e) {
      return 'Введите корректную дату';
    }
    return null;
  }

  Future<void> addItem() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true; // Начало загрузки
      });
      final maxVpnSessions = _maxVpnSessionsController.text.isNotEmpty
          ? int.parse(_maxVpnSessionsController.text)
          : 0; // Замените 0 на нужное значение по умолчанию
      final maxBandwidth = _maxBandwidthController.text.isNotEmpty
          ? int.parse(_maxBandwidthController.text)
          : 0; // Замените 0 на нужное значение по умолчанию
      final maxUsers = _maxUsersController.text.isNotEmpty
          ? int.parse(_maxUsersController.text)
          : 0;
      // Замените 0 на нужное значение по умолчанию
      final passwordBIOS = _passwordBiosController.text.isNotEmpty
          ? _passwordBiosController.text
          : '';
      final passwordRoot = _passwordRootController.text.isNotEmpty
          ? _passwordRootController.text
          : '';
      final _DateController = DateTime.now();
      String month = DateTime.now().month.toString().padLeft(2, '0');
      String day = DateTime.now().day.toString().padLeft(2, '0');
      var _DatenowController = "${day}.${month}.${DateTime.now().year}";
      final response = await http.post(
        Uri.parse('$API_URL/api/items'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'nameCreator': widget.userDto.login,
          'DateCreate': _DatenowController,
          'name': _nameController.text,
          'license_type': int.parse(_licenseTypeController.text),
          'expiry_date': dateSend.toString(),
          'date_shipping': _dateShippingController.text,
          'dogovor': _dogovorController.text,
          'UNNorUNP': _UNNorUNPController.text,
          'max_vpn_sessions': maxVpnSessions,
          'max_bandwidth': maxBandwidth,
          'max_users': maxUsers,
          'key': _keyController.text,
          'qty': int.parse(_qtyController.text),
          'passwordBIOS': passwordBIOS,
          'passwordRoot': passwordRoot,
          'remark': remarkController.text,
          'expireDateForBase': expireDateForBase.toString(),
        }),
      );



      if (response.statusCode == 201) {
        // fetchItems();
        fetchLastLicenseNumber().then((value) {
          setState(() {
            _lastLicenseNumber = value;
            _keyController.text = _formatLicenseKey(value, _selectedValue, _increaseValue);
          });
        });// Обновите список после добавления элемента
        _formKey.currentState!.reset();

        _maxVpnSessionsController.text = '';
        _maxBandwidthController.text = '';
        _maxUsersController.text = '';
        _expiryDateController.text = '';
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
          _isLoading = false; // Конец загрузки
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('Лицензия(ии) успешно добавлена'),
            duration: Duration(seconds: 2),

          ),
        );
      } else {
        setState(() {
          _isLoading = false; // Конец загрузки при ошибке
        });
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
  // Future<void> _selectDate(BuildContext context) async {
  //   DateTime? picked = await showDatePicker(
  //     context: context,
  //     initialDate: DateTime.now(),
  //     firstDate: DateTime(2000),
  //     lastDate: DateTime(2101),
  //     locale: const Locale('en', 'GB'),
  //   );
  //   if (picked != null && picked != DateTime.now()) {
  //     String month = picked.month.toString().padLeft(2, '0');
  //     _expiryDateController.text = "${picked.day}-$month-${picked.year}";
  //     expireDateForBase = _expiryDateController.text;
  //     dateSend ="${picked.year}/${picked.month}/${picked.day}";
  //   }
  // }
  Future<void> _selectShippingDate(BuildContext context) async {
    final DateTime? picked = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DatePickerWidget()),
    );
    if (picked != null && picked != DateTime.now()) {
      setState(() {
        _dateShippingController.text = DateFormat('dd.MM.yyyy').format(picked);
        // expireDateForBase = _expiryDateController.text;
        // dateSend ="${picked.year}/${picked.month}/${picked.day}";
        // print(dateSend);
      });
    }
  }

// Function to show date picker for shipping date
//   Future<void> _selectDateShipping(BuildContext context) async {
//     DateTime? picked = await showDatePicker(
//
//       context: context,
//       locale: Locale('en', 'GB'),
//       initialDate: DateTime.now(),
//       firstDate: DateTime(2000),
//       lastDate: DateTime(2101),
//
//
//     );
//     if (picked != null && picked != DateTime.now()) {
//       String month = picked.month.toString().padLeft(2, '0');
//       _dateShippingController.text =
//           "${picked.day}-$month-${picked.year}";
//     }
//   }


  @override
  void dispose() {
    _expiryDateController.removeListener(_updateDateSend);
    _expiryDateController.dispose();
    super.dispose();
  }

  void _updateDateSend() {
    String inputText = _expiryDateController.text;
    try {
      DateTime parsedDate = DateFormat('dd.MM.yyyy').parseStrict(inputText);
      setState(() {
        dateSend = "${parsedDate.year}/${parsedDate.month}/${parsedDate.day}";
      });
    } catch (e) {
      // Если дата не валидная, не обновляем dateSend
    }
    print(dateSend);
  }
  Future<void> _selectExpiryDate(BuildContext context) async {
    final DateTime? picked = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DatePickerWidget()),
    );
    if (picked != null && picked != DateTime.now()) {
      setState(() {
        _expiryDateController.text = DateFormat('dd.MM.yyyy').format(picked);
        expireDateForBase = _expiryDateController.text;
        dateSend ="${picked.year}/${picked.month}/${picked.day}";
        print(dateSend);
      });
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
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Поле не должно быть пустым';
                            }
                            return null;
                          },
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
                                inputFormatters: [maskFormatter],
                                // onTap: () {
                                //   _selectShippingDate(
                                //       context); // Выбор даты отгрузки
                                // },
                                name: 'date_shipping',
                                controller: _dateShippingController,
                                decoration: const InputDecoration(
                                  labelText: 'Дата отгрузки',
                                ),
                                readOnly: false,
                                validator: _dateValidator,

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
                                _selectShippingDate(context);
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
                          readOnly: true,
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
                              _keyController.text = _formatLicenseKey(_lastLicenseNumber, _selectedValue, _increaseValue);
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Поле не должно быть пустым';
                            }
                            return null;
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
                              _keyController.text = _formatLicenseKey(_lastLicenseNumber, _selectedValue, _increaseValue);
                            });
                          },
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: FormBuilderTextField(
                                inputFormatters: [maskFormatter],
                                // onTap: () {
                                //   _selectExpiryDate(context);
                                // },
                                name: 'expiry_date',
                                controller: _expiryDateController,
                                decoration: const InputDecoration(
                                  labelText: 'Срок действия (гггг/мм/дд)(по умолчанию бессрочная)',
                                ),
                                readOnly: false,
                                validator: _dateValidator,
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
                                _selectExpiryDate(context);
                              },
                            ),
                          ],
                        ),
                        FormBuilderTextField(
                          name: 'max_vpn_sessions',
                          controller: _maxVpnSessionsController,
                          decoration: const InputDecoration(
                            labelText: 'Максимальное кол-во впн сессий(по умолчанию без ограничений)',
                          ),
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                        FormBuilderTextField(
                          name: 'max_bandwidth',
                          controller: _maxBandwidthController,
                          decoration: const InputDecoration(
                            labelText: 'Максимальная пропускная способность(по умолчанию без ограничений)',
                          ),
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                        FormBuilderTextField(
                          name: 'max_users',
                          controller: _maxUsersController,
                          decoration: const InputDecoration(
                            labelText: 'Максимальное количество пользователей(по умолчанию без ограничений)',
                          ),
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                            if (value != null && value.isNotEmpty) {
                              if (value.length < 6) {
                                return 'Пароль BIOS должен содержать не менее 6 символов';
                              } else if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d).+$').hasMatch(value)) {
                                return 'Пароль BIOS должен содержать как минимум одну букву и одну цифру';
                              }
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
                            if (value != null && value.isNotEmpty) {
                              if (value.length < 6) {
                                return 'Пароль ROOT должен содержать не менее 6 символов';
                              } else if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d).+$').hasMatch(value)) {
                                return 'Пароль ROOT должен содержать как минимум одну букву и одну цифру';
                              }
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
                            child: const Text('Создать лицензию(и)', ),
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
                  if (_isLoading)
                    Container(
                      color: Colors.black54,
                      child: Center(
                        child: SpinKitFadingCircle(
                          color: Colors.white,
                          size: 50.0,
                        ),
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



class DatePickerWidget extends StatefulWidget {
  @override
  _DatePickerWidgetState createState() => _DatePickerWidgetState();
}


class _DatePickerWidgetState extends State<DatePickerWidget> {
  DateTime _selectedDate = DateTime.now();
  int _selectedYear = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    // Список доступных годов
    List<int> years = List.generate(101, (index) => 2000 + index);
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white,),
            onPressed: (){
              Navigator.of(context).pop();
            },
          ),
          title: Text('Выбор даты'),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Выберите год: "),
                  DropdownButton<int>(
                    value: _selectedYear,
                    items: years.map((int year) {
                      return DropdownMenuItem<int>(
                        value: year,
                        child: Text(year.toString()),
                      );
                    }).toList(),
                    onChanged: (int? newYear) {
                      if (newYear != null) {
                        setState(() {
                          _selectedYear = newYear;
                          _selectedDate = DateTime(newYear, _selectedDate.month, _selectedDate.day);
                        });
                      }
                    },
                  ),
                ],
              ),
              SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0), // базовый отступ
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    double padding = (constraints.maxWidth > 600)
                        ? (constraints.maxWidth - 600) / 2 // вычисляем отступы для центрации
                        : 16.0; // минимальный отступ

                    return GestureDetector(
                      onTap: () {},
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: padding),
                        child: TableCalendar(
                          locale: 'ru_RU', // Устанавливаем русскую локаль
                          firstDay: DateTime(2000),
                          lastDay: DateTime(2101),
                          focusedDay: _selectedDate,
                          selectedDayPredicate: (day) {
                            return isSameDay(_selectedDate, day);
                          },
                          onDaySelected: (selectedDay, focusedDay) {
                            setState(() {
                              _selectedDate = selectedDay;
                              _selectedYear = selectedDay.year; // обновляем выбранный год
                            });
                            // Navigator.pop(context, selectedDay);
                          },
                          startingDayOfWeek: StartingDayOfWeek.monday, // Неделя начинается с понедельника
                          calendarFormat: CalendarFormat.month,
                          headerStyle: const HeaderStyle(
                            decoration: BoxDecoration(
                              color: Colors.blueAccent,
                            ),
                            headerMargin: EdgeInsets.only(bottom: 8.0),
                            titleTextStyle: TextStyle(color: Colors.white), // Белый цвет текста
                            formatButtonVisible: false, // Убираем кнопку формата
                            leftChevronIcon: Icon(
                              Icons.chevron_left,
                              color: Colors.white,
                            ),
                            rightChevronIcon: Icon(
                              Icons.chevron_right,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, _selectedDate);
                },
                child: Text('Выбрать'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}