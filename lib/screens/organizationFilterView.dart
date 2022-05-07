import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';

import 'package:teog_swift/utilities/networkFunctions.dart' as Comm;
import 'package:teog_swift/utilities/constants.dart';
import 'package:teog_swift/utilities/organizationalRelation.dart';
import 'package:teog_swift/utilities/organizationalUnit.dart';
import 'package:teog_swift/utilities/messageException.dart';

class OrganizationFilterView extends StatefulWidget {
  final OrganizationalUnit? orgUnit;

  OrganizationFilterView({Key? key, this.orgUnit}) : super(key: key);

  @override
  _OrganizationFilterViewState createState() => _OrganizationFilterViewState();
}

class _OrganizationFilterViewState extends State<OrganizationFilterView> {
  Graph _graph = Graph();
  Map<int, String> _nameMap = Map();

  final _orgScrollController = ScrollController();

  @override
  void initState() {
    super.initState();

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
  }

  List<Node> _getAllSuccessingNodes(List<Node> nodes) {
    List<Node> successors = [];

    for(var succ in nodes) {
      successors.addAll(_graph.successorsOf(succ));
      successors.addAll(_getAllSuccessingNodes(_graph.successorsOf(succ)));
    }

    return successors;
  }

  @override
  Widget build(BuildContext context) {
    BuchheimWalkerConfiguration builder = BuchheimWalkerConfiguration();

    return Dialog(alignment: Alignment.center,
      child: FractionallySizedBox(widthFactor: 0.9, heightFactor: 0.9,
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(25.0),
            child: _graph.nodeCount() > 0 ? Center(
              child: Scrollbar(
                controller: _orgScrollController,
                isAlwaysShown: true,
                child: SingleChildScrollView(
                  controller: _orgScrollController,
                  scrollDirection: Axis.horizontal,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GraphView(
                        graph: _graph,
                        algorithm: BuchheimWalkerAlgorithm(builder, TreeEdgeRenderer(builder)),
                        builder: (Node node) {
                          int id = node.key!.value;

                          return Card(
                            color: widget.orgUnit == null || widget.orgUnit!.id != id ? Colors.grey[100] : Color(Constants.teog_blue),
                            child: TextButton(
                              child: Text(_nameMap[id]!, style: TextStyle(fontSize: 15, color: widget.orgUnit == null || widget.orgUnit!.id != id ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
                              onPressed: () {
                                //return this unit and all child units
                                List<Node> successors = _getAllSuccessingNodes([node]);

                                List<int> orgUnitIds = [];

                                for(var node in successors) {
                                  orgUnitIds.add(node.key!.value);
                                }

                                Navigator.pop(context, DepartmentFilter(OrganizationalUnit(id: id, name: _nameMap[id]!), orgUnitIds));
                              }
                            ),
                          );
                        }
                      ),
                    ]
                  )
                )
              )
            ) : Center(child: Text("loading departments..."))
          )
        )
      )
    );
  }
}

class DepartmentFilter {
  final OrganizationalUnit parent;
  final List<int> successors;

  DepartmentFilter(this.parent, this.successors);
}