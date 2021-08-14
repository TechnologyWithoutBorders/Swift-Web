import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import 'package:teog_swift/swiftResponse.dart';

import 'constants.dart';
import 'deviceInfo.dart';
import 'hospitalDevice.dart';
import 'report.dart';

const String _host = "teog.virlep.de";

Future<bool> checkCredentials(String country, int hospital, String password, {hashPassword: true}) async {
  if(hashPassword) {
    List<int> bytes = utf8.encode(password);
    password = sha256.convert(bytes).toString();
  }

  Uri uri = Uri.https(_host, 'interface/' + Constants.interfaceVersion.toString() + '/test.php');

  final response = await http.post(
    uri,
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, dynamic> {
      'action': "login_light",
      'country': country,
      'hospital': hospital,
      'password': password,
    }),
  );

  if(response.statusCode == 200) {
    SwiftResponse swiftResponse = SwiftResponse.fromJson(jsonDecode(response.body));

    if(swiftResponse.responseCode == 0) {
      return true;
    } else {
      throw Exception(swiftResponse.message.toString());
    }
  } else {
    throw Exception("something went wrong");
  }
}

Future<DeviceInfo> fetchDevice(int deviceId) async {
  List<int> bytes = utf8.encode("password");
  String hash = sha256.convert(bytes).toString();

  Uri uri = Uri.https(_host, 'interface/' + Constants.interfaceVersion.toString() + '/test.php');

  final response = await http.post(
    uri,
    headers: <String, String> {
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, dynamic>{
      'action': "fetch_device_info",
      'country': "Test",
      'hospital': 1,
      'device_id': deviceId,
      'password': hash,
    }),
  );

  if(response.statusCode == 200) {
    SwiftResponse swiftResponse = SwiftResponse.fromJson(jsonDecode(response.body));

    if(swiftResponse.responseCode == 0) {
      return DeviceInfo(
        device: HospitalDevice.fromJson(swiftResponse.message["device"]),
        report: Report.fromJson(swiftResponse.message["report"]),
        imageData: swiftResponse.message["image"],
      );
    } else {
      throw Exception(swiftResponse.message);
    }
  } else {
    print(response.statusCode.toString());
    throw Exception('something went wrong');
  }
}

Future<List<HospitalDevice>> searchDevices(String type, String manufacturer, String location) async {
  List<int> bytes = utf8.encode("password");
  String hash = sha256.convert(bytes).toString();

  Uri uri = Uri.https(_host, 'interface/' + Constants.interfaceVersion.toString() + '/test.php');

  final response = await http.post(
    uri,
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, dynamic> {
      'action': "search_devices",
      'country': "Test",
      'hospital': 1,
      'type': type,
      'manufacturer': manufacturer,
      'location': location,
      'password': hash,
    }),
  );

  if(response.statusCode == 200) {
    SwiftResponse swiftResponse = SwiftResponse.fromJson(jsonDecode(response.body));

    if(swiftResponse.responseCode == 0) {
      List<HospitalDevice> devices = [];

      for(var jsonDevice in swiftResponse.message) {
        devices.add(HospitalDevice.fromJson(jsonDevice));
      }

      return devices;
    } else {
      throw Exception(swiftResponse.message);
    }
  } else {
    print(response.statusCode.toString());
    throw Exception('something went wrong');
  }
}

Future<List<String>> retrieveDocuments(String manufacturer, String model) async {
  Uri uri = Uri.https(_host, 'interface/' + Constants.interfaceVersion.toString() + '/documents.php');

  final response = await http.post(
    uri,
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, dynamic> {
      'manufacturer': manufacturer,
      'model': model,
    }),
  );

  if(response.statusCode == 200) {
    SwiftResponse swiftResponse = SwiftResponse.fromJson(jsonDecode(response.body));

    if(swiftResponse.responseCode == 0) {
      List<String> documents = [];

      for(var jsonDocument in swiftResponse.message) {
        documents.add(jsonDocument);
      }

      return documents;
    } else {
      throw Exception(swiftResponse.message);
    }
  } else {
    print(response.statusCode.toString());
    throw Exception('something went wrong');
  }
}

Future<DeviceInfo> queueRepair(String content) async {//TODO image muss eigentlich nicht mit zurückgegeben werden
  List<int> bytes = utf8.encode("password");
  String hash = sha256.convert(bytes).toString();

  Uri uri = Uri.https(_host, 'interface/' + Constants.interfaceVersion.toString() + '/test.php');

  final response = await http.post(
    uri,
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, dynamic> {
      'action': "queue_repair",
      'country': "Test",
      'hospital': "1",
      'password': hash,
    }),
  );

  if(response.statusCode == 200) {
    SwiftResponse swiftResponse = SwiftResponse.fromJson(jsonDecode(response.body));

    if(swiftResponse.responseCode == 0) {
      return DeviceInfo(
        device: HospitalDevice.fromJson(swiftResponse.message["device"]),
        report: Report.fromJson(swiftResponse.message["report"]),
        imageData: swiftResponse.message["image"],
      );
    } else {
      throw Exception(swiftResponse.message);
    }
  } else {
    print(response.statusCode.toString());
    throw Exception('something went wrong');
  }
}
  