import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:teog_swift/screens/organization_filter_view.dart';
import 'package:teog_swift/utilities/country.dart';
import 'package:teog_swift/utilities/data_action.dart';
import 'package:teog_swift/utilities/device_info.dart';
import 'package:teog_swift/utilities/device_state.dart';
import 'package:teog_swift/utilities/device_stats.dart';
import 'package:teog_swift/utilities/maintenance_event.dart';
import 'package:teog_swift/utilities/organizational_relation.dart';
import 'package:teog_swift/utilities/organizational_unit.dart';
import 'package:teog_swift/utilities/preview_device_info.dart';

import 'package:teog_swift/utilities/swift_response.dart';

import 'package:teog_swift/utilities/constants.dart';
import 'package:teog_swift/utilities/short_device_info.dart';
import 'package:teog_swift/utilities/hospital_device.dart';
import 'package:teog_swift/utilities/report.dart';
import 'package:teog_swift/utilities/detailed_report.dart';
import 'package:teog_swift/utilities/user.dart';
import 'package:teog_swift/utilities/hospital.dart';
import 'package:teog_swift/utilities/message_exception.dart';

import 'package:teog_swift/utilities/preference_manager.dart' as prefs;

const String _host = "teog.virlep.de";
const Map<String, String> _headers = {'Content-Type': 'application/json; charset=UTF-8'};
const String _actionIdentifier = "action";
const String _passwordIdentifier = "password";
const String _countryIdentifier = "country";
const String _hospitalIdentifier = "hospital";
const String _roleIdentifier = "role";
const String _userIdentifier = "user";

String getBaseUrl() {
  return Uri.https(_host, 'interface/').toString();
}

Future<String> checkCredentials(final String country, final int hospital, String password, {final hashPassword = true}) async {
  if(hashPassword) {
    List<int> bytes = utf8.encode(password);
    password = sha256.convert(bytes).toString();
  }

  final Uri uri = Uri.https(_host, 'interface/${Constants.interfaceVersion}/test.php');

  final Map<String, dynamic> parameterMap = {};
  parameterMap[_actionIdentifier] = DataAction.login;
  parameterMap[_countryIdentifier] = country;
  parameterMap[_hospitalIdentifier] = hospital;
  parameterMap[_passwordIdentifier] = password;

  final response = await http.post(
    uri,
    headers: _headers,
    body: jsonEncode(parameterMap)
  );

  if(response.statusCode == 200) {
    SwiftResponse swiftResponse = SwiftResponse.fromJson(jsonDecode(response.body));
    
    if(swiftResponse.responseCode == 0) {
      return swiftResponse.data.toString();
    } else {
      throw MessageException(swiftResponse.data.toString());
    }
  } else {
    throw MessageException(Constants.genericErrorMessage);
  }
}

Future<ShortDeviceInfo> fetchDevice(final int deviceId) async {
  final Uri uri = Uri.https(_host, 'interface/${Constants.interfaceVersion}/test.php');

  final response = await http.post(
    uri,
    headers: _headers,
    body: jsonEncode(await _generateParameterMap(action: DataAction.fetchDeviceInfo, authentication: true,
        additional: <String, dynamic> {'device_id': deviceId}),
    ),
  );

  if(response.statusCode == 200) {
    SwiftResponse swiftResponse = SwiftResponse.fromJson(jsonDecode(response.body));

    if(swiftResponse.responseCode == 0) {
      return ShortDeviceInfo(
        device: HospitalDevice.fromJson(swiftResponse.data["device"]),
        report: Report.fromJson(swiftResponse.data["report"]),
        imageData: swiftResponse.data["image"],
      );
    } else {
      throw MessageException(swiftResponse.data);
    }
  } else {
    throw MessageException(Constants.genericErrorMessage);
  }
}

