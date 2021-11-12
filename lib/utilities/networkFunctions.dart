import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:teog_swift/utilities/dataAction.dart';
import 'package:teog_swift/utilities/previewDeviceInfo.dart';

import 'package:teog_swift/utilities/swiftResponse.dart';

import 'package:teog_swift/utilities/constants.dart';
import 'package:teog_swift/utilities/deviceInfo.dart';
import 'package:teog_swift/utilities/hospitalDevice.dart';
import 'package:teog_swift/utilities/report.dart';
import 'package:teog_swift/utilities/user.dart';
import 'package:teog_swift/utilities/hospital.dart';

const String _host = "teog.virlep.de";
const Map<String, String> _headers = {'Content-Type': 'application/json; charset=UTF-8'};
const String _actionIdentifier = "action";
const String _passwordIdentifier = "password";
const String _countryIdentifier = "country";
const String _hospitalIdentifier = "hospital";

String getBaseUrl() {
  return Uri.https(_host, 'interface/' + Constants.interfaceVersion.toString()).toString();
}

Future<String> checkCredentials(final String country, final int hospital, String password, {final hashPassword: true}) async {
  if(hashPassword) {
    List<int> bytes = utf8.encode(password);
    password = sha256.convert(bytes).toString();
  }

  final Uri uri = Uri.https(_host, 'interface/' + Constants.interfaceVersion.toString() + '/test.php');

  List<int> bytes = utf8.encode(password);
  String hash = sha256.convert(bytes).toString();

  final Map<String, dynamic> parameterMap = Map();
  parameterMap[_actionIdentifier] = DataAction.login;
  parameterMap[_countryIdentifier] = country;
  parameterMap[_hospitalIdentifier] = hospital;
  parameterMap[_passwordIdentifier] = hash;

  final response = await http.post(
    uri,
    headers: _headers,
    body: jsonEncode(parameterMap)
  );

  if(response.statusCode == 200) {
    SwiftResponse swiftResponse = SwiftResponse.fromJson(jsonDecode(response.body));

    if(swiftResponse.responseCode == 0) {
      return swiftResponse.data;
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
    throw Exception(Constants.generic_error_message);
  }
}

Future<List<DeviceInfo>> getDevices() async {
  final Uri uri = Uri.https(_host, 'interface/' + Constants.interfaceVersion.toString() + '/test.php');

  final response = await http.post(
    uri,
    headers: _headers,
    body: jsonEncode(_generateParameterMap(action: DataAction.getDevices, authentication: true)),
  );

  if(response.statusCode == 200) {
    SwiftResponse swiftResponse = SwiftResponse.fromJson(jsonDecode(response.body));
    
    if(swiftResponse.responseCode == 0) {
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
    throw Exception(Constants.generic_error_message);
  }
}

Future<List<User>> createUser(String mail, String name) async {
  final Uri uri = Uri.https(_host, 'interface/' + Constants.interfaceVersion.toString() + '/test.php');

  final response = await http.post(
    uri,
    headers: _headers,
    body: jsonEncode(_generateParameterMap(action: DataAction.createUser, authentication: true,
      additional: <String, dynamic> {'mail': mail, 'name': name})
    ),
  );

  if(response.statusCode == 200) {
    SwiftResponse swiftResponse = SwiftResponse.fromJson(jsonDecode(response.body));
    
    if(swiftResponse.responseCode == 0) {
      List<User> users = [];

      for(var jsonUser in swiftResponse.data) {
        users.add(User.fromJson(jsonUser));
      }

      return users;
    } else {
      throw Exception(swiftResponse.data);
    }
  } else {
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
      List<User> users = [];

      for(var jsonUser in swiftResponse.data) {
        users.add(User.fromJson(jsonUser));
      }

      return users;
    } else {
      throw Exception(swiftResponse.data);
    }
  } else {
    throw Exception(Constants.generic_error_message);
  }
}

Future<List<Hospital>> getHospitals(String country) async {
  final Uri uri = Uri.https(_host, 'interface/' + Constants.interfaceVersion.toString() + '/test.php');

  final response = await http.post(
    uri,
    headers: _headers,
    body: jsonEncode(_generateParameterMap(action: DataAction.getHospitals, authentication: false,
      additional: <String, dynamic> {'country': country}),
    )
  );

  if(response.statusCode == 200) {
    SwiftResponse swiftResponse = SwiftResponse.fromJson(jsonDecode(response.body));
    
    if(swiftResponse.responseCode == 0) {
      List<Hospital> hospitals = [];

      for(var jsonHospital in swiftResponse.data) {
        hospitals.add(Hospital.fromJson(jsonHospital));
      }

      return hospitals;
    } else {
      throw Exception(swiftResponse.data);
    }
  } else {
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

  additional.forEach((key, value) {
    parameterMap[key] = value;
  });

  return parameterMap;
}
  