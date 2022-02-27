import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';
import 'package:teog_swift/utilities/hospitalDevice.dart';

import 'package:teog_swift/utilities/networkFunctions.dart' as Comm;
import 'package:teog_swift/utilities/organizationalRelation.dart';
import 'package:teog_swift/utilities/organizationalUnit.dart';
import 'package:teog_swift/utilities/messageException.dart';
import 'package:teog_swift/utilities/previewDeviceInfo.dart';
import 'package:teog_swift/utilities/constants.dart';

class OrganizationScreen extends StatefulWidget {
  OrganizationScreen({Key key}) : super(key: key);

  @override
  _OrganizationScreenState createState() => _OrganizationScreenState();
}

class _OrganizationScreenState extends State<OrganizationScreen> {
  Graph _graph = Graph();
  Map<int, String> _nameMap = Map();
  bool _edited = false;

  int _selectedDepartment = 1;
  List<PreviewDeviceInfo> _devices = [];
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    Comm.searchDevices(null, null, _selectedDepartment).then((devices) {
      setState(() {
        _devices = devices;
      });
    });

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
      final snackBar = SnackBar(content: Text("cannot set a department as its own child"));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  void _addUnit(int parent) {
    //TODO: should those be disposed?
    TextEditingController nameController = TextEditingController();

    showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return new AlertDialog(
          title: Text("Add child department to \"" + _nameMap[parent] + "\""),
          contentPadding: const EdgeInsets.all(16.0),
          content: new Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: nameController,
                decoration: new InputDecoration(
                  labelText: 'Name of child department'),
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
                      if(node.key.value > maxId) {
                        maxId = node.key.value;
                      }
                    }

                    int newId = maxId+1;

                    Node node = Node.Id(newId);

                    //TODO: magic
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

  void _editUnit(int id) {
    TextEditingController nameChanger = TextEditingController(text: _nameMap[id]);
    
    showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return new AlertDialog(
            title: Text("Change name of \"" + _nameMap[id] + "\""),
            contentPadding: const EdgeInsets.all(16.0),
            content: new Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: nameChanger,
                  decoration: new InputDecoration(
                      labelText: 'New name of department'),
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

  void _removeUnit(int id) {
    showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return new AlertDialog(
          title: Text("Delete department \"" + _nameMap[id] + "\"?"),
          content: Text("This will also delete all child departments.", style: TextStyle(color: Colors.red)),
          actions: <Widget>[
            ElevatedButton(
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.pop(context);
                }),
            ElevatedButton(
                child: const Text('Delete'),
                onPressed: () {
                  Node node = _graph.getNodeUsingId(id);
                  List<Node> successors = _graph.successorsOf(node);

                  setState(() {
                    _graph.removeNodes(successors);
                    _graph.removeNode(node);
                    _nameMap.remove(id);
                    _edited = true;
                  });

                  Navigator.pop(context);
                })
          ],
        );
      }
    );
  }

  void _reset() {
    Comm.getOrganizationalInfo().then((orgInfo) {
      Graph graph = Graph();

      Map<int, String> nameMap = Map();

      for(OrganizationalUnit orgUnit in orgInfo.units) {
        Node node = Node.Id(orgUnit.id);
        graph.addNode(node);

        nameMap[orgUnit.id] = orgUnit.name;
      }

      for(OrganizationalRelation orgRelation in orgInfo.relations) {
          graph.addEdge(graph.getNodeUsingId(orgRelation.parent), graph.getNodeUsingId(orgRelation.id));
      }

      setState(() {
        _graph = graph;
        _nameMap = nameMap;
        _edited = false;
      });
    }).onError<MessageException>((error, stackTrace) {
        final snackBar = SnackBar(content: Text(error.message));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
    });
  }

