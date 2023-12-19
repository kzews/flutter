import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttersrc/appBar.dart';
import 'package:http/http.dart' as http;

import '../objects/userDto.dart';
import '../services/backButton.dart';

// void main() {
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Flutter Database App',
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//       ),
//       home: TablePage(userDto: ,),
//     );
//   }
// }

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
  List<Map<String, dynamic>> items = [];
  List<Map<String, dynamic>> filteredItems = [];
  bool _sortAscending = true;
  int _sortColumnIndex = 0;
  DateTime? currentBackPressTime;

  TextEditingController nameFilterController = TextEditingController();
  TextEditingController licenseTypeFilterController = TextEditingController();
  TextEditingController licenseNumberFilterController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchItems();
  }

  Future<void> _deleteItem(int itemId) async {
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
      final response = await http.delete(
        Uri.parse('http://192.168.202.199:5000/api/items/$itemId'),
      );

      if (response.statusCode == 200) {
        // Элемент успешно удален, обновите список элементов
        await fetchItems();

        // Отобразите успешное сообщение
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('Элемент успешно удален'),
            duration: Duration(seconds: 2), // Длительность отображения Snackbar
          ),
        );
      } else {
        // Обработайте ошибку удаления здесь, например, показав диалоговое окно с сообщением об ошибке
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
    }
  }

  Future<void> fetchItems() async {
    try {
      final response =
          await http.get(Uri.parse('http://192.168.202.199:5000/api/items'));

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

  void _filterItems() {
    final nameFilter = nameFilterController.text.toLowerCase();
    final licenseTypeFilter = licenseTypeFilterController.text.toLowerCase();
    final licenseNumberFilter =
        licenseNumberFilterController.text.toLowerCase();

    setState(() {
      filteredItems = items.where((item) {
        final name = item['name'].toString().toLowerCase();

        final licenseType = item['license_type'].toString().toLowerCase();
        final licenseNumber = item['license_number'].toString().toLowerCase();
        return name.contains(nameFilter) &&
            licenseType.contains(licenseTypeFilter) &&
            licenseNumber.contains(licenseNumberFilter);
      }).toList();
    });
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
                        _filterItems();
                      },
                      decoration: const InputDecoration(
                        labelText: 'Фильтр по названию',
                      ),
                    ),
                    TextField(
                      controller: licenseTypeFilterController,
                      onChanged: (value) {
                        _filterItems();
                      },
                      decoration: const InputDecoration(
                        labelText: 'Фильтр по типу лицензии',
                      ),
                    ),
                    // TextField(
                    //   controller: licenseNumberFilterController,
                    //   onChanged: (value) {
                    //     _filterItems();
                    //   },
                    //   decoration: const InputDecoration(
                    //     labelText: 'Фильтр по номеру лицензии',
                    //   ),
                    // ),
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
                          label: const Icon(Icons.account_box),
                          tooltip: 'Владелец',
                          onSort: (columnIndex, ascending) {
                            setState(() {
                              _sortAscending = ascending;
                              _sortColumnIndex = columnIndex;
                              _sort((item) => item['name'], columnIndex,
                                  ascending);
                            });
                          },
                        ),
                        // DataColumn(
                        //   // label: VerticalTextCell('дата\nдобавления'),
                        //   label: const Icon(Icons.access_alarm),
                        //   tooltip: 'дата\nдобавления',
                        //   onSort: (columnIndex, ascending) {
                        //     setState(() {
                        //       _sortAscending = ascending;
                        //       _sortColumnIndex = columnIndex;
                        //       _sort((item) => item['date_added'], columnIndex,
                        //           ascending);
                        //     });
                        //   },
                        // ),
                        DataColumn(
                          // label: VerticalTextCell('срок'),
                          label: const Center(child: Icon(Icons.date_range)),
                          tooltip: 'срок',
                          onSort: (columnIndex, ascending) {
                            setState(() {
                              _sortAscending = ascending;
                              _sortColumnIndex = columnIndex;
                              _sort((item) => item['expiry_date'], columnIndex,
                                  ascending);
                            });
                          },
                        ),
                        DataColumn(
                          // label: VerticalTextCell('пропускная\nспособность'),
                          label: const Icon(
                            Icons.network_check,
                          ),
                          tooltip: 'пропускная\nспособность',
                          onSort: (columnIndex, ascending) {
                            setState(() {
                              _sortAscending = ascending;
                              _sortColumnIndex = columnIndex;
                              _sort((item) => item['max_bandwidth'],
                                  columnIndex, ascending);
                            });
                          },
                        ),
                        DataColumn(
                          // label: VerticalTextCell('макс кол-во\nпользователей'),
                          label: const Icon(
                            Icons.people,
                          ),
                          tooltip: 'макс кол-во\nпользователей',
                          onSort: (columnIndex, ascending) {
                            setState(() {
                              _sortAscending = ascending;
                              _sortColumnIndex = columnIndex;
                              _sort((item) => item['max_users'], columnIndex,
                                  ascending);
                            });
                          },
                        ),
                        DataColumn(
                          // label: VerticalTextCell('макс кол-во\nсессий'),
                          label: const Icon(Icons.account_tree),
                          tooltip: 'макс кол-во сессий',
                          onSort: (columnIndex, ascending) {
                            setState(() {
                              _sortAscending = ascending;
                              _sortColumnIndex = columnIndex;
                              _sort((item) => item['max_vpn_sessions'],
                                  columnIndex, ascending);
                            });
                          },
                        ),
                        DataColumn(
                          // label: VerticalTextCell('тип лицензии'),
                          label: const Icon(Icons.format_list_numbered_rounded),
                          tooltip: 'тип лицензии',
                          onSort: (columnIndex, ascending) {
                            setState(() {
                              _sortAscending = ascending;
                              _sortColumnIndex = columnIndex;
                              _sort((item) => item['license_type'], columnIndex,
                                  ascending);
                            });
                          },
                        ),
                        // DataColumn(
                        //   label: const Icon(Icons.numbers),
                        //   tooltip: 'номер лицензии',
                        //   onSort: (columnIndex, ascending) {
                        //     setState(() {
                        //       _sortAscending = ascending;
                        //       _sortColumnIndex = columnIndex;
                        //       _sort((item) => item['license_number'], columnIndex,
                        //           ascending);
                        //     });
                        //   },
                        // ),
                        const DataColumn(
                          // label: VerticalTextCell('Действия'),
                          label: Icon(
                            Icons.delete_outline_outlined,
                            color: Colors.red,
                          ),
                        ),
                      ],
                      rows: (nameFilterController.text.isEmpty &&
                              licenseTypeFilterController.text.isEmpty &&
                              licenseNumberFilterController.text.isEmpty)
                          ? items.map(
                              (item) {
                                return DataRow(
                                  cells: <DataCell>[
                                    // DataCell(Text(item['id'].toString())),
                                    DataCell(
                                      Center(
                                        child: Text(item['name']),
                                      ),
                                    ),
                                    // DataCell(Text(item['date_added'].toString())),
                                    DataCell(
                                      Text(
                                        item['expiry_date'].toString().isEmpty
                                            ? 'бессрочно'
                                            : item['expiry_date'].toString(),
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
                                      Text(
                                        item['max_users'] == 0
                                            ? '∞' // or any other symbol or text
                                            : item['max_users'].toString(),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        item['max_vpn_sessions'] == 0
                                            ? '∞' // or any other symbol or text
                                            : item['max_vpn_sessions']
                                                .toString(),
                                      ),
                                    ),

                                    DataCell(
                                      Text(
                                        item['license_type'].toString(),
                                      ),
                                    ),
                                    // DataCell(
                                    //     Text(item['license_number'].toString())),
                                    DataCell(
                                      ElevatedButton(
                                        onPressed: () {
                                          _deleteItem(item['id']);
                                        },
                                        child: const Icon(
                                          Icons.delete,
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
                                    DataCell(
                                      Text(item['name']),
                                    ),
                                    // DataCell(Text(item['date_added'].toString())),
                                    DataCell(
                                        Text(item['expiry_date'].toString())),
                                    DataCell(
                                        Text(item['max_bandwidth'].toString())),
                                    DataCell(
                                        Text(item['max_users'].toString())),
                                    DataCell(Text(
                                        item['max_vpn_sessions'].toString())),
                                    DataCell(
                                        Text(item['license_type'].toString())),
                                    // DataCell(
                                    //     Text(item['license_number'].toString())),
                                    // DataCell(Text(item['license_key'].toString())),
                                    DataCell(
                                      ElevatedButton(
                                        onPressed: () {
                                          _deleteItem(item['id']);
                                        },
                                        child: const Icon(
                                          Icons.delete,
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
            ],
          ),
        ),
      ),
    );
  }
}
