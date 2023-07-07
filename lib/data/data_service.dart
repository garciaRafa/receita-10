import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../util/ordenador.dart';

enum TableStatus { idle, loading, ready, error }

enum ItemType {
  food,
  vehicle,
  company,
  none;

  String get asString => '$name';

  List<String> get columns => this == vehicle
      ? ["Marca", "Cor", "Modelo"]
      : this == food
          ? ["Prato", "Ingrediente", "Medição"]
          : this == company
              ? ["Nome", "Industria", "Tipo"]
              : [];

  List<String> get properties => this == vehicle
      ? ["make_and_model", "color", "car_type"]
      : this == food
          ? ["dish", "ingredient", "measurement"]
          : this == company
              ? ["business_name", "industry", "type"]
              : [];
}

class DataService {
  static const MAX_N_ITEMS = 15;

  static const MIN_N_ITEMS = 3;

  static const DEFAULT_N_ITEMS = 7;

  int _numberOfItems = DEFAULT_N_ITEMS;

  set numberOfItems(n) {
    _numberOfItems = n < 0
        ? MIN_N_ITEMS
        : n > MAX_N_ITEMS
            ? MAX_N_ITEMS
            : n;
  }

  int get getNumberOfItems => _numberOfItems;

  final ValueNotifier<Map<String, dynamic>> tableStateNotifier = ValueNotifier({
    'status': TableStatus.idle,
    'dataObjects': [],
    'itemType': ItemType.none
  });

  void carregar(index) {
    final params = [ItemType.vehicle, ItemType.food, ItemType.company];

    carregarPorTipo(params[index]);
  }

  void ordenarEstadoAtual(final String propriedade, bool ascending) {
    List objetos = tableStateNotifier.value['dataObjects'] ?? [];

    if (objetos == []) return;

    Ordenador ord = Ordenador();

    Decididor d = DecididorJSON(propriedade, ascending);

    ItemType type = tableStateNotifier.value['itemType'];

    var objetosOrdenados =
        ord.ordenarFuderoso(objetos, d.precisaTrocarAtualPeloProximo);

    emitirEstadoOrdenado(objetosOrdenados, propriedade,
        type.properties.indexOf(propriedade), ascending);
  }

  Uri montarUri(ItemType type) {
    return Uri(
        scheme: 'https',
        host: 'random-data-api.com',
        path: 'api/${type.asString}/random_${type.asString}',
        queryParameters: {'size': '$_numberOfItems'});
  }

  Future<List<dynamic>> acessarApi(Uri uri) async {
    var jsonString = await http.read(uri);

    var json = jsonDecode(jsonString);

    json = [...tableStateNotifier.value['dataObjects'], ...json];

    return json;
  }

  void emitirEstadoOrdenado(
      List objetosOrdenados, String propriedade, int column, bool ascending) {
    var estado = Map<String, dynamic>.from(tableStateNotifier.value);

    estado['dataObjects'] = objetosOrdenados;
    estado['sortCriteria'] = propriedade;
    estado['ascending'] = ascending;
    estado['sortedColumn'] = column;
    tableStateNotifier.value = estado;
  }

  void emitirEstadoCarregando(ItemType type) {
    tableStateNotifier.value = {
      'status': TableStatus.loading,
      'dataObjects': [],
      'itemType': type
    };
  }

  void emitirEstadoPronto(ItemType type, var json) {
    tableStateNotifier.value = {
      'itemType': type,
      'status': TableStatus.ready,
      'dataObjects': json,
      'propertyNames': type.properties,
      'columnNames': type.columns
    };
  }

  bool temRequisicaoEmCurso() =>
      tableStateNotifier.value['status'] == TableStatus.loading;

  bool mudouTipoDeItemRequisitado(ItemType type) =>
      tableStateNotifier.value['itemType'] != type;

  void carregarPorTipo(ItemType type) async {
    //ignorar solicitação se uma requisição já estiver em curso

    if (temRequisicaoEmCurso()) return;

    if (mudouTipoDeItemRequisitado(type)) {
      emitirEstadoCarregando(type);
    }

    var uri = montarUri(type);

    var json = await acessarApi(uri);

    emitirEstadoPronto(type, json);
  }
}

class DecididorJSON extends Decididor {
  final String propriedade;

  final bool crescente;

  DecididorJSON(this.propriedade, [this.crescente = true]);

  @override
  bool precisaTrocarAtualPeloProximo(atual, proximo) {
    try {
      return crescente
          ? atual[propriedade].compareTo(proximo[propriedade]) > 0
          : atual[propriedade].compareTo(proximo[propriedade]) < 0;
    } catch (error) {
      return false;
    }
  }
}

final dataService = DataService();