Future<DeviceInfo> getDeviceInfo(final int deviceId) async {
  final Uri uri = Uri.https(_host, 'interface/${Constants.interfaceVersion}/test.php');

  final response = await http.post(
    uri,
    headers: _headers,
    body: jsonEncode(await _generateParameterMap(action: DataAction.getDeviceInfo, authentication: true,
        additional: <String, dynamic> {'device_id': deviceId}),
    ),
  );

  if(response.statusCode == 200) {
    SwiftResponse swiftResponse = SwiftResponse.fromJson(jsonDecode(response.body));

    if(swiftResponse.responseCode == 0) {
      List<DetailedReport> reports = [];

      for(var jsonReport in swiftResponse.data["reports"]) {
        reports.add(DetailedReport.fromJson(jsonReport));
      }

      reports.sort((a, b) => a.id.compareTo(b.id));

      return DeviceInfo(
        device: HospitalDevice.fromJson(swiftResponse.data["device"]),
        reports: reports,
        imageData: swiftResponse.data["image"],
      );
    } else {
      throw MessageException(swiftResponse.data);
    }
  } else {
    throw MessageException(Constants.genericErrorMessage);
  }
}

Future<DeviceInfo> editDevice(HospitalDevice device) async {
  final Uri uri = Uri.https(_host, 'interface/${Constants.interfaceVersion}/test.php');

  final response = await http.post(
    uri,
    headers: _headers,
    body: jsonEncode(await _generateParameterMap(action: DataAction.editDevice, authentication: true,
        additional: <String, dynamic> {'device': device.toJson()}),
    ),
  );

  if(response.statusCode == 200) {
    SwiftResponse swiftResponse = SwiftResponse.fromJson(jsonDecode(response.body));

    if(swiftResponse.responseCode == 0) {
      List<DetailedReport> reports = [];

      for(var jsonReport in swiftResponse.data["reports"]) {
        reports.add(DetailedReport.fromJson(jsonReport));
      }

      reports.sort((a, b) => a.id.compareTo(b.id));

      return DeviceInfo(
        device: HospitalDevice.fromJson(swiftResponse.data["device"]),
        reports: reports,
        imageData: swiftResponse.data["image"],
      );
    } else {
      throw MessageException(swiftResponse.data);
    }
  } else {
    throw MessageException(Constants.genericErrorMessage);
  }
}

Future<User> editUser(User user) async {
  final Uri uri = Uri.https(_host, 'interface/${Constants.interfaceVersion}/test.php');

  final response = await http.post(
    uri,
    headers: _headers,
    body: jsonEncode(await _generateParameterMap(action: DataAction.editUser, authentication: true,
        additional: <String, dynamic> {'user': user.toJson()}),
    ),
  );

  if(response.statusCode == 200) {
    SwiftResponse swiftResponse = SwiftResponse.fromJson(jsonDecode(response.body));

    if(swiftResponse.responseCode == 0) {
      return User.fromJson(swiftResponse.data);
    } else {
      throw MessageException(swiftResponse.data);
    }
  } else {
    throw MessageException(Constants.genericErrorMessage);
  }
}

Future<bool> deleteDevice(HospitalDevice device) async {
  final Uri uri = Uri.https(_host, 'interface/${Constants.interfaceVersion}/test.php');

  final response = await http.post(
    uri,
    headers: _headers,
    body: jsonEncode(await _generateParameterMap(action: DataAction.deleteDevice, authentication: true,
        additional: <String, dynamic> {'device': device.toJson()}),
    ),
  );

  if(response.statusCode == 200) {
    SwiftResponse swiftResponse = SwiftResponse.fromJson(jsonDecode(response.body));

    if(swiftResponse.responseCode == 0) {
      return true;
    } else {
      throw MessageException(swiftResponse.data);
    }
  } else {
    throw MessageException(Constants.genericErrorMessage);
  }
}

Future<List<PreviewDeviceInfo>> searchDevices(String? type, String? manufacturer, {DepartmentFilter? filter}) async {
  final Uri uri = Uri.https(_host, 'interface/${Constants.interfaceVersion}/test.php');

  List<int>? orgUnits;

  if(filter != null) {
    orgUnits = [filter.parent.id];
    orgUnits.addAll(filter.successors);
  } else {
    orgUnits = null;
  }

  final response = await http.post(
    uri,
    headers: _headers,
    body: jsonEncode(await _generateParameterMap(action: DataAction.searchDevices, authentication: true,
        additional: <String, dynamic> {'type': type, 'manufacturer': manufacturer, 'orgUnits': orgUnits})
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
      throw MessageException(swiftResponse.data);
    }
  } else {
    throw MessageException(Constants.genericErrorMessage);
  }
}

