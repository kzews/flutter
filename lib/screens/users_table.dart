import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttersrc/appBar.dart';
import 'package:http/http.dart' as http;

import '../objects/userDto.dart';

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

class UsersPage extends StatefulWidget {
  final UserDto userDto;

  const UsersPage({required this.userDto, Key? key}) : super(key: key);

  @override
  _UsersPageState createState() => _UsersPageState();
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

class _UsersPageState extends State<UsersPage> {
  List<Map<String, dynamic>> items = [];
  List<Map<String, dynamic>> filteredItems = [];
  bool _sortAscending = true;
  int _sortColumnIndex = 0;
  TextEditingController loginController = TextEditingController();
  TextEditingController passwordFilterController = TextEditingController();
  TextEditingController roleFilterController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchItems(widget.userDto);
  }

  Future<void> _deleteItem(int itemId, userDto) async {
    bool confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Подтверждение удаления'),
          content: const Text('Вы уверены, что хотите удалить запись?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context)
                    .pop(true); // Пользователь подтвердил удаление
              },
              child: const Text('Да'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context)
                    .pop(false); // Пользователь отменил удаление
              },
              child: const Text('Нет'),
            ),
          ],
        );
      },
    );

    if (confirmDelete) {
      try {
        Dio dio = Dio();
        Response response = await dio.delete(
          'http://192.168.202.199:5000/api/users/$itemId',
          data: jsonEncode(userDto),
          options: Options(headers: {
            'Content-Type': 'application/json',
            // Добавьте другие необходимые заголовки здесь
          }),
        );

        if (response.statusCode == 200) {
          // Элемент успешно удален, обновите список элементов
          await fetchItems(widget.userDto);

          // Отобразите успешное сообщение
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.green,
              content: Text('Элемент успешно удален'),
              duration:
                  Duration(seconds: 2), // Длительность отображения Snackbar
            ),
          );
        } else {
          // Обработайте ошибку удаления здесь
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Ошибка удаления'),
                content: const Text('Не удалось удалить элемент.'),
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
      } catch (error) {
        // Обработайте ошибки Dio здесь
        print(error.toString());
      }
    }
  }

  Future<void> _updateUser(
      int itemId, String login, String password, String role) async {
    final response = await http.put(
      Uri.parse('http://192.168.202.199:5000/api/users/$itemId'),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, String>{
        'login': login,
        'password': password,
        'role': role,
      }),
    );

    if (response.statusCode == 200) {
      // Пользователь успешно обновлен
      // Обработайте успешный ответ по вашему усмотрению
    } else {
      print(response.statusCode);
      if (response.statusCode == 400) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text('Данный Логин уже занят! Используйте другой логин!'),
            duration: Duration(seconds: 2), // Длительность отображения Snackbar
          ),
        );
        print("invalid login");
      }
      // Обработка ошибок при обновлении пользователя
      // Показать сообщение об ошибке или выполнить другие действия
    }
  }

  Future<void> fetchItems(userDto) async {
    Dio dio = Dio();
    try {
      var response = await dio.post(
        'http://192.168.202.199:5000/api/registerPersons',
        data: jsonEncode(userDto),
        options: Options(
          contentType: "application/json",
          responseType: ResponseType.plain,
        ),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('Загружено успешно'),
            duration: Duration(seconds: 2), // Длительность отображения Snackbar
          ),
        );
        final List<dynamic> responseData = json.decode(response.data);
        final List<Map<String, dynamic>> itemsList =
            List<Map<String, dynamic>>.from(responseData);

        setState(() {
          items = itemsList;
        });
      } else if (response.statusCode == 403) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content:
                Text('для просмотра нужно обладать правами администратора'),
            duration: Duration(seconds: 2), // Длительность отображения Snackbar
          ),
        );
        throw Exception('Failed to load items');
      }
    } catch (error) {
      print(error);
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

  void _filterItems() {
    // fetchItems(widget.userDto);
    final loginFilter = loginController.text.toLowerCase();
    final passwordTypeFilter = passwordFilterController.text.toLowerCase();
    final roleFilter = roleFilterController.text.toLowerCase();

    setState(() {
      filteredItems = items.where((item) {
        final login = item['login'].toString().toLowerCase();
        final password = item['password'].toString().toLowerCase();
        final role = item['role'].toString().toLowerCase();
        return login.contains(loginFilter) &&
            password.contains(passwordTypeFilter) &&
            role.contains(roleFilter);
      }).toList();
    });
  }

  Future<void> _showEditDialog(Map<String, dynamic> item) async {
    TextEditingController loginController =
        TextEditingController(text: item['login']);
    TextEditingController passwordController =
        TextEditingController(text: item['password']);
    TextEditingController roleController =
        TextEditingController(text: item['role']);

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Изменить данные'),
          content: Column(
            children: [
              TextField(
                controller: loginController,
                decoration: const InputDecoration(labelText: 'Логин'),
              ),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Пароль'),
              ),
              TextField(
                controller: roleController,
                decoration: const InputDecoration(labelText: 'Роль'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Закрыть диалоговое окно
              },
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () {
                _updateUser(item['id'], loginController.text,
                    passwordController.text, roleController.text);
                fetchItems(widget.userDto);
                Navigator.of(context)
                    .pop(); // Закрыть диалоговое окно после сохранения
              },
              child: const Text('Сохранить и обновить'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Object? userDto = ModalRoute.of(context)!.settings.arguments;
    // double bottomPadding =
    //     MediaQuery.of(context).size.height * 0.05; // 5% высоты экрана
    return Scaffold(
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
                    controller: loginController,
                    onChanged: (value) {
                      _filterItems();
                    },
                    decoration: const InputDecoration(
                      labelText: 'Фильтр по логину',
                    ),
                  ),
                  // TextField(
                  //   controller: passwordFilterController,
                  //   onChanged: (value) {
                  //     _filterItems();
                  //   },
                  //   decoration: const InputDecoration(
                  //     labelText: 'Фильтр по паролю',
                  //   ),
                  // ),
                  TextField(
                    controller: roleFilterController,
                    onChanged: (value) {
                      _filterItems();
                    },
                    decoration: const InputDecoration(
                      labelText: 'Фильтр по роли',
                    ),
                  ),
                ],
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: DataTable(
                    border: TableBorder.all(
                      width: 2.0,
                      color: Colors.black45,
                    ),
                    // headingRowHeight: 200,
                    columnSpacing: 1,
                    sortAscending: _sortAscending,
                    sortColumnIndex: _sortColumnIndex,
                    columns: <DataColumn>[
                      DataColumn(
                        // label: VerticalTextCell('название'),
                        label: const Icon(Icons.person),
                        tooltip: 'логин',
                        onSort: (columnIndex, ascending) {
                          setState(() {
                            _sortAscending = ascending;
                            _sortColumnIndex = columnIndex;
                            _sort((item) => item['login'], columnIndex,
                                ascending);
                          });
                        },
                      ),
                      DataColumn(
                        // label: VerticalTextCell('дата\nдобавления'),
                        label: const Icon(Icons.personal_injury_rounded),
                        tooltip: 'пароль',
                        onSort: (columnIndex, ascending) {
                          setState(() {
                            _sortAscending = ascending;
                            _sortColumnIndex = columnIndex;
                            _sort((item) => item['password'], columnIndex,
                                ascending);
                          });
                        },
                      ),
                      DataColumn(
                        // label: VerticalTextCell('срок'),
                        label: const Icon(Icons.person_search_rounded),
                        tooltip: 'роль',
                        onSort: (columnIndex, ascending) {
                          setState(() {
                            _sortAscending = ascending;
                            _sortColumnIndex = columnIndex;
                            _sort(
                                (item) => item['role'], columnIndex, ascending);
                          });
                        },
                      ),
                      const DataColumn(
                        // label: VerticalTextCell('Действия'),
                        label: Icon(
                          Icons.delete_outline_outlined,
                          color: Colors.red,
                        ),
                      ),
                      const DataColumn(
                        // label: VerticalTextCell('Действия'),
                        label: Icon(
                          Icons.edit,
                          color: Colors.red,
                        ),
                      ),
                    ],
                    rows: (loginController.text.isEmpty &&
                            passwordFilterController.text.isEmpty &&
                            roleFilterController.text.isEmpty)
                        ? items.map(
                            (item) {
                              return DataRow(
                                cells: <DataCell>[
                                  // DataCell(Text(item['id'].toString())),
                                  // DataCell(
                                  //   TextFormField(
                                  //     initialValue: item['login'], // Устанавливаем начальное значение поля
                                  //     onChanged: (newValue) {
                                  //       // Обработка изменений в поле login
                                  //       item['login'] = newValue;// Обновляем значение в вашем источнике данных
                                  //     },
                                  //
                                  //   ),
                                  // ),
                                  DataCell(Text(item['login'].toString())),
                                  DataCell(Text(item['password'].toString())),
                                  DataCell(Text(item['role'].toString())),
                                  DataCell(
                                    ElevatedButton(
                                      onPressed: () {
                                        _deleteItem(item['id'], userDto);
                                      },
                                      child: const Icon(
                                        Icons.delete,
                                        color: Colors.white, // цвет иконки
                                      ),
                                    ),
                                  ),

                                  DataCell(
                                    ElevatedButton(
                                      onPressed: () {
                                        _showEditDialog(item);
                                      },
                                      child: const Icon(
                                        Icons.edit,
                                        color: Colors.white, // цвет иконки
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ).toList()
                        : filteredItems.map(
                            (item) {
                              return DataRow(
                                cells: <DataCell>[
                                  // DataCell(
                                  //   TextFormField(
                                  //     initialValue: item['login'], // Устанавливаем начальное значение поля
                                  //     onChanged: (newValue) {
                                  //       // Обработка изменений в поле login
                                  //       item['login'] = newValue;// Обновляем значение в вашем источнике данных
                                  //     },
                                  //
                                  //   ),
                                  // ),
                                  DataCell(Text(item['login'].toString())),
                                  DataCell(Text(item['password'].toString())),
                                  DataCell(Text(item['role'].toString())),

                                  // DataCell(Text(item['license_key'].toString())),
                                  DataCell(
                                    ElevatedButton(
                                      onPressed: () {
                                        _deleteItem(item['id'], userDto);
                                      },
                                      child: const Icon(
                                        Icons.delete,
                                        color: Colors.white, // цвет иконки
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    ElevatedButton(
                                      onPressed: () {
                                        _showEditDialog(item);
                                      },
                                      child: const Icon(
                                        Icons.edit,
                                        color: Colors.white, // цвет иконки
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ).toList(),
                  ),
                ),
              ),
            ),
            // Positioned(
            //   bottom: bottomPadding,
            //   right: bottomPadding,
            //   child: FloatingActionButton(
            //     onPressed: () {
            //       // Обработка нажатия кнопки добавления пользователя
            //       // Например, откройте новый экран для добавления пользователя
            //       Navigator.push(
            //         context,
            //         MaterialPageRoute(
            //           builder: (context) => RegisterPage(userDto: widget.userDto),
            //         ),
            //       );
            //     },
            //     child: Icon(Icons.person_add_alt_rounded),
            //   ),
            // ),
          ],
        ),
      ),

      ///////////////
    );
  }
}
