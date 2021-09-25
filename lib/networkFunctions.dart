import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:teog_swift/dataAction.dart';
import 'package:teog_swift/previewDeviceInfo.dart';

import 'package:teog_swift/swiftResponse.dart';

import 'constants.dart';
import 'deviceInfo.dart';
import 'hospitalDevice.dart';
import 'report.dart';
import 'user.dart';

const String _host = "teog.virlep.de";
const Map<String, String> _headers = {'Content-Type': 'application/json; charset=UTF-8'};
const String _actionIdentifier = "action";
const String _passwordIdentifier = "password";
const String _countryIdentifier = "country";
const String _hospitalIdentifier = "hospital";

Future<bool> checkCredentials(final String country, final int hospital, String password, {final hashPassword: true}) async {
  if(hashPassword) {
    List<int> bytes = utf8.encode(password);
    password = sha256.convert(bytes).toString();
  }

  final Uri uri = Uri.https(_host, 'interface/' + Constants.interfaceVersion.toString() + '/test.php');

  final response = await http.post(
    uri,
    headers: _headers,
    body: jsonEncode(_generateParameterMap(action: DataAction.login, authentication: true))
  );

  if(response.statusCode == 200) {
    SwiftResponse swiftResponse = SwiftResponse.fromJson(jsonDecode(response.body));

    if(swiftResponse.responseCode == 0) {
      return true;
    } else {
      throw Exception(swiftResponse.data.toString());
    }
  } else {
    throw Exception(Constants.generic_error_message);
  }
}

Future<DeviceInfo> fetchDevice(final int deviceId) async {
  final Uri uri = Uri.https(_host, 'interface/' + Constants.interfaceVersion.toString() + '/test.php');

  final response = await http.post(
    uri,
    headers: _headers,
    body: jsonEncode(_generateParameterMap(action: DataAction.fetchDeviceInfo, authentication: true,
        additional: <String, dynamic> {'device_id': deviceId}),
    ),
  );

  if(response.statusCode == 200) {
    SwiftResponse swiftResponse = SwiftResponse.fromJson(jsonDecode(response.body));

    if(swiftResponse.responseCode == 0) {
      return DeviceInfo(
        device: HospitalDevice.fromJson(swiftResponse.data["device"]),
        report: Report.fromJson(swiftResponse.data["report"]),
        imageData: swiftResponse.data["image"],
      );
    } else {
      throw Exception(swiftResponse.data);
    }
  } else {
    print(response.statusCode.toString());
    throw Exception(Constants.generic_error_message);
  }
}

Future<List<PreviewDeviceInfo>> searchDevices(String type, String manufacturer, String location) async {
  final Uri uri = Uri.https(_host, 'interface/' + Constants.interfaceVersion.toString() + '/test.php');

  final response = await http.post(
    uri,
    headers: _headers,
    body: jsonEncode(_generateParameterMap(action: DataAction.searchDevices, authentication: true,
        additional: <String, dynamic> {'type': type, 'manufacturer': manufacturer, 'location': location,})
    ),
  );

  if(response.statusCode == 200) {
    SwiftResponse swiftResponse = SwiftResponse.fromJson(jsonDecode(response.body));
    
    if(swiftResponse.responseCode == 0) {
      print(swiftResponse.data);
      List<PreviewDeviceInfo> devices = [];

      for(var jsonDevice in swiftResponse.data) {
        devices.add(PreviewDeviceInfo(
          device: HospitalDevice.fromJson(jsonDevice["device"]),
          imageData: jsonDevice["image"],
        ));
      }

      return devices;
    } else {
      throw Exception(swiftResponse.data);
    }
  } else {
    print(response.statusCode.toString());
    throw Exception(Constants.generic_error_message);
  }
}