Future<List<ShortDeviceInfo>> getDevices() async {
  final Uri uri = Uri.https(_host, 'interface/${Constants.interfaceVersion}/test.php');

  final response = await http.post(
    uri,
    headers: _headers,
    body: jsonEncode(await _generateParameterMap(action: DataAction.getDevices, authentication: true)),
  );

  if(response.statusCode == 200) {
    SwiftResponse swiftResponse = SwiftResponse.fromJson(jsonDecode(response.body));
    
    if(swiftResponse.responseCode == 0) {
      List<ShortDeviceInfo> devices = [];

      for(var jsonDevice in swiftResponse.data) {
        devices.add(ShortDeviceInfo(
          device: HospitalDevice.fromJson(jsonDevice["device"]),
          report: Report.fromJson(jsonDevice["report"])
        ));
      }

      return devices;
    } else {
      throw MessageException(swiftResponse.data);
    }
  } else {
    throw MessageException(Constants.genericErrorMessage);
  }
}

Future<List<MaintenanceEvent>> getMaintenanceEvents() async {
  final Uri uri = Uri.https(_host, 'interface/${Constants.interfaceVersion}/test.php');

  final response = await http.post(
    uri,
    headers: _headers,
    body: jsonEncode(await _generateParameterMap(action: DataAction.getMaintenanceEvents, authentication: true)),
  );

  if(response.statusCode == 200) {
    SwiftResponse swiftResponse = SwiftResponse.fromJson(jsonDecode(response.body));
    
    if(swiftResponse.responseCode == 0) {
      List<MaintenanceEvent> events = [];

      for(var jsonEvent in swiftResponse.data) {
        events.add(MaintenanceEvent(
          dateTime: DateTime.parse(jsonEvent["datetime"]),
          device: HospitalDevice.fromJson(jsonEvent["device"])
        ));
      }

      return events;
    } else {
      throw MessageException(swiftResponse.data);
    }
  } else {
    throw MessageException(Constants.genericErrorMessage);
  }
}

Future<List<ShortDeviceInfo>> getTodoDevices() async {
  final Uri uri = Uri.https(_host, 'interface/${Constants.interfaceVersion}/test.php');

  final response = await http.post(
    uri,
    headers: _headers,
    body: jsonEncode(await _generateParameterMap(action: DataAction.getTodoDevices, authentication: true)),
  );

  if(response.statusCode == 200) {
    SwiftResponse swiftResponse = SwiftResponse.fromJson(jsonDecode(response.body));
    
    if(swiftResponse.responseCode == 0) {
      List<ShortDeviceInfo> devices = [];

      for(var jsonDevice in swiftResponse.data) {
        devices.add(ShortDeviceInfo(
          device: HospitalDevice.fromJson(jsonDevice["device"]),
          report: Report.fromJson(jsonDevice["report"])
        ));
      }

      return devices;
    } else {
      throw MessageException(swiftResponse.data);
    }
  } else {
    throw MessageException(Constants.genericErrorMessage);
  }
}

Future<DeviceStats> getDeviceStats() async {
  final Uri uri = Uri.https(_host, 'interface/${Constants.interfaceVersion}/test.php');

  final response = await http.post(
    uri,
    headers: _headers,
    body: jsonEncode(await _generateParameterMap(action: DataAction.getDeviceStats, authentication: true)),
  );

  if(response.statusCode == 200) {
    SwiftResponse swiftResponse = SwiftResponse.fromJson(jsonDecode(response.body));
    
    if(swiftResponse.responseCode == 0) {
      return DeviceStats.fromJson(swiftResponse.data);
    } else {
      throw MessageException(swiftResponse.data);
    }
  } else {
    throw MessageException(Constants.genericErrorMessage);
  }
}

