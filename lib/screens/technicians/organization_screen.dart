import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';
import 'package:teog_swift/utilities/hospital_device.dart';

import 'package:teog_swift/utilities/network_functions.dart' as comm;
import 'package:teog_swift/utilities/organizational_relation.dart';
import 'package:teog_swift/utilities/organizational_unit.dart';
import 'package:teog_swift/utilities/message_exception.dart';
import 'package:teog_swift/utilities/preview_device_info.dart';
import 'package:teog_swift/utilities/constants.dart';
import 'package:teog_swift/utilities/user.dart';
import 'package:teog_swift/screens/technicians/technician_device_screen.dart';

class OrganizationScreen extends StatefulWidget {
  final User user;

  const OrganizationScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<OrganizationScreen> createState() => _OrganizationScreenState();
}

class _OrganizationScreenState extends State<OrganizationScreen> {
  Graph _graph = Graph();
  Map<int, String> _nameMap = {};
  bool _edited = false;

  int? _selectedDepartment;
  Map<int?, List<PreviewDeviceInfo>> _deviceRelations = {};
  List<PreviewDeviceInfo> _displayedDevices = [];
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    _reset();
  }

  void _reOrganizeUnit(int id, int parentId) {
    Node parent = _graph.getNodeUsingId(parentId);
    Node child = _graph.getNodeUsingId(id);

    List<Node> successors = _graph.successorsOf(child);

    if(!successors.contains(parent)) {
      setState(() {
        _graph.removeEdges(_graph.getInEdges(child));
        _graph.addEdge(parent, child);
        _edited = true;
      });
    } else {
      const snackBar = SnackBar(content: Text("cannot set a department as its own child"));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  void _assignDevice(PreviewDeviceInfo deviceInfo, int orgUnitId) {
    setState(() {
      if(_deviceRelations.containsKey(deviceInfo.device.orgUnitId)) {
        _deviceRelations[deviceInfo.device.orgUnitId]!.remove(deviceInfo);
      }

      if(_deviceRelations.containsKey(orgUnitId)) {
        _deviceRelations[orgUnitId]!.add(deviceInfo);
      } else {
        _deviceRelations[orgUnitId] = [deviceInfo];
      }

      deviceInfo.device.orgUnitId = orgUnitId;
      deviceInfo.device.orgUnit = _nameMap[orgUnitId];

      _edited = true;

      _updateAssignedDevices(_selectedDepartment);
    });
  }

  void _addUnit(int parent) {
    TextEditingController nameController = TextEditingController();

    showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
          title: Text("Add child department to \"${_nameMap[parent]}\""),
          contentPadding: const EdgeInsets.all(16.0),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name of child department'),
                maxLength: 25,
                autofocus: true,
              ),
            ],
          ),
          actions: <Widget>[
            ElevatedButton(
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.pop(context);
                }),
            ElevatedButton(
                child: const Text('Create'),
                onPressed: () {
                  if(nameController.text.isNotEmpty) {
                    int maxId = 1;

                    for(Node node in _graph.nodes) {
                      if(node.key!.value > maxId) {
                        maxId = node.key!.value;
                      }
                    }

                    int newId = maxId+1;

                    Node node = Node.Id(newId);

                    setState(() {
                      _graph.addNode(node);
                      _graph.addEdge(_graph.getNodeUsingId(parent), node);
                      _nameMap[newId] = nameController.text;
                      _edited = true;
                    });

                    Navigator.pop(context);
                  }
                })
          ],
        );
      }
    );
  }

  void _renameUnit(int id) {
    TextEditingController nameChanger = TextEditingController(text: _nameMap[id]);
    
    showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Change name of \"${_nameMap[id]}\""),
            contentPadding: const EdgeInsets.all(16.0),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: nameChanger,
                  decoration: const InputDecoration(
                      labelText: 'New name of department'),
                  maxLength: 25,
                  autofocus: true,
                ),
              ],
            ),
            actions: <Widget>[
              ElevatedButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.pop(context);
                  }),
              ElevatedButton(
                  child: const Text('Change'),
                  onPressed: () {
                    if(nameChanger.text.isNotEmpty) {
                      setState(() {
                        _nameMap[id] = nameChanger.text;
                        _edited = true;
                      });

                      Navigator.pop(context);
                    }
                  })
            ],
          );
        }
    );
  }

  void _recursiveDeleteSuccessors(List<Node> successors) {
    for(var succ in successors) {
      int removedUnitId = succ.key!.value;

      if(_deviceRelations.containsKey(removedUnitId)) {
        //put removed devices to unassigned devices
        _deviceRelations[null]!.addAll(_deviceRelations.remove(removedUnitId)!);
      }

      _recursiveDeleteSuccessors(_graph.successorsOf(succ));
    }

    _graph.removeNodes(successors);
  }

  void _removeUnit(int id) {
    showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Delete department \"${_nameMap[id]}\"?"),
          content: const Text("This will also delete all child departments.", style: TextStyle(color: Colors.red)),
          actions: <Widget>[
            ElevatedButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.pop(context);
              }
            ),
            ElevatedButton(
              child: const Text('Delete'),
              onPressed: () {
                Node node = _graph.getNodeUsingId(id);
                List<Node> successors = _graph.successorsOf(node);

                setState(() {
                  _recursiveDeleteSuccessors(successors);

                  _graph.removeNode(node);
                  _nameMap.remove(id);

                  if(_deviceRelations.containsKey(id)) {
                    //put removed devices to unassigned devices
                    _deviceRelations[null]!.addAll(_deviceRelations.remove(id)!);
                  }
                  
                  _edited = true;
                });

                Navigator.pop(context);
              }
            )
          ],
        );
      }
    );
  }

  Future<void> _reset() async {
    OrganizationalInfo orgInfo = await comm.getOrganizationalInfo();
    Graph graph = Graph();

    Map<int, String> nameMap = {};

    for(OrganizationalUnit orgUnit in orgInfo.units) {
      Node node = Node.Id(orgUnit.id);
      graph.addNode(node);

      nameMap[orgUnit.id] = orgUnit.name;
    }

    for(OrganizationalRelation orgRelation in orgInfo.relations) {
        graph.addEdge(graph.getNodeUsingId(orgRelation.parent), graph.getNodeUsingId(orgRelation.id));
    }

    List<PreviewDeviceInfo> devices = await comm.searchDevices(null, null);

    Map<int?, List<PreviewDeviceInfo>> deviceRelations = {};
    //always add a list for unassigned devices
    deviceRelations[null] = [];

    for(PreviewDeviceInfo deviceInfo in devices) {
      HospitalDevice device = deviceInfo.device;

      if(deviceRelations.containsKey(device.orgUnitId)) {
        deviceRelations[device.orgUnitId]!.add(deviceInfo);
      } else {
        deviceRelations[device.orgUnitId] = [deviceInfo];
      }
    }

    setState(() {
      _graph = graph;
      _nameMap = nameMap;
      _edited = false;
      _deviceRelations = deviceRelations;
    });

    _updateAssignedDevices(null);
  }

  void _save() {
    List<OrganizationalUnit> orgUnits = [];
    List<OrganizationalRelation> orgRelations = [];

    for(var node in _graph.nodes) {
      int id = node.key!.value;

      orgUnits.add(OrganizationalUnit(id: id, name: _nameMap[id]!));
    }

    for(var edge in _graph.edges) {
      int parent = edge.source.key!.value;
      int id = edge.destination.key!.value;

      orgRelations.add(OrganizationalRelation(id: id, parent: parent));
    }

    List<DeviceRelation> deviceRelations = [];

    for(var entry in _deviceRelations.entries) {
      for(var deviceInfo in entry.value) {
        deviceRelations.add(DeviceRelation(deviceId: deviceInfo.device.id, orgUnitId: entry.key));
      }
    }

    comm.updateOrganizationalInfo(orgUnits, orgRelations, deviceRelations).then((success) {
      if(success) {
        setState(() {
          _edited = false;
        });
      }
    }).onError<MessageException>((error, stackTrace) {
        final snackBar = SnackBar(content: Text(error.message));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
    });
  }

  List<PreviewDeviceInfo> _getAllSuccessingDevices(List<Node> successors) {
    List<PreviewDeviceInfo> devices = [];

    for(var succ in successors) {
        if(_deviceRelations.containsKey(succ.key!.value)) {
          devices.addAll(_deviceRelations[succ.key!.value]!);
        }

        devices.addAll(_getAllSuccessingDevices(_graph.successorsOf(succ)));
      }

    return devices;
  }

  void _updateAssignedDevices(int? orgUnitId) {
    setState(() {
      _displayedDevices.clear();
    });

    List<PreviewDeviceInfo> displayedDevices = [];

    if(_deviceRelations.containsKey(orgUnitId)) {
      displayedDevices.addAll(_deviceRelations[orgUnitId]!);
    }

    if(orgUnitId != null) {
      displayedDevices.addAll(_getAllSuccessingDevices(_graph.successorsOf(_graph.getNodeUsingId(orgUnitId))));
    }

    setState(() {
      _displayedDevices = displayedDevices;
      _selectedDepartment = orgUnitId;
    });
  }

  @override
  Widget build(BuildContext context) {
    BuchheimWalkerConfiguration builder = BuchheimWalkerConfiguration();
    builder.orientation = BuchheimWalkerConfiguration.ORIENTATION_LEFT_RIGHT;
    builder.levelSeparation = 40;
    builder.subtreeSeparation = 25;
    builder.siblingSeparation = 5;

    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Container(alignment: Alignment.center,
        child: FractionallySizedBox(widthFactor: 0.95, heightFactor: 0.9,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(25.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _graph.nodeCount() > 0 ? Column(
                      children: [
                        ButtonBar(
                          alignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(onPressed: !_edited ? null : () => _save(), child: const Text("Save")),
                            ElevatedButton(onPressed: !_edited ? null : () => _reset(), child: const Text("Reset"))
                          ],
                        ),
                        Expanded(
                          child: InteractiveViewer(
                            boundaryMargin: const EdgeInsets.all(double.infinity),
                            constrained: false,
                            minScale: 0.3,
                            maxScale: 1.0,
                            child: GraphView(
                              graph: _graph,
                              algorithm: BuchheimWalkerAlgorithm(builder, TreeEdgeRenderer(builder)),
                              builder: (Node node) {
                                int id = node.key!.value;

                                return Draggable<Node>(
                                  data: node,
                                  feedback: Card(color: Colors.grey[100], child: Padding(padding: const EdgeInsets.all(15), child: Text(_nameMap[id]!, style: const TextStyle(fontSize: 15, color: Colors.black, fontWeight: FontWeight.bold)))),
                                  child: DragTarget<Object>(
                                    builder: (context, candidateItems, rejectedItems) {
                                      return Card(
                                        shape: id != _selectedDepartment ? RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(4.0),
                                        ) : RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(4.0),
                                          side: const BorderSide(color: Color(Constants.teogBlue))
                                        ),
                                        color: candidateItems.isNotEmpty ? Colors.grey[300] : Colors.grey[100],
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            TextButton(child: Text(_nameMap[id]!, style: const TextStyle(fontSize: 15, color: Colors.black, fontWeight: FontWeight.bold)), onPressed: () => _updateAssignedDevices(id)),
                                            ButtonBar(
                                              mainAxisSize: MainAxisSize.min,
                                              buttonPadding: EdgeInsets.zero,
                                              children: [
                                                id != 1 ? TextButton(child: const Icon(Icons.delete, color: Colors.red), onPressed: () => _removeUnit(node.key!.value)) : Container(),
                                                id != 1 ? TextButton(child: const Icon(Icons.edit), onPressed: ()=> _renameUnit(node.key!.value)) : Container(),
                                                TextButton(child: const Icon(Icons.add), onPressed: () => _addUnit(node.key!.value))
                                            ],)
                                          ]
                                        )
                                      );
                                    },
                                    onWillAcceptWithDetails: (item) {
                                      if(item.data is Node) {
                                        return !((item.data as Node).key!.value == 1 || (item.data as Node).key!.value == id);
                                      } else if(item.data is PreviewDeviceInfo) {
                                        return true;
                                      } else {
                                        return false;
                                      }
                                    },
                                    onAcceptWithDetails: (item) {
                                      if(item.data is Node) {
                                        _reOrganizeUnit((item.data as Node).key!.value, id);
                                      } else if(item.data is PreviewDeviceInfo) {
                                        _assignDevice((item.data as PreviewDeviceInfo), id);
                                      }
                                    },
                                  )
                                );
                              }
                            )
                          )
                        )
                      ]
                    ) : const Center(child: SizedBox(width: 60, height: 60, child: CircularProgressIndicator())),
                  ),
                  const VerticalDivider(),
                  Expanded(
                    child: Column(
                      children: [
                        _selectedDepartment != null ? ElevatedButton(onPressed: () => _updateAssignedDevices(null), child: const Text("Show unassigned devices")) : const SizedBox(height: 0),
                        const SizedBox(height: 10),
                        Text(_selectedDepartment != null && _nameMap[_selectedDepartment] != null ? _nameMap[_selectedDepartment]! : "Unassigned devices", style: const TextStyle(fontSize: 25)),
                        Flexible(
                          child: Scrollbar(
                            controller: _scrollController,
                            child: ListView.separated(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(3),
                              itemCount: _displayedDevices.length,
                              itemBuilder: (BuildContext context, int index) {
                                PreviewDeviceInfo deviceInfo = _displayedDevices[index];
                                HospitalDevice device = deviceInfo.device;
                                String? imageData = deviceInfo.imageData;

                                return Draggable<PreviewDeviceInfo>(
                                  data: deviceInfo,
                                  feedback: Card(
                                    color: Colors.grey[100],
                                    child: Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Row(
                                        children: [
                                          imageData != null && imageData.isNotEmpty ? SizedBox(width: 50, child: Image.memory(base64Decode(imageData))) : const Text(""),
                                          const SizedBox(width: 5,),
                                          Text(device.type,style: const TextStyle(fontSize: 15))
                                        ]
                                      )
                                    )
                                  ),
                                  child: ListTile(
                                    leading: imageData != null && imageData.isNotEmpty ? Image.memory(base64Decode(imageData)) : const Text("no image"),
                                    title: Text(device.type),
                                    subtitle: Text("${device.manufacturer} ${device.model}"),
                                    trailing: device.orgUnit != null ? Text(device.orgUnit!) : const Text(""),
                                    onTap: () => {
                                      showDialog<void>(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return Dialog(alignment: Alignment.center,
                                            child: FractionallySizedBox(widthFactor: 0.7, heightFactor: 0.85,
                                              child: Padding(
                                                padding: const EdgeInsets.all(25.0),
                                                child: TechnicianDeviceScreen(user: widget.user, deviceId: deviceInfo.device.id)
                                              )
                                            )
                                          );
                                        }
                                      )
                                    }
                                  )
                                );
                              },
                              separatorBuilder: (BuildContext context, int index) => const Divider(),
                            )
                          )
                        ),
                        const SizedBox(height: 15),
                        const Padding(padding: EdgeInsets.symmetric(horizontal: 15), child: Text("Drag and drop the devices onto the departments in order to assign them."))
                      ]
                    )
                  ),
                ]
              )
            )
          )
        )
      )
    );
  }
}