Future<List<DeviceInfo>> getTodoDevices() async {
  final Uri uri = Uri.https(_host, 'interface/' + Constants.interfaceVersion.toString() + '/test.php');

  final response = await http.post(
    uri,
    headers: _headers,
    body: jsonEncode(_generateParameterMap(action: DataAction.getTodoDevices, authentication: true)),
  );

  if(response.statusCode == 200) {
    SwiftResponse swiftResponse = SwiftResponse.fromJson(jsonDecode(response.body));
    
    if(swiftResponse.responseCode == 0) {
      print(swiftResponse.data);
      List<DeviceInfo> devices = [];

      for(var jsonDevice in swiftResponse.data) {
        devices.add(DeviceInfo(
          device: HospitalDevice.fromJson(jsonDevice["device"]),
          report: Report.fromJson(jsonDevice["report"])
        ));
      }

      return devices;
    } else {
      throw Exception(swiftResponse.data);
    }
  } else {
    print(response.statusCode.toString());
    throw Exception(Constants.generic_error_message);
  }
}

Future<List<User>> getUsers() async {
  final Uri uri = Uri.https(_host, 'interface/' + Constants.interfaceVersion.toString() + '/test.php');

  final response = await http.post(
    uri,
    headers: _headers,
    body: jsonEncode(_generateParameterMap(action: DataAction.getUsers, authentication: true)),
  );

  if(response.statusCode == 200) {
    SwiftResponse swiftResponse = SwiftResponse.fromJson(jsonDecode(response.body));
    
    if(swiftResponse.responseCode == 0) {
      print(swiftResponse.data);
      List<User> users = [];

      for(var jsonUser in swiftResponse.data) {
        users.add(User.fromJson(jsonUser));
      }

      return users;
    } else {
      throw Exception(swiftResponse.data);
    }
  } else {
    print(response.statusCode.toString());
    throw Exception(Constants.generic_error_message);
  }
}

Future<List<String>> retrieveDocuments(String manufacturer, String model) async {
  final Uri uri = Uri.https(_host, 'interface/' + Constants.interfaceVersion.toString() + '/documents.php');

  final response = await http.post(
    uri,
    headers: _headers,
    body: jsonEncode(_generateParameterMap(additional: <String, dynamic> {'manufacturer': manufacturer,'model': model})),
  );

  if(response.statusCode == 200) {
    SwiftResponse swiftResponse = SwiftResponse.fromJson(jsonDecode(response.body));

    if(swiftResponse.responseCode == 0) {
      List<String> documents = [];

      for(var jsonDocument in swiftResponse.data) {
        documents.add(jsonDocument);
      }

      return documents;
    } else {
      throw Exception(swiftResponse.data);
    }
  } else {
    print(response.statusCode.toString());
    throw Exception(Constants.generic_error_message);
  }
}

Future<Report> queueRepair(int deviceId, String title, String problemDescription) async {
  final Uri uri = Uri.https(_host, 'interface/' + Constants.interfaceVersion.toString() + '/test.php');

  final response = await http.post(
    uri,
    headers: _headers,
    body: jsonEncode(_generateParameterMap(action: DataAction.queueRepair, authentication: true,
        additional: <String, dynamic> {'device_id': deviceId, 'title': title, 'problem_description': problemDescription,}),
    ),
  );

  if(response.statusCode == 200) {
    SwiftResponse swiftResponse = SwiftResponse.fromJson(jsonDecode(response.body));

    if(swiftResponse.responseCode == 0) {
      return Report.fromJson(swiftResponse.data);
    } else {
      throw Exception(swiftResponse.data);
    }
  } else {
    print(response.statusCode.toString());
    throw Exception(Constants.generic_error_message);
  }
}

Map<String, dynamic> _generateParameterMap({final String action = "", final bool authentication = false, final Map<String, dynamic> additional = const {}}) {
  final Map<String, dynamic> parameterMap = Map();

  if(action.isNotEmpty) {
    parameterMap[_actionIdentifier] = action;
  }

  if(authentication) {
    List<int> bytes = utf8.encode("password");
    String hash = sha256.convert(bytes).toString();

    parameterMap[_countryIdentifier] = "Test";//TODO: get everything from preferences
    parameterMap[_hospitalIdentifier] = 1;
    parameterMap[_passwordIdentifier] = hash;
  }

  return parameterMap;
}
  