Future<List<User>> createUser(String mail, String name) async {
  final Uri uri = Uri.https(_host, 'interface/${Constants.interfaceVersion}/test.php');

  final response = await http.post(
    uri,
    headers: _headers,
    body: jsonEncode(await _generateParameterMap(action: DataAction.createUser, authentication: true,
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
      throw MessageException(swiftResponse.data);
    }
  } else {
    throw MessageException(Constants.genericErrorMessage);
  }
}

Future<List<User>> getUsers() async {
  final Uri uri = Uri.https(_host, 'interface/${Constants.interfaceVersion}/test.php');

  final response = await http.post(
    uri,
    headers: _headers,
    body: jsonEncode(await _generateParameterMap(action: DataAction.getUsers, authentication: true)),
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
      throw MessageException(swiftResponse.data);
    }
  } else {
    throw MessageException(Constants.genericErrorMessage);
  }
}

Future<Map<int, List<DetailedReport>>> getRecentActivity() async {
  final Uri uri = Uri.https(_host, 'interface/${Constants.interfaceVersion}/test.php');

  final response = await http.post(
    uri,
    headers: _headers,
    body: jsonEncode(await _generateParameterMap(action: DataAction.getRecentActivity, authentication: true)),
  );

  if(response.statusCode == 200) {
    SwiftResponse swiftResponse = SwiftResponse.fromJson(jsonDecode(response.body));
    
    if(swiftResponse.responseCode == 0) {
      Map<int, List<DetailedReport>> reports = {};

      for(var jsonReport in swiftResponse.data["reports"]) {
        DetailedReport report = DetailedReport.fromJson(jsonReport);

        if(reports.containsKey(report.deviceId)) {
          reports[report.deviceId]!.add(report);
        } else {
          List<DetailedReport> deviceReports = [report];

          reports[report.deviceId] = deviceReports;
        }
      }

      return reports;
    } else {
      throw MessageException(swiftResponse.data);
    }
  } else {
    throw MessageException(Constants.genericErrorMessage);
  }
}

Future<List<Hospital>> getHospitals(String country) async {
  final Uri uri = Uri.https(_host, 'interface/${Constants.interfaceVersion}/test.php');

  final response = await http.post(
    uri,
    headers: _headers,
    body: jsonEncode(await _generateParameterMap(action: DataAction.getHospitals, authentication: false,
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
      throw MessageException(swiftResponse.data);
    }
  } else {
    throw MessageException(Constants.genericErrorMessage);
  }
}

Future<Hospital> getHospitalInfo() async {
  final Uri uri = Uri.https(_host, 'interface/${Constants.interfaceVersion}/test.php');

  final response = await http.post(
    uri,
    headers: _headers,
    body: jsonEncode(await _generateParameterMap(action: DataAction.getHospitalInfo, authentication: true),
    )
  );

  if(response.statusCode == 200) {
    SwiftResponse swiftResponse = SwiftResponse.fromJson(jsonDecode(response.body));
    
    if(swiftResponse.responseCode == 0) {
      return Hospital.fromJson(swiftResponse.data);
    } else {
      throw MessageException(swiftResponse.data);
    }
  } else {
    throw MessageException(Constants.genericErrorMessage);
  }
}

Future<Image?> getHospitalImage() async {
  final Uri uri = Uri.https(_host, 'interface/${Constants.interfaceVersion}/test.php');

  final response = await http.post(
    uri,
    headers: _headers,
    body: jsonEncode(await _generateParameterMap(action: DataAction.getHospitalImage, authentication: true),
    )
  );

  if(response.statusCode == 200) {
    SwiftResponse swiftResponse = SwiftResponse.fromJson(jsonDecode(response.body));
    
    if(swiftResponse.responseCode == 0) {
      if(swiftResponse.data != null && swiftResponse.data.isNotEmpty) {
        return Image.memory(base64Decode(swiftResponse.data));
      } else {
        return null;
      }
    } else {
      throw MessageException(swiftResponse.data);
    }
  } else {
    throw MessageException(Constants.genericErrorMessage);
  }
}

Future<List<Country>> getCountries() async {
  final Uri uri = Uri.https(_host, 'interface/${Constants.interfaceVersion}/test.php');

  final response = await http.post(
    uri,
    headers: _headers,
    body: jsonEncode(await _generateParameterMap(action: DataAction.getCountries, authentication: false))
  );

  if(response.statusCode == 200) {
    SwiftResponse swiftResponse = SwiftResponse.fromJson(jsonDecode(response.body));
    
    if(swiftResponse.responseCode == 0) {
      List<Country> countries = [];

      for(String countryInfo in swiftResponse.data) {
        countries.add(Country.fromString(countryInfo));
      }

      return countries;
    } else {
      throw MessageException(swiftResponse.data);
    }
  } else {
    throw MessageException(Constants.genericErrorMessage);
  }
}

Future<List<String>> retrieveDocuments(String manufacturer, String model) async {
  final Uri uri = Uri.https(_host, 'interface/${Constants.interfaceVersion}/documents.php');

  final response = await http.post(
    uri,
    headers: _headers,
    body: jsonEncode(await _generateParameterMap(additional: <String, dynamic> {'manufacturer': manufacturer,'model': model})),
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
      throw MessageException(swiftResponse.data);
    }
  } else {
    throw MessageException(Constants.genericErrorMessage);
  }
}

