import 'package:gateway_config/models/dropdown_items.dart';

class StaticData {
  static const List<Map<String, dynamic>> dataModbusType = [
    {'text': 'INT16', 'value': 'int16'},
    {'text': 'UINT16', 'value': 'uint16'},
    {'text': 'INT32-BE', 'value': 'int32-be'},
    {'text': 'INT32-LE', 'value': 'int32-le'},
    {'text': 'INT32-WS1', 'value': 'int32-ws1'},
    {'text': 'INT32-WS2', 'value': 'int32-ws2'},
    {'text': 'UINT32-BE', 'value': 'uint32-be'},
    {'text': 'UINT32-LE', 'value': 'uint32-le'},
    {'text': 'UINT32-WS1', 'value': 'uint32-ws1'},
    {'text': 'UINT32-WS2', 'value': 'uint32-ws2'},
    {'text': 'FLOAT32-BE', 'value': 'float32-be'},
    {'text': 'FLOAT32-LE', 'value': 'float32-le'},
    {'text': 'FLOAT32-WS1', 'value': 'float32-ws1'},
    {'text': 'FLOAT32-WS2', 'value': 'float32-ws2'},
    {'text': 'INT64-BE', 'value': 'int64-be'},
    {'text': 'INT64-LE', 'value': 'int64-le'},
    {'text': 'INT64-WS1', 'value': 'int64-ws1'},
    {'text': 'INT64-WS2', 'value': 'int64-ws2'},
    {'text': 'UINT64-BE', 'value': 'uint64-be'},
    {'text': 'UINT64-LE', 'value': 'uint64-le'},
    {'text': 'UINT64-WS1', 'value': 'uint64-ws1'},
    {'text': 'UINT64-WS2', 'value': 'uint64-ws2'},
    {'text': 'FLOAT64-BE', 'value': 'float64-be'},
    {'text': 'FLOAT64-LE', 'value': 'float64-le'},
    {'text': 'FLOAT64-WS1', 'value': 'float64-ws1'},
    {'text': 'FLOAT64-WS2', 'value': 'float64-ws2'},
  ];

  static final List<DropdownItems> modbusReadFunctions = [
    DropdownItems(text: 'Coil Status', value: '1'),
    DropdownItems(text: 'Input Status', value: '2'),
    DropdownItems(text: 'Holding Register', value: '3'),
    DropdownItems(text: 'Input Registers', value: '4'),
  ];
}
