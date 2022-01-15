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
  Comm.OrganizationalInfo _orgInfo;
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
        _orgInfo = orgInfo;
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
          contentPadding: const EdgeInsets.all(16.0),
          content: new Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text("Are you sure you want to delete this user? (Does nothing at the moment)"),
            ],
          ),
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

  void _refreshOrgUnits(int id, int parent) {
    Graph graph = Graph();

    List<OrganizationalUnit> orgUnits = List.from(_orgInfo.units);
    List<OrganizationalRelation> oldOrgRelations = List.from(_orgInfo.relations);
    List<OrganizationalRelation> orgRelations = [];

    // adjust graph
    for(OrganizationalRelation orgRelation in oldOrgRelations) {
      if(orgRelation.id != id) {
        orgRelations.add(orgRelation);
      }
    }

    orgRelations.add(new OrganizationalRelation(id: id, parent: parent));

    // redraw graph
    Map<int, String> nameMap = Map();

    for(OrganizationalUnit orgUnit in orgUnits) {
      Node node = Node.Id(orgUnit.id);
      graph.addNode(node);

      nameMap[orgUnit.id] = orgUnit.name;
    }

    for(OrganizationalRelation orgRelation in orgRelations) {
        graph.addEdge(graph.getNodeUsingId(orgRelation.parent), graph.getNodeUsingId(orgRelation.id));
    }

    //TODO: magic
    setState(() {
      _orgInfo = Comm.OrganizationalInfo(units: orgUnits, relations: orgRelations);
      _graph = graph;
      _nameMap = nameMap;
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
                              feedback: OutlinedButton(child: Text(_nameMap[id], style: TextStyle(fontSize: 15)), onPressed: () => {}),
                              child: DragTarget<Node>(
                                builder: (context, candidateItems, rejectedItems) {
                                  return OutlinedButton(child: Text(_nameMap[id], style: TextStyle(fontSize: 15, fontWeight: candidateItems.isNotEmpty ? FontWeight.bold : FontWeight.normal)), onPressed: () => {});
                                },
                                onAccept: (item) {
                                  if(item.key.value != 1 && item.key.value != node.key.value) {
                                    _refreshOrgUnits(item.key.value, node.key.value);
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