Future<Report> queueRepair(int deviceId, String title, String problemDescription) async {
  final Uri uri = Uri.https(_host, 'interface/${Constants.interfaceVersion}/test.php');
  
  final response = await http.post(
    uri,
    headers: _headers,
    body: jsonEncode(await _generateParameterMap(action: DataAction.createReport, authentication: true,
        additional: <String, dynamic> {'device_id': deviceId, 'title': title, 'description': problemDescription, 'current_state': DeviceState.broken}),
    ),
  );

  if(response.statusCode == 200) {
    SwiftResponse swiftResponse = SwiftResponse.fromJson(jsonDecode(response.body));

    if(swiftResponse.responseCode == 0) {
      return Report.fromJson(swiftResponse.data);
    } else {
      throw MessageException(swiftResponse.data);
    }
  } else {
    throw MessageException(Constants.genericErrorMessage);
  }
}

Future<DetailedReport> createReport(int authorId, int deviceId, String title, String description, int currentState) async {
  final Uri uri = Uri.https(_host, 'interface/${Constants.interfaceVersion}/test.php');
  
  final response = await http.post(
    uri,
    headers: _headers,
    body: jsonEncode(await _generateParameterMap(action: DataAction.createReport, authentication: true,
        additional: <String, dynamic> {'author_id': authorId, 'device_id': deviceId, 'title': title, 'description': description, 'current_state': currentState}),
    ),
  );

  if(response.statusCode == 200) {
    SwiftResponse swiftResponse = SwiftResponse.fromJson(jsonDecode(response.body));

    if(swiftResponse.responseCode == 0) {
      return DetailedReport.fromJson(swiftResponse.data);
    } else {
      throw MessageException(swiftResponse.data);
    }
  } else {
    throw MessageException(Constants.genericErrorMessage);
  }
}

Future<List<String>> uploadDocument(String manufacturer, String model, String name, Uint8List bytes) async {
  final Uri uri = Uri.https(_host, 'interface/${Constants.interfaceVersion}/test.php');
  
  final response = await http.post(
    uri,
    headers: _headers,
    body: jsonEncode(await _generateParameterMap(action: DataAction.uploadDocument, authentication: true,
        additional: <String, dynamic> {'manufacturer': manufacturer, 'model': model, 'file_name': name, 'file_content': base64.encode(bytes)}),
    ),
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
      throw MessageException(swiftResponse.data);
    }
  } else {
    throw MessageException(Constants.genericErrorMessage);
  }
}

Future<List<DeviceInfo>> getAllDeviceInfos() async {
  final Uri uri = Uri.https(_host, 'interface/${Constants.interfaceVersion}/test.php');

  final response = await http.post(
    uri,
    headers: _headers,
    body: jsonEncode(await _generateParameterMap(action: DataAction.getDeviceInfos, authentication: true))
  );

  if(response.statusCode == 200) {
    SwiftResponse swiftResponse = SwiftResponse.fromJson(jsonDecode(response.body));

    if(swiftResponse.responseCode == 0) {
      List<DeviceInfo> deviceInfos = [];

      for(var jsonDeviceInfo in swiftResponse.data) {
        List<DetailedReport> reports = [];

        for(var jsonReport in jsonDeviceInfo["reports"]) {
          reports.add(DetailedReport.fromJson(jsonReport));
        }

        reports.sort((a, b) => b.id.compareTo(a.id));

        deviceInfos.add(DeviceInfo(
          device: HospitalDevice.fromJson(jsonDeviceInfo["device"]),
          reports: reports,
        ));
      }

      return deviceInfos;
    } else {
      throw MessageException(swiftResponse.data);
    }
  } else {
    throw MessageException(Constants.genericErrorMessage);
  }
}

