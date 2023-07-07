import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../data/data_service.dart';
import 'package:flutter/gestures.dart';

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  // Override behavior methods and getters like dragDevices
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}

var optionsMenu = [3, 7, 15];

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        scrollBehavior: MyCustomScrollBehavior(),
        theme: ThemeData(primarySwatch: Colors.deepPurple),
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          appBar: AppBar(title: const Text("Dicas"), actions: [NewPop()]),
          body: ValueListenableBuilder(
              valueListenable: dataService.tableStateNotifier,
              builder: (_, value, __) {
                switch (value['status']) {
                  case TableStatus.idle:
                    return Center(child: Text("Toque em algum botão"));

                  case TableStatus.loading:
                    return Center(child: CircularProgressIndicator());

                  case TableStatus.ready:
                    return SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTableWidget(
                              jsonObjects: value['dataObjects'],
                              propertyNames: value['propertyNames'],
                              columnNames: value['columnNames'],
                              isAscending: value['ascending'] ?? false,
                              sortedColumn: value['sortedColumn'] ?? null,
                            )));

                  case TableStatus.error:
                    return Text("Lascou");
                }

                return Text("...");
              }),
          bottomNavigationBar:
              NewNavBar(itemSelectedCallback: dataService.carregar),
        ));
  }
}

class NewNavBar extends HookWidget {
  final _itemSelectedCallback;

  NewNavBar({itemSelectedCallback})
      : _itemSelectedCallback = itemSelectedCallback ?? (int) {}

  @override
  Widget build(BuildContext context) {
    var state = useState(1);

    return BottomNavigationBar(
        onTap: (index) {
          state.value = index;

          _itemSelectedCallback(index);
        },
        currentIndex: state.value,
        items: const [
          BottomNavigationBarItem(
            label: "Cafés",
            icon: Icon(Icons.coffee_outlined),
          ),
          BottomNavigationBarItem(
              label: "Cervejas", icon: Icon(Icons.local_drink_outlined)),
          BottomNavigationBarItem(
              label: "Nações", icon: Icon(Icons.flag_outlined))
        ]);
  }
}

class DataTableWidget extends StatelessWidget {
  final List jsonObjects;

  final List<String> columnNames;

  final List<String> propertyNames;

  final sortedColumn;

  final isAscending;

  DataTableWidget(
      {this.jsonObjects = const [],
      this.columnNames = const [],
      this.propertyNames = const [],
      this.sortedColumn = null,
      this.isAscending = false});

  @override
  Widget build(BuildContext context) {
    return DataTable(
        sortAscending: isAscending,
        sortColumnIndex: sortedColumn,
        columns: columnNames
            .map((name) => DataColumn(
                onSort: (columnIndex, ascending) => dataService
                    .ordenarEstadoAtual(propertyNames[columnIndex], ascending),
                label: Expanded(
                    child: Text(name,
                        style: TextStyle(fontStyle: FontStyle.italic)))))
            .toList(),
        rows: jsonObjects
            .map((obj) => DataRow(
                cells: propertyNames
                    .map((propName) => DataCell(Text(obj[propName])))
                    .toList()))
            .toList());
  }
}

class NewPop extends StatefulWidget {
  NewPop();

  @override
  State<NewPop> createState() => _NewPop();
}

class _NewPop extends State<NewPop> {
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      initialValue: dataService.getNumberOfItems,
      itemBuilder: (value) => optionsMenu
          .map((num) => PopupMenuItem(
                value: num,
                child: Text("Carregar $num itens por vez"),
              ))
          .toList(),
      onSelected: (number) {
        setState(() {
          dataService.numberOfItems = number;
        });
      },
    );
  }
}
