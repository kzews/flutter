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

  List<double> columnWidths = [150,150,150,150,150,150,150,150,150,150,150,150,150,150,150,150,150,150,150,150,150,150,150,150,150,];
  Widget _buildColumnLabel(String tooltip, IconData icon,int columnIndex) {
    return (kIsWeb || defaultTargetPlatform == TargetPlatform.windows)
        ? Stack(
      children:[ Container(

        child: Text(
          tooltip,
          style: const TextStyle(fontSize: 14.0, color: Colors.white),
          textAlign: TextAlign.center,
          selectionColor: Colors.white,
        ),
        width: columnWidths[columnIndex],
        constraints: BoxConstraints(minWidth: 10),),
        Positioned(
          right: 0,
          child: GestureDetector(
            onPanStart: (details) {
              // debugPrint(details.globalPosition.dx.toString());
              setState(() {
                initX = details.globalPosition.dx;
              });
            },
            onPanUpdate: (details) {
              final increment = details.globalPosition.dx - initX;
              final newWidth = columnWidths[columnIndex] + increment;
              setState(() {
                initX = details.globalPosition.dx;
                columnWidths[columnIndex] = newWidth > minimumColumnWidth
                    ? newWidth
                    : minimumColumnWidth;
              });
            },
            child: Container(
              width: 10,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(1),
                shape: BoxShape.rectangle,
              ),
            ),
          ),
        )],)
        : Icon(icon);
  }

  double columnWidth = 100;
  double initX = 0;
  final minimumColumnWidth = 50.0;
  final verticalScrollController = ScrollController();
  final horizontalScrollController = ScrollController();

  List<DataColumn> buildDataColumns() {
    List<DataColumn> columns = [

      DataColumn(
        label: _buildColumnLabel('Владелец', Icons.password, 1),
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
        label: _buildColumnLabel('УНН/УНП', Icons.password, 2),
        tooltip: 'УНН/УНП',
      ),

      // DataColumn(
      //   label: _buildColumnLabel('Дата отгрузки', Icons.password,3),
      //   tooltip: 'Дата отгрузки',
      //   onSort: (columnIndex, ascending) {
      //     setState(() {
      //       _sortAscending = ascending;
      //       _sortColumnIndex = columnIndex;
      //       _sort((item) => item['date_shipping'], columnIndex, ascending);
      //     });
      //   },
      // ),

      DataColumn(
        label: _buildColumnLabel('Договор', Icons.password,4),
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
        label: _buildColumnLabel('Серийный\nномер', Icons.numbers,5),
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
        label: _buildColumnLabel('Лицензия', Icons.text_fields,6),
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
            'Тип лицензии', Icons.format_list_numbered_rounded,7
        ),
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
        label: _buildColumnLabel('Срок', Icons.date_range,8),
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
        _buildColumnLabel('Пропускная\nспособность', Icons.network_check,9),
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
        label: _buildColumnLabel('Макс кол-во\nпользователей', Icons.people,10),
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
        label: _buildColumnLabel('Макс кол-во\nсессий', Icons.account_tree,11),
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
        label: _buildColumnLabel('Код\nактивации', Icons.password,12),
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
        const DataColumn(
          label: Icon(
            Icons.print,
            color: Colors.greenAccent,
          ),
          tooltip: 'Выбрать для печати',
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

    return columns;
  }
  DataCell buildTextDataCell(String text,
      {String? nullText, int? maxLines, double? maxWidth}) {
    return DataCell(
      ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth ?? double.infinity),
        child: Text(
          text.isEmpty ? nullText ?? '-' : text,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          softWrap: false,
        ),
      ),
    );
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
                        Row(
                          children: [
                            const Text(
                              'Без физического источника',
                              style: const TextStyle(fontSize: 16.0),
                            ),

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
                      title: const Text('Выбрать документы для печати'),
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
                          child: Text('Печать'),
                        ),
                      )
                  ],
                ),
              ),
              LayoutBuilder(builder: (context, constraints) {
                double availableWidth = constraints.maxWidth;
                if (availableWidth > 1250) {
                  return Center(
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height*0.5,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.black,
                          width: 3,
                        ),
                      ),
                      margin: const EdgeInsets.all(15.0),
                      child: Scrollbar(
                        thumbVisibility: true,
                        trackVisibility: true, // make the scrollbar easy to see
                        controller: verticalScrollController,
                        child: Scrollbar(
                          thumbVisibility: true,
                          trackVisibility: true,
                          controller: horizontalScrollController,
                          notificationPredicate: (notif) => notif.depth == 1,
                          child: SingleChildScrollView(
                            controller: verticalScrollController,
                            scrollDirection: Axis.vertical,
                            child: SingleChildScrollView(
                              controller: horizontalScrollController,
                              scrollDirection: Axis.horizontal,
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
                                columnSpacing: 5,
                                sortAscending: _sortAscending,
                                sortColumnIndex: _sortColumnIndex,
                                columns: buildDataColumns(),
                                rows: (nameFilterController.text.isEmpty &&
                                    licenseTypeFilterController
                                        .text.isEmpty &&
                                    licenseNumberFilterController
                                        .text.isEmpty &&
                                    licenseKeyFilterController.text.isEmpty)
                                    ? items.map(
                                      (item) {
                                    List<DataCell> cells = [
                                      buildTextDataCell(item['name'], maxWidth: columnWidth),
                                      buildTextDataCell(item['UNNorUNP'], nullText: '-', maxWidth: columnWidths[2]),
                                      buildTextDataCell(item['date_shipping'], nullText: '-', maxWidth: columnWidths[3]),
                                      buildTextDataCell(item['dogovor'], nullText: '-', maxWidth: columnWidths[4]),
                                      buildTextDataCell(item['key'], nullText: '-', maxWidth: columnWidths[5]),
                                      buildTextDataCell(item['license_key'].toString(), nullText: '-', maxWidth: columnWidths[6]),
                                      buildTextDataCell(licenseTypes[item['license_type']] ?? '-', nullText: '-', maxWidth: columnWidths[7]),
                                      buildTextDataCell(
                                        item['expiry_date'].toString().isEmpty ? 'бессрочно' : item['expiry_date'].toString(),
                                        nullText: '-', maxWidth: columnWidths[8],
                                      ),
                                      buildTextDataCell(item['max_bandwidth'].toString() == '0' ? '∞' : item['max_bandwidth'].toString(), nullText: '-', maxWidth: columnWidths[9]),
                                      buildTextDataCell(item['max_users'].toString() == '0' ? '∞' : item['max_users'].toString(), nullText: '-', maxWidth: columnWidths[10]),
                                      buildTextDataCell(item['max_vpn_sessions'].toString() == '0' ? '∞' : item['max_vpn_sessions'].toString(), nullText: '-', maxWidth: columnWidths[11]),
                                      buildTextDataCell(item['generate_key'] ?? '-', nullText: '-', maxWidth: columnWidths[12]),
                                    ];
                                    if (widget.userDto.role == 'admin') {
                                      cells.add(
                                        DataCell(
                                          Center(
                                            child: ElevatedButton(
                                              onPressed: () {
                                                deleteItem(
                                                    context, item['id'],
                                                        () {
                                                      fetchItemsPage(context,
                                                              (List<
                                                              Map<String,
                                                                  dynamic>>
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
                                                changeItem(
                                                    context,
                                                    item['id'],
                                                    item,
                                                    setState);
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
                                              value: checkBoxStates[
                                              item['id']] ??
                                                  false,
                                              onChanged: (value) {
                                                setState(() {
                                                  checkBoxStates[
                                                  item['id']] =
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
                                        if (selected != null &&
                                            selected) {
                                          showLicenseDetailsDialog(
                                              context,
                                              item,
                                              widget.userDto);
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
                                                : item['UNNorUNP']
                                                .toString(),
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
                                                : item['dogovor']
                                                .toString(),
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
                                                .toString(),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Center(
                                          child: Text(
                                            licenseTypes[
                                            item['license_type']]!,
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
                                                : item['max_users']
                                                .toString(),
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
                                    if (widget.userDto.role != 'user') {
                                      cells.add(
                                        DataCell(
                                          Center(
                                            child: ElevatedButton(
                                              onPressed: () {
                                                deleteItem(
                                                    context, item['id'],
                                                        () {
                                                      fetchItemsPage(context,
                                                              (List<
                                                              Map<String,
                                                                  dynamic>>
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
                                                changeItem(
                                                    context,
                                                    item['id'],
                                                    item,
                                                    setState);
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

                                              onChanged: (value) {
                                              },
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                    return DataRow(
                                      onSelectChanged: (selected) {
                                        if (selected != null &&
                                            selected) {
                                          showLicenseDetailsDialog(
                                              context,
                                              item,
                                              widget.userDto);
                                        }
                                      },
                                      cells: cells,
                                    );
                                  },
                                ).toList(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                } else {
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
                    onPressed: () {
                      setState(() {
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
                      });
                    },
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
                              currentPage);
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
