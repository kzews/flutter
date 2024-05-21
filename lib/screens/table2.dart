import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttersrc/appBar.dart';
import 'package:http/http.dart' as http;
import 'package:page_transition/page_transition.dart';

import '../environment.dart';
import '../objects/userDto.dart';
import '../services/backButton.dart';
import '../services/tableServices/changeItem.dart';
import '../services/tableServices/deleteItem.dart';
import '../services/tableServices/fetchItemsPage.dart';
import '../services/tableServices/sendSelectedItemsToServer.dart';
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
  bool _increaseValue = false;
  bool isChecked = false;
  Map<int, bool> checkBoxStates =
      {}; // int - индекс строки, bool - состояние флажка
  List<int> selectedIds = [];

  TextEditingController nameFilterController = TextEditingController();
  TextEditingController licenseTypeFilterController = TextEditingController();
  TextEditingController licenseNumberFilterController = TextEditingController();
  TextEditingController licenseKeyFilterController = TextEditingController();
  TextEditingController pageController = TextEditingController(text: '1');
  TextEditingController pageSizeController = TextEditingController(text: '10');

  @override
  void initState() {
    super.initState();
    fetchItemsPage(context, (List<Map<String, dynamic>> itemsList) {
      setState(() {
        items = itemsList;
        for (int i = 0; i < items.length; i++) {
          checkBoxStates[i] = false;
        }
      });
    });
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

  bool _selectAll = false;

  void _toggleSelectAll(bool? value) {
    setState(() {
      _selectAll = value ?? false;
      for (var item in items) {
        checkBoxStates[item['id']] = _selectAll;
        if (_selectAll) {
          selectedIds.add(item['id']);
        } else {
          selectedIds.remove(item['id']);
        }
      }
    });
  }

  Widget _buildColumnLabel(String tooltip, IconData icon) {
    return (kIsWeb || defaultTargetPlatform == TargetPlatform.windows)
        ? Expanded(
            child: Text(
            tooltip,
            style: const TextStyle(fontSize: 14.0, color: Colors.white),
            textAlign: TextAlign.center,
            selectionColor: Colors.white,
          ))
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
        label: _buildColumnLabel('УНН/УНП', Icons.password),
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
        label: _buildColumnLabel('Дата отгрузки', Icons.password),
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
        label: _buildColumnLabel('Договор', Icons.password),
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
        label: _buildColumnLabel('Серийный\nномер', Icons.numbers),
        tooltip: 'Серийный номер',
        onSort: (columnIndex, ascending) {
          setState(() {
            _sortAscending = ascending;
            _sortColumnIndex = columnIndex;
            _sort((item) => item['key'], columnIndex, ascending);
          });
        },
      ),
      DataColumn(
        label: _buildColumnLabel('Лицензия', Icons.text_fields),
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
            'Тип лицензии', Icons.format_list_numbered_rounded),
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
        label: _buildColumnLabel('Срок', Icons.date_range),
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
            _buildColumnLabel('Пропускная\nспособность', Icons.network_check),
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
        label: _buildColumnLabel('Макс кол-во\nпользователей', Icons.people),
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
        label: _buildColumnLabel('Макс кол-во\nсессий', Icons.account_tree),
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
        label: _buildColumnLabel('Код\nактивации', Icons.password),
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
    if (_increaseValue) {
      columns.insert(
        0,
        DataColumn(
          label: Row(
            children: [
              const Icon(
                Icons.print,
                color: Colors.greenAccent,
              ),
              Checkbox(
                value: _selectAll,
                onChanged: _toggleSelectAll,
              ),
            ],
          ),
        ),
      );
    }
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
    // if (_increaseValue) {
    //   columns.add(
    //     const DataColumn(
    //       label: Icon(
    //         Icons.print,
    //         color: Colors.greenAccent,
    //       ),
    //       tooltip: 'Выбрать для печати',
    //     ),
    //   );
    // }
    return columns;
  }

  String dropdownValue =
      'Сервер'; // добавляем переменную и устанавливаем значение по умолчанию
  bool isCheckedServer = false;
  bool isCheckedConfirmationCode = false;

  void updateLicenseType() {
    switch (dropdownValue) {
      case 'Любой':
        licenseTypeFilterController.text = '';
        break;
      case 'Сервер':
        if (isCheckedServer && isCheckedConfirmationCode) {
          licenseTypeFilterController.text =
              '104'; // сервер без случайности с КП
        } else if (isCheckedServer) {
          licenseTypeFilterController.text = '101'; // сервер без случайности
        } else if (isCheckedConfirmationCode) {
          licenseTypeFilterController.text = '4'; // сервер с КП
        } else {
          licenseTypeFilterController.text = '1'; // сервер
        }
        break;
      case 'Мост':
        if (isCheckedServer && isCheckedConfirmationCode) {
          licenseTypeFilterController.text = '105'; // мост без случайности с КП
        } else if (isCheckedServer) {
          licenseTypeFilterController.text = '102'; // мост без случайности
        } else if (isCheckedConfirmationCode) {
          licenseTypeFilterController.text = '5'; // мост с КП
        } else {
          licenseTypeFilterController.text = '2'; // мост
        }
        break;
      case 'Клиент':
        if (isCheckedServer && isCheckedConfirmationCode) {
          licenseTypeFilterController.text =
              '106'; // клиент без случайности с КП
        } else if (isCheckedServer) {
          licenseTypeFilterController.text = '103'; // клиент без случайности
        } else if (isCheckedConfirmationCode) {
          licenseTypeFilterController.text = '6'; // клиент с КП
        } else {
          licenseTypeFilterController.text = '3'; // клиент
        }
        break;
      default:
        licenseTypeFilterController.text = '';
    }
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

                    Row(
                      children: [
                        DropdownButton<String>(
                          value: dropdownValue,
                          onChanged: (String? newValue) {
                            setState(() {
                              dropdownValue = newValue!;
                              updateLicenseType();
                              _filterItems(pageSize, currentPage);
                            });
                          },
                          items: <String>[
                            'Любой',
                            'Сервер',
                            'Мост',
                            'Клиент'
                          ] // добавляем элемент "любое"
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                        SizedBox(width: 20),
                        // пространство между выпадающим списком и чекбоксами

                        Row(
                          children: [
                            const Text(
                              'Без физического источника',
                              style: const TextStyle(fontSize: 16.0),
                            ),
                            // добавляем текстовую метку для чекбокса
                            Checkbox(
                              value: isCheckedServer,
                              onChanged: (bool? newValue) {
                                setState(() {
                                  isCheckedServer = newValue!;
                                  updateLicenseType();
                                  _filterItems(pageSize, currentPage);
                                });
                              },
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              'С кодом подтверждения',
                              style: const TextStyle(fontSize: 16.0),
                            ),
                            // добавляем текстовую метку для чекбокса
                            Checkbox(
                              value: isCheckedConfirmationCode,
                              onChanged: (bool? newValue) {
                                setState(() {
                                  isCheckedConfirmationCode = newValue!;
                                  updateLicenseType();
                                  _filterItems(pageSize, currentPage);
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),

                    // TextField(
                    //   controller: licenseTypeFilterController,
                    //   onChanged: (value) {
                    //     _filterItems(pageSize, currentPage);
                    //     setState(() {});
                    //   },
                    //   decoration: const InputDecoration(
                    //     labelText: 'Фильтр по типу лицензии',
                    //   ),
                    // ),
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
                    CheckboxListTile(
                      title: const Text('Печать нескольких'),
                      controlAffinity: ListTileControlAffinity.leading,
                      value: _increaseValue,
                      onChanged: (newValue) {
                        setState(() {
                          _increaseValue = newValue!;
                        });
                      },
                    ),
                    if (_increaseValue)
                      Container(
                        alignment: Alignment.bottomLeft,
                        child: ElevatedButton(
                          onPressed: () {
                            sendSelectedItemsToServer(context, selectedIds);
                          },
                          child: Text('Сформировать документы'),
                        ),
                      )
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
                          columnSpacing: 10,
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
                                            item['license_key']
                                                .toString()
                                                .replaceAll('-', ' '),
                                            softWrap: true,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Center(
                                          child: Text(
                                            licenseTypes[item['license_type']]!,
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
                                                deleteItem(context, item['id'],
                                                    () {
                                                  fetchItemsPage(context, (List<
                                                          Map<String, dynamic>>
                                                      itemsList) {
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
                                                changeItem(context, item['id'],
                                                    item, setState);
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
                                    if (_increaseValue) {
                                      cells.insert(
                                        0,
                                        DataCell(
                                          Center(
                                            child: Checkbox(
                                              value:
                                                  checkBoxStates[item['id']] ??
                                                      false,
                                              onChanged: (value) {
                                                setState(() {
                                                  checkBoxStates[item['id']] =
                                                      value ?? false;
                                                  if (value ?? false) {
                                                    selectedIds.add(item[
                                                        'id']); // Add id to selectedIds when checkbox is checked
                                                  } else {
                                                    selectedIds.remove(item[
                                                        'id']); // Remove id from selectedIds when checkbox is unchecked
                                                  }
                                                });
                                              },
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
                                            licenseTypes[item['license_type']]!,
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
                                                deleteItem(context, item['id'],
                                                    () {
                                                  fetchItemsPage(context, (List<
                                                          Map<String, dynamic>>
                                                      itemsList) {
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
                                                changeItem(context, item['id'],
                                                    item, setState);
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
                                    if (_increaseValue) {
                                      selectedIds.add(item['id']);

                                      cells.add(
                                        DataCell(
                                          Center(
                                            child: Checkbox(
                                              value: false,
                                              // Provide the value for the checkbox
                                              onChanged: (value) {
                                                // Handle checkbox state changes here
                                              },
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
                              fetchItemsPage(context,
                                  (List<Map<String, dynamic>> itemsList) {
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
                        fetchItemsPage(context,
                            (List<Map<String, dynamic>> itemsList) {
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
                    onPressed: currentPage < totalPages
                        ? () {
                            setState(() {
                              // Проверяем, не превышает ли текущая страница общее количество страниц
                              if (currentPage < totalPages) {
                                currentPage++;
                                pageController.text = currentPage
                                    .toString(); // Обновляем значение в TextField
                                fetchItemsPage(context,
                                    (List<Map<String, dynamic>> itemsList) {
                                  setState(() {
                                    items = itemsList;
                                  });
                                });
                                _filterItems(pageSize,
                                    currentPage); // Загружаем следующую страницу
                              } else {
                                // Если текущая страница равна или превышает общее количество страниц, ничего не делаем
                                // Можете добавить какое-то уведомление пользователю, что это последняя страница
                              }
                            });
                          }
                        : null,
                  ),

                  const Text('Количество строк:'),
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
                          fetchItemsPage(context,
                              (List<Map<String, dynamic>> itemsList) {
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
