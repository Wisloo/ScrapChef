import 'dart:async';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttService {
  static const String broker = 'broker.hivemq.com';
  static const int port = 1883;
  static const String clientId = 'scrapchef_flutter';
  static const String weightTopic = 'scrapchef/weight';

  MqttServerClient? _client;
  double? _currentWeight;
  final StreamController<double> _weightController = StreamController<double>.broadcast();

  Stream<double> get weightStream => _weightController.stream;
  double? get currentWeight => _currentWeight;

  Future<void> connect() async {
    try {
      _client = MqttServerClient(broker, clientId);
      _client!.port = port;
      _client!.logging(on: false);
      _client!.keepAlivePeriod = 30;
      _client!.onDisconnected = _onDisconnected;
      _client!.onConnected = _onConnected;

      await _client!.connect();
    } catch (e) {
      print('MQTT connection error: $e');
      _scheduleReconnect();
    }
  }

  void _onConnected() {
    print('MQTT connected');
    _subscribeToWeight();
  }

  void _onDisconnected() {
    print('MQTT disconnected');
    _scheduleReconnect();
  }

  void _subscribeToWeight() {
    if (_client == null || _client!.connectionStatus!.state != MqttConnectionState.connected) {
      return;
    }

    _client!.subscribe(weightTopic, MqttQos.atMostOnce);

    _client!.updates!.listen((List<MqttReceivedMessage<MqttMessage?>> events) {
      final MqttReceivedMessage<MqttMessage?> event = events.first;
      final MqttMessage? message = event.payload;

      if (message != null && message is MqttPublishMessage) {
        final payload = MqttPublishPayload.bytesToStringAsString(message.payload.message);
        final weight = double.tryParse(payload);
        if (weight != null) {
          _currentWeight = weight;
          _weightController.add(weight);
          print('Weight received: $weight g');
        }
      }
    });
  }

  void _scheduleReconnect() {
    Future.delayed(const Duration(seconds: 5), () {
      if (_client != null && _client!.connectionStatus!.state != MqttConnectionState.connected) {
        connect();
      }
    });
  }

  Future<void> disconnect() async {
    await _weightController.close();
    if (_client != null) {
      _client!.disconnect();
    }
  }
}
