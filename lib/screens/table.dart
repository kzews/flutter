import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttersrc/appBar.dart';
import 'package:http/http.dart' as http;
import 'package:page_transition/page_transition.dart';

import '../objects/userDto.dart';
import '../services/backButton.dart';

import 'dart:io' show Platform;

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
  List<Map<String, dynamic>> items = [];
  List<Map<String, dynamic>> filteredItems = [];
  bool _sortAscending = true;
  int _sortColumnIndex = 0;
  DateTime? currentBackPressTime;

  TextEditingController nameFilterController = TextEditingController();
  TextEditingController licenseTypeFilterController = TextEditingController();
  TextEditingController licenseNumberFilterController = TextEditingController();
  TextEditingController licenseKeyFilterController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchItems();
  }

  Future<void> _showLicenseDetailsDialog(
      BuildContext context, Map<String, dynamic> item) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        bool isActivationButtonVisible = !(item['license_type'] == 1 ||
            item['license_type'] == 2 ||
            item['license_type'] == 3);
        return Scaffold(
          body: AlertDialog(
            title: const Text('Данные лицензии'),

            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Владелец: ${item['name']}'),
                Text(
                    'Срок: ${item['expiry_date'].toString().isEmpty ? 'бессрочно' : item['expiry_date']}'),
                Text(
                    'Пропускная способность: ${item['max_bandwidth'] == '0' ? 'без ограничений' : item['max_bandwidth']}'),
                Text(
                    'Максимальное количество пользователей: ${item['max_users'] == 0 ? 'без ограничений' : item['max_users']}'),
                Text(
                    'Максимальное количество сессий: ${item['max_vpn_sessions'] == 0 ? 'без ограничений' : item['max_vpn_sessions']}'),
                Text(
                    'Тип лицензии: ${item['license_type'] == 1 ? 'сервер' : item['license_type'] == 3 ? 'клиент' : item['license_type'] == 2 ? 'мост' : item['license_type']}'),
                Text('Номер лицензии: ${item['license_number']}'),
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
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('В PDF-формате '),
              ),
              Visibility(
                visible: isActivationButtonVisible,
                child: TextButton(
                  onPressed: () {
                    _showActivationDialog(item);
                  },
                  child: const Text('Активировать лицензию'),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showActivationDialog(Map<String, dynamic> item) async {
    String activationCode = '';

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Введите код активации'),
          content: Column(
            children: [
              TextField(
                onChanged: (value) {
                  activationCode = value;
                },
                decoration: const InputDecoration(
                  labelText: 'Код активации',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _activateLicense(item['license_type'], item['license_number'],
                    activationCode);

                Navigator.of(context).pop();
              },
              child: const Text('Активировать'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Отмена'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _activateLicense(
      int licenseType, int licenseNumber, String activationCode) async {
    final response = await http.post(
      Uri.parse('http://192.168.202.200:5000/api/createCode'),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, String>{
        'install_key': activationCode,
        // 'password': password,
        'license_type': licenseType.toString(),
        'license_number': licenseNumber.toString(),
      }),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Успешно активировано'),
            content: Text('Код активации: ${responseData['install_code']}'),
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
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(
      //     backgroundColor: Colors.green,
      //     content: Text('Kод лицензии выслан'),
      //     duration: Duration(seconds: 2), // Длительность отображения Snackbar
      //   ),
      // );
    } else {
      print(response.statusCode);
      if (response.statusCode == 400) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text('Ошибка'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
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
        Uri.parse('http://192.168.202.200:5000/api/items/$itemId'),
      );

      if (response.statusCode == 200) {
        await fetchItems();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('Элемент успешно удален'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
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
          await http.get(Uri.parse('http://192.168.202.200:5000/api/items'));

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
    final licenseKeyFilter = licenseKeyFilterController.text.toLowerCase();

    setState(() {
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
    return kIsWeb
        ? Center(
            child: Text(
              tooltip,
              style: const TextStyle(fontSize: 14.0),
              textAlign: TextAlign.center,
            ),
          )
        : Icon(icon);
  }

  int _rowsPerPage = 10; // Начальное количество строк на странице
  int _currentPage = 0;

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
                        setState(() {});
                      },
                      decoration: const InputDecoration(
                        labelText: 'Фильтр по названию',
                      ),
                    ),
                    TextField(
                      controller: licenseTypeFilterController,
                      onChanged: (value) {
                        _filterItems();
                        setState(() {});
                      },
                      decoration: const InputDecoration(
                        labelText: 'Фильтр по типу лицензии',
                      ),
                    ),
                    TextField(
                      controller: licenseKeyFilterController,
                      onChanged: (value) {
                        _filterItems();
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
                              (Set<MaterialState> states){
                                return Colors.blue;
                              }
                          ),
                          border: TableBorder.all(
                            width: 2.0,
                            color: Colors.black45,
                          ),
                          columnSpacing: 1,
                          sortAscending: _sortAscending,
                          sortColumnIndex: _sortColumnIndex,
                          columns: <DataColumn>[
                            DataColumn(
                              label: _buildColumnLabel(
                                  'Владелец', Icons.account_box),
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
                            DataColumn(
                              label:
                                  _buildColumnLabel('срок', Icons.date_range),
                              tooltip: 'срок',
                              onSort: (columnIndex, ascending) {
                                setState(() {
                                  _sortAscending = ascending;
                                  _sortColumnIndex = columnIndex;
                                  _sort((item) => item['expiry_date'],
                                      columnIndex, ascending);
                                });
                              },
                            ),
                            DataColumn(
                              label: _buildColumnLabel(
                                  'пропускная\nспособность',
                                  Icons.network_check),
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
                              label: _buildColumnLabel(
                                  'макс кол-во\nпользователей', Icons.people),
                              tooltip: 'макс кол-во\nпользователей',
                              onSort: (columnIndex, ascending) {
                                setState(() {
                                  _sortAscending = ascending;
                                  _sortColumnIndex = columnIndex;
                                  _sort((item) => item['max_users'],
                                      columnIndex, ascending);
                                });
                              },
                            ),
                            DataColumn(
                              label: _buildColumnLabel(
                                  'макс кол-во сессий', Icons.account_tree),
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
                              label: _buildColumnLabel('тип лицензии',
                                  Icons.format_list_numbered_rounded),
                              tooltip: 'тип лицензии',
                              onSort: (columnIndex, ascending) {
                                setState(() {
                                  _sortAscending = ascending;
                                  _sortColumnIndex = columnIndex;
                                  _sort((item) => item['license_type'],
                                      columnIndex, ascending);
                                });
                              },
                            ),
                            DataColumn(
                              label: _buildColumnLabel('лицензия',
                                  Icons.format_list_numbered_rounded),
                              tooltip: 'лицензия',
                              onSort: (columnIndex, ascending) {
                                setState(() {
                                  _sortAscending = ascending;
                                  _sortColumnIndex = columnIndex;
                                  _sort((item) => item['license_key'],
                                      columnIndex, ascending);
                                });
                              },
                            ),
                            DataColumn(
                              label: _buildColumnLabel('код активации',
                                  Icons.format_list_numbered_rounded),
                              tooltip: 'код активации',
                              onSort: (columnIndex, ascending) {
                                setState(() {
                                  _sortAscending = ascending;
                                  _sortColumnIndex = columnIndex;
                                  _sort((item) => item['generate_key'],
                                      columnIndex, ascending);
                                });
                              },
                            ),
                            const DataColumn(
                              label: Icon(
                                Icons.delete_outline_outlined,
                                color: Colors.red,
                              ),
                            ),
                          ],
                          rows: (nameFilterController.text.isEmpty &&
                                  licenseTypeFilterController.text.isEmpty &&
                                  licenseNumberFilterController.text.isEmpty &&
                                  licenseKeyFilterController.text.isEmpty)
                              ? items.map(
                                  (item) {
                                    return DataRow(
                                      onSelectChanged: (selected) {
                                        if (selected != null && selected) {
                                          _showLicenseDetailsDialog(
                                              context, item);
                                        }
                                      },
                                      cells: <DataCell>[
                                        DataCell(
                                          Center(
                                            child: Text(item['name']),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            item['expiry_date']
                                                    .toString()
                                                    .isEmpty
                                                ? 'бессрочно'
                                                : item['expiry_date']
                                                    .toString(),
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
                                        DataCell(
                                          Text(
                                            item['license_key'].toString(),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            item['generate_key'].toString(),
                                          ),
                                        ),
                                        DataCell(
                                          ElevatedButton(
                                            onPressed: () {
                                              _deleteItem(item['id']);
                                            },
                                            child: const Icon(
                                              Icons.delete,
                                              color: Colors.white,
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
                                      onSelectChanged: (selected) {
                                        if (selected != null && selected) {
                                          _showLicenseDetailsDialog(
                                              context, item);
                                        }
                                      },
                                      cells: <DataCell>[
                                        DataCell(
                                          Text(item['name']),
                                        ),
                                        DataCell(Text(
                                            item['expiry_date'].toString())),
                                        DataCell(Text(
                                            item['max_bandwidth'].toString())),
                                        DataCell(
                                            Text(item['max_users'].toString())),
                                        DataCell(Text(item['max_vpn_sessions']
                                            .toString())),
                                        DataCell(Text(
                                            item['license_type'].toString())),
                                        DataCell(Text(
                                            item['license_key'].toString())),
                                        DataCell(Text(
                                            item['generate_key'].toString())),
                                        DataCell(
                                          ElevatedButton(
                                            onPressed: () {
                                              _deleteItem(item['id']);
                                            },
                                            child: const Icon(
                                              Icons.delete,
                                              color: Colors.white,
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
                  );
                } else {

                  int columnCount = availableWidth > 600 ? 2 : 1;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: (nameFilterController.text.isEmpty &&
                        licenseTypeFilterController.text.isEmpty &&
                        licenseKeyFilterController.text.isEmpty)
                        ? items.map((item) {
                      return InkWell(
                        onTap: () {
                          _showLicenseDetailsDialog(context, item);
                        },
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Название: ${item['name']}'),
                                Text('Срок: ${item['expiry_date']}'),
                                Text(
                                    'пропускная способность: ${item['max_bandwidth']}'),
                                Text('пользователи: ${item['max_users']}'),
                                Text('сессии: ${item['max_vpn_sessions']}'),
                                Text('тип лицензии: ${item['license_type']}'),
                                Text('лицензионный ключ: ${item['license_key']}'),
                                Text('ключ активации: ${item['generate_key']}'),
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
                          _showLicenseDetailsDialog(context, item);
                        },
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Название: ${item['name']}'),
                                Text('Срок: ${item['expiry_date']}'),
                                Text(
                                    'пропускная способность: ${item['max_bandwidth']}'),
                                Text('пользователи: ${item['max_users']}'),
                                Text('сессии: ${item['max_vpn_sessions']}'),
                                Text('тип лицензии: ${item['license_type']}'),
                                Text('лицензионный ключ: ${item['license_key']}'),
                                Text('ключ активации: ${item['generate_key']}'),
                                // Добавьте другие поля по мере необходимости
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                }
              })
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.of(context).pushReplacement(PageTransition(
              type: PageTransitionType.leftToRight,
              child: HomePage(userDto: widget.userDto),
            ));
          },
          child: Icon(Icons.add),
          backgroundColor: Colors.yellow, // Цвет кнопки
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }
}
