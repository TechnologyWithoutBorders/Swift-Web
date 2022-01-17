import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';

import 'dart:html' as html;

import 'package:teog_swift/utilities/networkFunctions.dart' as Comm;
import 'package:teog_swift/utilities/organizationalRelation.dart';
import 'package:teog_swift/utilities/organizationalUnit.dart';
import 'package:teog_swift/utilities/user.dart';
import 'package:teog_swift/utilities/hospital.dart';
import 'package:teog_swift/utilities/messageException.dart';

class UserManagementScreen extends StatefulWidget {
  UserManagementScreen({Key key}) : super(key: key);

  @override
  _DetailScreenState createState() => _DetailScreenState();
}

class _DetailScreenState extends State<UserManagementScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameTextController = TextEditingController();
  final _mailTextController = TextEditingController();

  final _scrollController = ScrollController();

  Hospital _hospital;
  Graph _graph = Graph();
  Map<int, String> _nameMap = Map();
  List<User> _users = [];

  void _createUser() {
    if (_formKey.currentState.validate()) {
      String name = _nameTextController.text;
      String mail = _mailTextController.text;

      Comm.createUser(mail, name).then((users) {
        setState(() {
          _users = users;
        });
      });
    }
  }

  @override
  void initState() {
    super.initState();

    Comm.getHospitalInfo().then((hospital) {
      setState(() {
        _hospital = hospital;
      });
    }).onError<MessageException>((error, stackTrace) {
        final snackBar = SnackBar(content: Text(error.message));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
    });

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
      });
    }).onError<MessageException>((error, stackTrace) {
        final snackBar = SnackBar(content: Text(error.message));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
    });

    Comm.getUsers().then((users) {
      setState(() {
        _users = users;
      });
    }).onError<MessageException>((error, stackTrace) {
        final snackBar = SnackBar(content: Text(error.message));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
    });
  }

  void _deleteUser() {
    showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return new AlertDialog(
          title: Text("Are you sure you want to delete this user? (Does nothing at the moment)"),
          actions: <Widget>[
            ElevatedButton(
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.pop(context);
                }),
            ElevatedButton(
                child: const Text('Delete'),
                onPressed: () {
                  //TODO: implement

                  Navigator.pop(context);
                })
          ],
        );
      }
    );
  }

  void _reOrganizeUnit(int id, int parentId) {
    Node parent = _graph.getNodeUsingId(parentId);
    Node child = _graph.getNodeUsingId(id);

    List<Node> successors = _graph.successorsOf(child);

    if(!successors.contains(parent)) {
      setState(() {
        _graph.removeEdges(_graph.getInEdges(child));

        _graph.addEdge(parent, child);
      });
    } else {
      final snackBar = SnackBar(content: Text("cannot set a node as its own successor"));
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
          title: Text("Add child unit to \"" + _nameMap[parent] + "\""),
          contentPadding: const EdgeInsets.all(16.0),
          content: new Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: nameController,
                decoration: new InputDecoration(
                  labelText: 'Name of child unit'),
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
          title: Text("Delete unit \"" + _nameMap[id] + "\"?"),
          content: Text("This will also delete all child units.", style: TextStyle(color: Colors.red)),
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
                  });

                  Navigator.pop(context);
                })
          ],
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    BuchheimWalkerConfiguration builder = BuchheimWalkerConfiguration();

    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Container(alignment: Alignment.center,
        child: FractionallySizedBox(widthFactor: 0.9, heightFactor: 0.9,
          child: Card(
            child: Padding(padding: EdgeInsets.all(25.0),
              child: Row(mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 5,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: 10),
                        _hospital == null ? Text("") : Text(_hospital.name, style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
                        SizedBox(height: 5),
                        _hospital == null ? Text("") : Text(_hospital.location, style: TextStyle(fontSize: 20)),
                        _hospital == null ? Text("") : TextButton(onPressed: () => {
                            html.window.open('https://www.openstreetmap.org/?mlat=' + _hospital.latitude.toString() + '&mlon=' + _hospital.longitude.toString() + '#map=17/' + _hospital.latitude.toString() + '/' + _hospital.longitude.toString(), 'map')
                          }, child: Icon(Icons.map)),
                        _hospital == null ? Text("") : TextButton(onPressed: () => {
                            html.window.open('https://www.openstreetmap.org/?mlat=' + _hospital.latitude.toString() + '&mlon=' + _hospital.longitude.toString() + '#map=17/' + _hospital.latitude.toString() + '/' + _hospital.longitude.toString(), 'map')
                          }, child: Text("show on map")),
                        SizedBox(height: 15),
                        _graph.nodeCount() > 0 ? GraphView(
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
                                    color: candidateItems.isNotEmpty ? Colors.grey[300] : Colors.grey[100],
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        TextButton(child: Text(_nameMap[id], style: TextStyle(fontSize: 15, color: Colors.black, fontWeight: FontWeight.bold)), onPressed: () => {}),
                                        ButtonBar(
                                          mainAxisSize: MainAxisSize.min,
                                          buttonPadding: EdgeInsets.zero,
                                          children: [
                                            TextButton(child: Icon(Icons.add), onPressed: () => _addUnit(node.key.value)),
                                            id != 1 ? TextButton(child: Icon(Icons.delete), onPressed: () => _removeUnit(node.key.value)) : null
                                        ],)
                                      ]
                                    )
                                  );
                                },
                                onAccept: (item) {
                                  if(item.key.value != 1 && item.key.value != node.key.value) {
                                    _reOrganizeUnit(item.key.value, node.key.value);
                                  }
                                },
                              )
                            );
                          }
                          ) : Text("loading organizational units..."),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Manage Staff", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                        Flexible(
                          child: Scrollbar(isAlwaysShown: true,
                            controller: _scrollController,
                            child: ListView.separated(
                              controller: _scrollController,
                              itemCount: _users.length,
                              itemBuilder: (BuildContext context, int index) {
                                User user = _users[index];

                                return ListTile(
                                  title: SelectableText(user.name),
                                  subtitle: SelectableText(user.position + "\n" + user.mail + "\n" + user.phone),
                                  trailing: TextButton(child: Icon(Icons.delete), onPressed: () =>_deleteUser()),
                                  //trailing: Text(_users[index].position),
                                );
                              },
                              separatorBuilder: (BuildContext context, int index) => const Divider(),
                            ),
                          ),
                        ),
                        SizedBox(height: 15,),
                        Text('Register a new technician', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                        Form(key: _formKey,
                          child: Column(mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextFormField(
                                controller: _nameTextController,
                                decoration: InputDecoration(hintText: 'Name'),
                                validator: (value) {
                                  if (value.isEmpty) {
                                    return 'Please enter the name of the user';
                                  }
                                  return null;
                                },
                                onFieldSubmitted: (value) => _createUser(),
                              ),
                              TextFormField(
                                controller: _mailTextController,
                                decoration: InputDecoration(hintText: 'Mail Address'),
                                validator: (value) {
                                  if (value.isEmpty) {
                                    return 'Please enter the mail address of the user';
                                  }
                                  return null;
                                },
                                onFieldSubmitted: (value) => _createUser(),
                              ),
                              SizedBox(height: 10,),
                              ElevatedButton(
                                onPressed: () => _createUser(),
                                child: Text('Register user'),
                              )
                            ]
                          )
                        )
                      ]
                    )
                  ),
                ]
              )
            ),
          )     
        )
      )
    );
  }
}