Future<OrganizationalInfo> getOrganizationalInfo() async {
  final Uri uri = Uri.https(_host, 'interface/${Constants.interfaceVersion}/test.php');

  final response = await http.post(
    uri,
    headers: _headers,
    body: jsonEncode(await _generateParameterMap(action: DataAction.getOrganizationalUnits, authentication: true),
    ),
  );

  if(response.statusCode == 200) {
    SwiftResponse swiftResponse = SwiftResponse.fromJson(jsonDecode(response.body));

    if(swiftResponse.responseCode == 0) {
      List<OrganizationalUnit> units = [];
      List<OrganizationalRelation> relations = [];

      for(var jsonUnit in swiftResponse.data['orgUnits']) {
        units.add(OrganizationalUnit.fromJson(jsonUnit));
      }

      for(var jsonRelation in swiftResponse.data['orgRelations']) {
        relations.add(OrganizationalRelation.fromJson(jsonRelation));
      }

      return OrganizationalInfo(units: units, relations: relations);
    } else {
      throw MessageException(swiftResponse.data);
    }
  } else {
    throw MessageException(Constants.genericErrorMessage);
  }
}

Future<bool> updateOrganizationalInfo(List<OrganizationalUnit> orgUnits, List<OrganizationalRelation> orgRelations, List<DeviceRelation> deviceRelations) async {
  final Uri uri = Uri.https(_host, 'interface/${Constants.interfaceVersion}/test.php');

  final Map<String, dynamic> orgInfo = {};

  List<Map<String, dynamic>> orgUnitList = [];
  for(var orgUnit in orgUnits) {
    orgUnitList.add(orgUnit.toJson());
  }

  List<Map<String, dynamic>> orgRelationList = [];
  for(var orgRelation in orgRelations) {
    orgRelationList.add(orgRelation.toJson());
  }

  List<Map<String, dynamic>> deviceRelationList = [];
  for(var deviceRelation in deviceRelations) {
    deviceRelationList.add(deviceRelation.toJson());
  }

  orgInfo['orgUnits'] = orgUnitList;
  orgInfo['orgRelations'] = orgRelationList;
  orgInfo['deviceRelations'] = deviceRelationList;

  final response = await http.post(
    uri,
    headers: _headers,
    body: jsonEncode(await _generateParameterMap(action: DataAction.updateOrganizationalUnits, authentication: true,
      additional: <String, dynamic> {'orgInfo': orgInfo}),
    ),
  );

  if(response.statusCode == 200) {
    SwiftResponse swiftResponse = SwiftResponse.fromJson(jsonDecode(response.body));

    if(swiftResponse.responseCode == 0) {
      return true;
    } else {
      throw MessageException(swiftResponse.data);
    }
  } else {
    throw MessageException(Constants.genericErrorMessage);
  }
}

Future<Map<String, dynamic>> _generateParameterMap({final String action = "", final bool authentication = false, final Map<String, dynamic> additional = const {}}) async {
  final Map<String, dynamic> parameterMap = {};

  if(action.isNotEmpty) {
    parameterMap[_actionIdentifier] = action;
  }

  if(authentication) {
    String? country = await prefs.getCountry();
    int? hospital = await prefs.getHospital();
    String? role = await prefs.getRole();
    int? user = await prefs.getUser();
    String? password = await prefs.getPassword();

    parameterMap[_countryIdentifier] = country;
    parameterMap[_hospitalIdentifier] = hospital;
    parameterMap[_roleIdentifier] = role;
    parameterMap[_userIdentifier] = user;
    parameterMap[_passwordIdentifier] = password;
  }

  additional.forEach((key, value) {
    parameterMap[key] = value;
  });

  return parameterMap;
}
  