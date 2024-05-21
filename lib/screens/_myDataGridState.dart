import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:http/http.dart' as http;
import '../appBar.dart';
import '../environment.dart';
import '../objects/userDto.dart';
import '../services/backButton.dart';
import '../services/tableServices/fetchItemsPage1.dart';
import '../services/tableServices/sendSelectedItemsToServer.dart';
import '../services/tableServices/showLicenseDetailsDialog.dart';

class MyDataGrid extends StatefulWidget {
  final UserDto userDto;
  MyDataGrid({required this.userDto});

  @override
  _MyDataGridState createState() => _MyDataGridState();
}

class _MyDataGridState extends State<MyDataGrid> {

  List<Map<String, dynamic>> items = [];

  String dropdownValue = 'Сервер';
  bool isCheckedServer = false;
  bool isCheckedConfirmationCode = false;

  TextEditingController licenseTypeFilterController = TextEditingController();
  TextEditingController nameFilterController = TextEditingController();
  TextEditingController licenseKeyFilterController = TextEditingController();
  TextEditingController licenseNumberFilterController = TextEditingController();


  final DataGridController _dataGridController = DataGridController();

  bool _increaseValue = false;

  List<int> selectedIds = [];
  List<Map<String, dynamic>> filteredItems = [];

  late LicenseDataSource _licenseDataSource;
  late Map<String, double> columnWidths;
  TextEditingController pageController = TextEditingController(text: '1');
  TextEditingController pageSizeController = TextEditingController(text: '5');

