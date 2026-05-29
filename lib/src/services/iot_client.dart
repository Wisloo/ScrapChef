import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:connectivity_plus/connectivity_plus.dart';

import '../models.dart' as model;

class IoTClient {
  final String _apiEndpoint = 'http://localhost:3000/scrap-data';

  Future<bool> isConnected() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult == ConnectivityResult.wifi;
  }

  Future<void> sendScrapData(model.ScrapItem scrap) async {
    if (!await isConnected()) {
      print('No WiFi connection available');
      return;
    }
    try {
      final response = await http.post(
        Uri.parse(_apiEndpoint),
        body: jsonEncode(scrap.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        print('Scrap data sent successfully');
      } else {
        print('Failed to send scrap data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending scrap data: $e');
    }
  }
}