  void _save() {
    List<OrganizationalUnit> orgUnits = [];
    List<OrganizationalRelation> orgRelations = [];

    for(var node in _graph.nodes) {
      int id = node.key.value;

      orgUnits.add(OrganizationalUnit(id: id, name: _nameMap[id]));
    }

    for(var edge in _graph.edges) {
      int parent = edge.source.key.value;
      int id = edge.destination.key.value;

      orgRelations.add(OrganizationalRelation(id: id, parent: parent));
    }

    Comm.updateOrganizationalInfo(orgUnits, orgRelations).then((success) {
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

  void _updateAssignedDevices(int orgUnitId) {
    setState(() {
      _selectedDepartment = orgUnitId;
    });
  }

  @override
  Widget build(BuildContext context) {
    BuchheimWalkerConfiguration builder = BuchheimWalkerConfiguration();

    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Container(alignment: Alignment.center,
        child: FractionallySizedBox(widthFactor: 0.9, heightFactor: 0.9,
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(25.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: _graph.nodeCount() > 0 ? SingleChildScrollView(
                      child: Column(
                        children: [
                          ButtonBar(
                            alignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(child: Text("Save"), onPressed: !_edited ? null : () => _save()),
                              ElevatedButton(child: Text("Reset"), onPressed: !_edited ? null : () => _reset())
                            ],
                          ),
                          SizedBox(height: 15),
                          GraphView(
                            graph: _graph,
                            algorithm: BuchheimWalkerAlgorithm(builder, TreeEdgeRenderer(builder)),
                            builder: (Node node) {
                              int id = node.key.value;

                              return Draggable<Node>(
                                data: node,
                                feedback: Card(color: Colors.grey[100], child: Padding(padding: EdgeInsets.all(15), child: Text(_nameMap[id], style: TextStyle(fontSize: 15, color: Colors.black, fontWeight: FontWeight.bold)))),
                                child: DragTarget<Node>(
                                  builder: (context, candidateItems, rejectedItems) {
                                    return Card(
                                      shape: id != _selectedDepartment ? RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4.0),
                                      ) : RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4.0),
                                        side: new BorderSide(color: Color(Constants.teog_blue))
                                      ),
                                      color: candidateItems.isNotEmpty ? Colors.grey[300] : Colors.grey[100],
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          TextButton(child: Text(_nameMap[id], style: TextStyle(fontSize: 15, color: Colors.black, fontWeight: FontWeight.bold)), onPressed: () => _updateAssignedDevices(id)),
                                          ButtonBar(
                                            mainAxisSize: MainAxisSize.min,
                                            buttonPadding: EdgeInsets.zero,
                                            children: [
                                              id != 1 ? TextButton(child: Icon(Icons.delete), onPressed: () => _removeUnit(node.key.value)) : null,
                                              id != 1 ? TextButton(child: Icon(Icons.edit), onPressed: ()=> _editUnit(node.key.value)) : null,
                                              TextButton(child: Icon(Icons.add), onPressed: () => _addUnit(node.key.value))
                                          ],)
                                        ]
                                      )
                                    );
                                  },
                                  onWillAccept: (item) {
                                    return item is Node;
                                  },
                                  onAccept: (item) {
                                    if(item.key.value != 1 && item.key.value != node.key.value) {
                                      _reOrganizeUnit(item.key.value, node.key.value);
                                    }
                                  },
                                )
                              );
                            }
                          ),
                          SizedBox(height: 10)
                        ]
                      )
                    ) : Center(child: Text("loading departments...")),
                  ),
                  VerticalDivider(),
                  Expanded(
                    child: Column(
                      children: [
                        ElevatedButton(onPressed: () => _updateAssignedDevices(null), child: Text("Show unassigned devices")),
                        SizedBox(height: 10),
                        Text(_selectedDepartment != null ? _nameMap[_selectedDepartment] : "Unassigned devices", style: TextStyle(fontSize: 25)),
                        Flexible(
                          child: Scrollbar(
                            controller: _scrollController,
                            isAlwaysShown: true,
                            child: ListView.separated(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(3),
                              itemCount: _devices.length,
                              itemBuilder: (BuildContext context, int index) {
                                PreviewDeviceInfo deviceInfo = _devices[index];
                                HospitalDevice device = deviceInfo.device;

                                return Draggable<ListTile>(
                                  feedback: Card(
                                    color: Colors.grey[100],
                                    child: Padding(
                                      padding: EdgeInsets.all(10),
                                      child: Row(
                                        children: [
                                          deviceInfo.imageData.isNotEmpty ? SizedBox(width: 50, child: Image.memory(base64Decode(deviceInfo.imageData))) : Text(""),
                                          SizedBox(width: 5,),
                                          Text(device.type,style: TextStyle(fontSize: 15))
                                        ]
                                      )
                                    )
                                  ),
                                  child: ListTile(
                                    leading: deviceInfo.imageData.isNotEmpty ? Image.memory(base64Decode(deviceInfo.imageData)) : Text("no image"),
                                    title: Text(device.type),
                                    subtitle: Text(device.manufacturer + " " + device.model)
                                  )
                                );
                              },
                              separatorBuilder: (BuildContext context, int index) => const Divider(),
                            )
                          )
                        ),
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