  @override
  void initState() {
    super.initState();
    _licenseDataSource = LicenseDataSource(items: items);
    columnWidths = {
      'name': double.nan,
      'UNNorUNP': double.nan,
      'date_shipping': double.nan,
      'dogovor': double.nan,
      'key': double.nan,
      'license_key': double.nan,
      'license_type': double.nan,
      'expiry_date': double.nan,
      'max_bandwidth': double.nan,
      'max_users': double.nan,
      'max_vpn_sessions': double.nan,
      'generate_key': double.nan,
      // Add more initial column widths if necessary
    };
    fetchItemsPage1(context, (itemsList) {
      setState(() {
        items = itemsList;
        _licenseDataSource.buildDataGridRows(items);
      });
    });
  }

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
        _licenseDataSource.buildDataGridRows(items);
      });
    } else {
      // Обработка ошибки, если запрос не удался
      // Например, отображение сообщения об ошибке пользователю
      print('Request failed with status: ${response.statusCode}');
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
                        setState(() {
                        });
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
                          items: <String>['Любой', 'Сервер', 'Мост', 'Клиент']
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
                            // Получаем список выбранных строк из контроллера
                            List<DataGridRow?>? selectedRowObjects = _dataGridController.selectedRows;

                            // Очищаем список выбранных элементов
                            selectedIds.clear();


                            // Проходимся по списку выбранных строк и извлекаем соответствующие id
                            for (DataGridRow? rowObject in selectedRowObjects ?? []) {
                              int index = _licenseDataSource.rows.indexOf(rowObject!);
                              selectedIds.add(_licenseDataSource.idList[index]);
                            }

                            // Выводим информацию о выбранных элементах
                            if (selectedIds.isNotEmpty) {
                              sendSelectedItemsToServer(context, selectedIds);
                              print("Selected Ids: $selectedIds");
                            } else {
                              print('No rows selected.');
                            }
                          },
                          child: Text('Печать'),
                        ),
                      )
                  ],
                ),
              ),
              LayoutBuilder(builder: (context, constraints) {
                double availableWidth = constraints.maxWidth;
                double screenHeight = MediaQuery.of(context).size.height*0.6;
                if (availableWidth > 1250) {
                  return Center(
                  child: Container(
                  height: screenHeight,
                      child: SfDataGrid(

                        source: _licenseDataSource,
                        allowColumnsResizing: true,
                        gridLinesVisibility: GridLinesVisibility.both,
                        columnWidthMode: ColumnWidthMode.fill,


                        onColumnResizeUpdate: (ColumnResizeUpdateDetails details) {
                          setState(() {
                            columnWidths[details.column.columnName] = details.width;
                          });
                          return true;
                        },
                        columns: <GridColumn>[
                          GridColumn(

                            columnName: 'name',
                            width: columnWidths['name'] ?? double.nan,
                            label: Container(
                              color: Colors.blue,
                              padding: EdgeInsets.all(8.0),
                              alignment: Alignment.center,
                              child: Text('Name',style: TextStyle(color: Colors.black),),
                            ),
                          ),
                          GridColumn(
                            columnName: 'UNNorUNP',
                            width: columnWidths['UNNorUNP'] ?? double.nan,
                            label: Container(
                              color: Colors.blue,
                              padding: EdgeInsets.all(8.0),
                              alignment: Alignment.center,
                              child: Text('UNN/UNP',style: TextStyle(color: Colors.black),),
                            ),
                          ),
                          GridColumn(
                            columnName: 'date_shipping',
                            width: columnWidths['date_shipping'] ?? double.nan,
                            label: Container(
                              color: Colors.blue,
                              padding: EdgeInsets.all(8.0),
                              alignment: Alignment.center,
                              child: Text('Date Shipping',style: TextStyle(color: Colors.black),),
                            ),
                          ),
                          GridColumn(
                            columnName: 'dogovor',
                            width: columnWidths['dogovor'] ?? double.nan,
                            label: Container(
                              color: Colors.blue,
                              padding: EdgeInsets.all(8.0),
                              alignment: Alignment.center,
                              child: Text('dogovor',style: TextStyle(color: Colors.black),),
                            ),
                          ),
                          GridColumn(
                            columnName: 'key',
                            width: columnWidths['key'] ?? double.nan,
                            label: Container(
                              color: Colors.blue,
                              padding: EdgeInsets.all(8.0),
                              alignment: Alignment.center,
                              child: Text('key',style: TextStyle(color: Colors.black),),
                            ),
                          ),
                          GridColumn(
                            columnName: 'license_key',
                            width: columnWidths['license_key'] ?? double.nan,
                            label: Container(
                              color: Colors.blue,
                              padding: EdgeInsets.all(8.0),
                              alignment: Alignment.center,
                              child: Text('license_key',style: TextStyle(color: Colors.black),),
                            ),
                          ),
                          GridColumn(
                            columnName: 'license_type',
                            width: columnWidths['license_type'] ?? double.nan,
                            label: Container(
                              color: Colors.blue,
                              padding: EdgeInsets.all(8.0),
                              alignment: Alignment.center,
                              child: Text('license_type',style: TextStyle(color: Colors.black),),
                            ),
                          ),
                          GridColumn(
                            columnName: 'expiry_date',
                            width: columnWidths['expiry_date'] ?? double.nan,
                            label: Container(
                              color: Colors.blue,
                              padding: EdgeInsets.all(8.0),
                              alignment: Alignment.center,
                              child: Text('expiry_date',style: TextStyle(color: Colors.black),),
                            ),
                          ),
                          GridColumn(
                            columnName: 'max_bandwidth',
                            width: columnWidths['max_bandwidth'] ?? double.nan,
                            label: Container(
                              color: Colors.blue,
                              padding: EdgeInsets.all(8.0),
                              alignment: Alignment.center,
                              child: Text('max_bandwidth',style: TextStyle(color: Colors.black),),
                            ),
                          ),
                          GridColumn(
                            columnName: 'max_users',
                            width: columnWidths['max_users'] ?? double.nan,
                            label: Container(
                              color: Colors.blue,
                              padding: EdgeInsets.all(8.0),
                              alignment: Alignment.center,
                              child: Text('max_users',style: TextStyle(color: Colors.black),),
                            ),
                          ),
                          GridColumn(
                            columnName: 'max_vpn_sessions',
                            width: columnWidths['max_vpn_sessions'] ?? double.nan,
                            label: Container(
                              color: Colors.blue,
                              padding: EdgeInsets.all(8.0),
                              alignment: Alignment.center,
                              child: Text('max_vpn_sessions',style: TextStyle(color: Colors.black),),
                            ),
                          ),
                          GridColumn(
                            columnName: 'generate_key',
                            width: columnWidths['generate_key'] ?? double.nan,
                            label: Container(
                              color: Colors.blue,
                              padding: EdgeInsets.all(8.0),
                              alignment: Alignment.center,
                              child: Text('generate_key',style: TextStyle(color: Colors.black),),
                            ),
                          ),
                          // Add more GridColumn widgets for other columns
                        ],
                        controller: _dataGridController,
                        selectionMode: SelectionMode.multiple,

                        allowSorting: true,
                        allowMultiColumnSorting: true,
                        showCheckboxColumn: true,
                        onQueryRowHeight: (details) {
                          return details.getIntrinsicRowHeight(details.rowIndex);
                        },
                        onCellTap: (details) {
                          if (details.rowColumnIndex.rowIndex != 0) {
                            final tappedItem = items[details.rowColumnIndex.rowIndex - 1];
                            showLicenseDetailsDialog(context, tappedItem, widget.userDto);
                          }
                        },
                      ),
                  )
                  );
                } else {
                  return Text("Width too small for DataGrid");
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
                        fetchItemsPage1(context,
                                (List<Map<String, dynamic>> itemsList) {
                              setState(() {
                                items = itemsList;
                                _licenseDataSource.buildDataGridRows(items);
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
                        fetchItemsPage1(context,
                                (List<Map<String, dynamic>> itemsList) {
                              setState(() {
                                items = itemsList;
                                _licenseDataSource.buildDataGridRows(items);
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
                        fetchItemsPage1(context,
                                (List<Map<String, dynamic>> itemsList) {
                              setState(() {
                                items = itemsList;
                                _licenseDataSource.buildDataGridRows(items);
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
                          fetchItemsPage1(context,
                                  (List<Map<String, dynamic>> itemsList) {
                                setState(() {
                                  items = itemsList;
                                  _licenseDataSource.buildDataGridRows(items);
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
      ),

    );

  }
}

class LicenseDataSource extends DataGridSource {
  List<DataGridRow> _dataGridRows = [];
  List<int> idList = [];
  LicenseDataSource({required List<Map<String, dynamic>> items}) {
    buildDataGridRows(items);
  }

  void buildDataGridRows(List<Map<String, dynamic>> items) {
    _dataGridRows = items.map<DataGridRow>((item) {
      idList.add(item['id']);
      return DataGridRow(cells: [
        DataGridCell<String>(columnName: 'name', value: item['name']),
        DataGridCell<String>(columnName: 'UNNorUNP', value: item['UNNorUNP']),
        DataGridCell<String>(columnName: 'date_shipping', value: item['date_shipping']),
        DataGridCell<String>(columnName: 'dogovor', value: item['dogovor'].toString()),
        DataGridCell<String>(columnName: 'key', value: item['key'].toString()),
        DataGridCell<String>(columnName: 'license_key', value: item['license_key'].toString()),
        DataGridCell<String>(columnName: 'license_type', value: item['license_type'].toString()),
        DataGridCell<String>(columnName: 'expiry_date', value: item['expiry_date'].toString()),
        DataGridCell<String>(columnName: 'max_bandwidth', value: item['max_bandwidth'].toString()),
        DataGridCell<String>(columnName: 'max_users', value: item['max_users'].toString()),
        DataGridCell<String>(columnName: 'max_vpn_sessions', value: item['max_vpn_sessions'].toString()),
        DataGridCell<String>(columnName: 'generate_key', value: item['generate_key'].toString()),

        // Add more DataGridCell for other columns

      ]  );

    }).toList();
    print("id List = " + idList.toString());

  }

  @override
  List<DataGridRow> get rows => _dataGridRows;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    return DataGridRowAdapter(cells: row.getCells().map<Widget>((dataGridCell) {
      return Container(
        alignment: Alignment.center,
        padding: EdgeInsets.all(8.0),
        child: Text(dataGridCell.value.toString()),
      );
    }).toList());
  }
}