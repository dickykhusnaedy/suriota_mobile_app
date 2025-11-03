import 'package:gateway_config/models/dropdown_items.dart';

class StaticData {
  static const List<Map<String, dynamic>> dataModbusType = [
    // 🔹 16-bit Signed Integer
    {
      'group': '16-bit Signed Integer',
      'text': 'Single Register',
      'value': 'INT16',
    },

    // 🔹 16-bit Unsigned Integer
    {
      'group': '16-bit Unsigned Integer',
      'text': 'Single Register',
      'value': 'UINT16',
    },

    // 🔹 Boolean Value
    {'group': 'Boolean Value', 'text': 'Single Register', 'value': 'BOOL'},

    // 🔹 Binary Data
    {'group': 'Binary Data', 'text': 'Raw 16-bit Value', 'value': 'BINARY'},

    // 🔹 32-bit Signed Integer
    {
      'group': '32-bit Signed Integer',
      'text': 'Big Endian',
      'value': 'INT32_BE',
    },
    {
      'group': '32-bit Signed Integer',
      'text': 'Little Endian',
      'value': 'INT32_LE',
    },
    {
      'group': '32-bit Signed Integer',
      'text': 'Big Endian + Byte Swap',
      'value': 'INT32_BE_BS',
    },
    {
      'group': '32-bit Signed Integer',
      'text': 'Little Endian + Byte Swap',
      'value': 'INT32_LE_BS',
    },

    // 🔹 32-bit Unsigned Integer
    {
      'group': '32-bit Unsigned Integer',
      'text': 'Big Endian',
      'value': 'UINT32_BE',
    },
    {
      'group': '32-bit Unsigned Integer',
      'text': 'Little Endian',
      'value': 'UINT32_LE',
    },
    {
      'group': '32-bit Unsigned Integer',
      'text': 'Big Endian + Byte Swap',
      'value': 'UINT32_BE_BS',
    },
    {
      'group': '32-bit Unsigned Integer',
      'text': 'Little Endian + Byte Swap',
      'value': 'UINT32_LE_BS',
    },

    // 🔹 32-bit IEEE 754 Float
    {
      'group': '32-bit IEEE 754 Float',
      'text': 'Big Endian',
      'value': 'FLOAT32_BE',
    },
    {
      'group': '32-bit IEEE 754 Float',
      'text': 'Little Endian',
      'value': 'FLOAT32_LE',
    },
    {
      'group': '32-bit IEEE 754 Float',
      'text': 'Big Endian + Byte Swap',
      'value': 'FLOAT32_BE_BS',
    },
    {
      'group': '32-bit IEEE 754 Float',
      'text': 'Little Endian + Byte Swap',
      'value': 'FLOAT32_LE_BS',
    },

    // 🔹 64-bit Signed Integer
    {
      'group': '64-bit Signed Integer',
      'text': 'Big Endian',
      'value': 'INT64_BE',
    },
    {
      'group': '64-bit Signed Integer',
      'text': 'Little Endian',
      'value': 'INT64_LE',
    },
    {
      'group': '64-bit Signed Integer',
      'text': 'Big Endian + Byte Swap',
      'value': 'INT64_BE_BS',
    },
    {
      'group': '64-bit Signed Integer',
      'text': 'Little Endian + Byte Swap',
      'value': 'INT64_LE_BS',
    },

    // 🔹 64-bit Unsigned Integer
    {
      'group': '64-bit Unsigned Integer',
      'text': 'Big Endian',
      'value': 'UINT64_BE',
    },
    {
      'group': '64-bit Unsigned Integer',
      'text': 'Little Endian',
      'value': 'UINT64_LE',
    },
    {
      'group': '64-bit Unsigned Integer',
      'text': 'Big Endian + Byte Swap',
      'value': 'UINT64_BE_BS',
    },
    {
      'group': '64-bit Unsigned Integer',
      'text': 'Little Endian + Byte Swap',
      'value': 'UINT64_LE_BS',
    },

    // 🔹 64-bit IEEE 754 Double
    {
      'group': '64-bit IEEE 754 Double',
      'text': 'Big Endian',
      'value': 'DOUBLE64_BE',
    },
    {
      'group': '64-bit IEEE 754 Double',
      'text': 'Little Endian',
      'value': 'DOUBLE64_LE',
    },
    {
      'group': '64-bit IEEE 754 Double',
      'text': 'Big Endian + Byte Swap',
      'value': 'DOUBLE64_BE_BS',
    },
    {
      'group': '64-bit IEEE 754 Double',
      'text': 'Little Endian + Byte Swap',
      'value': 'DOUBLE64_LE_BS',
    },

    // 🔹 Legacy Types
    {'group': '32-bit Signed (BE)', 'text': 'Legacy Format', 'value': 'INT32'},
    {'group': '32-bit Float (BE)', 'text': 'Legacy Format', 'value': 'FLOAT32'},
    {
      'group': 'Text String (UTF-8 Encoded)',
      'text': 'Variable Length',
      'value': 'STRING',
    },
  ];

  static final List<DropdownItems> modbusReadFunctions = [
    DropdownItems(text: 'Coil Status', value: '1'),
    DropdownItems(text: 'Input Status', value: '2'),
    DropdownItems(text: 'Holding Register', value: '3'),
    DropdownItems(text: 'Input Registers', value: '4'),
  ];

  static final List<DropdownItems> booleanOptions = [
    DropdownItems(text: 'true', value: 'true'),
    DropdownItems(text: 'false', value: 'false'),
  ];
}
