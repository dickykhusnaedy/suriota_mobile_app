import 'dart:async';
import 'dart:convert';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gateway_config/core/controllers/ble_controller.dart';
import 'package:gateway_config/models/device_model.dart';
import 'package:get/get.dart';
import 'package:mockito/mockito.dart';

import '../../mocks/mocks.mocks.mocks.dart';

void main() {
  group('BleController Tests', () {
    late BleController controller;
    late MockBluetoothDevice mockDevice;
    late MockBluetoothService mockService;
    late MockBluetoothCharacteristic mockCommandChar;
    late MockBluetoothCharacteristic mockResponseChar;
    late MockStreamSubscription<BluetoothConnectionState>
    mockStreamSubscription;
    late MockScanResult mockScanResult;

    setUp(() async {
      // Inisialisasi GetX untuk test
      Get.testMode = true;
      controller = BleController();
      mockDevice = MockBluetoothDevice();
      mockService = MockBluetoothService();
      mockCommandChar = MockBluetoothCharacteristic();
      mockResponseChar = MockBluetoothCharacteristic();
      mockStreamSubscription =
          MockStreamSubscription<BluetoothConnectionState>();
      mockScanResult = MockScanResult();

      // Setup mock default
      when(mockDevice.id).thenReturn(DeviceIdentifier('id1'));
      when(mockDevice.name).thenReturn('SURIOTA CRUD Service');
      when(
        mockDevice.connectionState,
      ).thenAnswer((_) => Stream.value(BluetoothConnectionState.disconnected));
      when(mockScanResult.device).thenReturn(mockDevice);
      // Reset response buffer dan response untuk test handleNotification
      controller.responseBuffer = '';
      controller.response.value = '';
    });

    tearDown(() {
      controller.onClose(); // Reset controller setelah setiap test
      Get.reset(); // Reset GetX state
    });

    test('Initial state is correct', () {
      expect(controller.isScanning.value, false);
      expect(controller.isLoading.value, false);
      expect(controller.isLoadingConnectionGlobal.value, false);
      expect(controller.connectedDevice.value, isNull);
      expect(controller.response.value, '');
      expect(controller.errorMessage.value, '');
      expect(controller.scannedDevices, isEmpty);
    });

    test('startScan does nothing if already scanning or loading', () async {
      controller.isScanning.value = true;
      await controller.startScan();
      verifyNever(FlutterBluePlus.startScan(timeout: anyNamed('timeout')));

      controller.isScanning.value = false;
      controller.isLoading.value = true;
      await controller.startScan();
      verifyNever(FlutterBluePlus.startScan(timeout: anyNamed('timeout')));
    });

    test('startScan handles Bluetooth off', () async {
      when(FlutterBluePlus.isOn).thenAnswer((_) async => false);

      await controller.startScan();

      expect(controller.isLoading.value, false);
      expect(controller.isScanning.value, false);
      expect(controller.errorMessage.value, 'Bluetooth is turned off');
    });

    test('startScan adds devices to scannedDevices', () async {
      when(FlutterBluePlus.isOn).thenAnswer((_) async => true);
      when(
        FlutterBluePlus.startScan(timeout: anyNamed('timeout')),
      ).thenAnswer((_) async {});
      when(
        FlutterBluePlus.scanResults,
      ).thenAnswer((_) => Stream.value([mockScanResult]));
      when(FlutterBluePlus.stopScan()).thenAnswer((_) async {});

      await controller.startScan();

      await Future.delayed(const Duration(milliseconds: 100));
      expect(controller.scannedDevices.length, 1);
      expect(controller.scannedDevices[0].device.id, DeviceIdentifier('id1'));
      expect(controller.scannedDevices[0].device.name, 'SURIOTA CRUD Service');
      expect(controller.scannedDevices[0].isConnected.value, false);
    });

    test('handleScannedDevice skips duplicate devices', () {
      final deviceModel = DeviceModel(
        device: mockDevice,
        onConnect: () {},
        onDisconnect: () {},
      );
      controller.scannedDevices.add(deviceModel);

      controller.handleScannedDevice(mockDevice);

      expect(controller.scannedDevices.length, 1); // Tidak bertambah
    });

    test(
      'handleScannedDevice updates isConnected on connection state change',
      () async {
        when(mockDevice.connectionState).thenAnswer(
          (_) => Stream.fromIterable([
            BluetoothConnectionState.disconnected,
            BluetoothConnectionState.connected,
            BluetoothConnectionState.disconnected,
          ]),
        );

        controller.handleScannedDevice(mockDevice);

        await Future.delayed(const Duration(milliseconds: 100));
        expect(controller.scannedDevices.length, 1);
        expect(
          controller.scannedDevices[0].isConnected.value,
          false,
        ); // Terakhir disconnected
      },
    );

    test('connectToDevice fails when service not found', () async {
      when(mockDevice.connect()).thenAnswer((_) async {});
      when(mockDevice.discoverServices()).thenAnswer((_) async => []);

      final deviceModel = DeviceModel(
        device: mockDevice,
        onConnect: () {},
        onDisconnect: () {},
      );

      await controller.connectToDevice(deviceModel);

      expect(controller.isLoadingConnectionGlobal.value, false);
      expect(deviceModel.isLoadingConnection.value, false);
      expect(controller.errorMessage.value, 'Service not found');
      expect(controller.connectedDevice.value, isNull);
    });

    test('connectToDevice succeeds and shows dialog', () async {
      when(mockDevice.connect()).thenAnswer((_) async {});
      when(
        mockDevice.discoverServices(),
      ).thenAnswer((_) async => [mockService]);
      when(
        mockService.characteristics,
      ).thenReturn([mockCommandChar, mockResponseChar]);
      when(mockCommandChar.uuid).thenReturn(controller.commandUUID);
      when(mockResponseChar.uuid).thenReturn(controller.responseUUID);
      when(mockResponseChar.setNotifyValue(true)).thenAnswer((_) async => true);
      when(
        mockResponseChar.lastValueStream,
      ).thenAnswer((_) => Stream.value([]));

      final deviceModel = DeviceModel(
        device: mockDevice,
        onConnect: () {},
        onDisconnect: () {},
      );

      await controller.connectToDevice(deviceModel);

      expect(controller.connectedDevice.value, mockDevice);
      expect(controller.isLoadingConnectionGlobal.value, false);
      expect(deviceModel.isLoadingConnection.value, false);
    });

    test('disconnectFromDevice resets state and updates isConnected', () async {
      when(mockDevice.connectionState).thenAnswer(
        (_) => Stream.fromIterable([
          BluetoothConnectionState.connected,
          BluetoothConnectionState.disconnected,
        ]),
      );
      when(mockDevice.disconnect()).thenAnswer((_) async {});
      controller.responseSubscription = mockStreamSubscription;

      final deviceModel = DeviceModel(
        device: mockDevice,
        onConnect: () {},
        onDisconnect: () {},
      );
      deviceModel.isConnected.value = true;
      controller.connectedDevice.value = mockDevice;

      await controller.disconnectFromDevice(deviceModel);

      expect(controller.isLoadingConnectionGlobal.value, false);
      expect(deviceModel.isConnected.value, false);
      expect(controller.connectedDevice.value, isNull);
      expect(controller.commandChar, isNull);
      expect(controller.responseChar, isNull);
      expect(controller.response.value, '');
      verify(mockDevice.disconnect()).called(1);
      verify(mockStreamSubscription.cancel()).called(1);
    });

    test('sendCommand fails when not connected', () async {
      controller.commandChar = null;

      await controller.sendCommand({"op": "read"});

      expect(controller.errorMessage.value, 'Not connected');
      expect(controller.isLoading.value, false);
    });

    test('sendCommand sends chunked JSON', () async {
      controller.commandChar = mockCommandChar;
      when(mockCommandChar.write(any)).thenAnswer((_) async => true);

      final command = {"op": "read", "type": "devices"};
      await controller.sendCommand(command);

      verify(
        mockCommandChar.write(argThat(isA<List<int>>())),
      ).called(greaterThan(0));
      verify(mockCommandChar.write(utf8.encode('<END>'))).called(1);
      expect(controller.isLoading.value, false);
    });

    test('handleNotification assembles valid JSON', () async {
      controller.handleNotificationForTest(
        utf8.encode('{"status":"ok","devices":['),
      );
      controller.handleNotificationForTest(utf8.encode('"D123"]'));
      controller.handleNotificationForTest(utf8.encode('<END>'));

      expect(controller.response.value, '{"status":"ok","devices":["D123"]}');
      expect(controller.responseBuffer, '');
    });

    test('handleNotification handles invalid JSON', () async {
      controller.handleNotificationForTest(utf8.encode('invalid json'));
      controller.handleNotificationForTest(utf8.encode('<END>'));

      expect(
        controller.errorMessage.value.contains('Invalid response JSON'),
        true,
      );
      expect(controller.responseBuffer, '');
    });

    test('findDeviceByRemoteId returns DeviceModel', () async {
      final mockDevice2 = MockBluetoothDevice();
      when(mockDevice2.id).thenReturn(DeviceIdentifier('id2'));
      when(mockDevice2.name).thenReturn('Other Device');

      final deviceModel1 = DeviceModel(
        device: mockDevice,
        onConnect: () {},
        onDisconnect: () {},
      );
      final deviceModel2 = DeviceModel(
        device: mockDevice2,
        onConnect: () {},
        onDisconnect: () {},
      );
      controller.scannedDevices.addAll([deviceModel1, deviceModel2]);

      final foundModel = controller.findDeviceByRemoteId('id1');
      expect(foundModel, isNotNull);
      expect(foundModel, isA<DeviceModel>());
      expect(foundModel!.device.remoteId, DeviceIdentifier('id1'));
      expect(foundModel.device.platformName, 'SURIOTA CRUD Service');

      final notFoundModel = controller.findDeviceByRemoteId('id3');
      expect(notFoundModel, isNull);
    });

    test('onClose disconnects all devices', () async {
      when(mockDevice.disconnect()).thenAnswer((_) async {});
      final deviceModel = DeviceModel(
        device: mockDevice,
        onConnect: () {},
        onDisconnect: () {},
      );
      controller.scannedDevices.add(deviceModel);

      controller.onClose();

      verify(mockDevice.disconnect()).called(1);
      expect(controller.scannedDevices, isEmpty);
    });
  });
}
