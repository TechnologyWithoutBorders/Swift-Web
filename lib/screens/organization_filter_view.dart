import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';

import 'package:teog_swift/utilities/network_functions.dart' as comm;
import 'package:teog_swift/utilities/constants.dart';
import 'package:teog_swift/utilities/organizational_relation.dart';
import 'package:teog_swift/utilities/organizational_unit.dart';
import 'package:teog_swift/utilities/message_exception.dart';

class OrganizationFilterView extends StatefulWidget {
  final OrganizationalUnit? orgUnit;

  const OrganizationFilterView({Key? key, this.orgUnit}) : super(key: key);

  @override
  State<OrganizationFilterView> createState() => _OrganizationFilterViewState();
}

class _OrganizationFilterViewState extends State<OrganizationFilterView> {
  Graph _graph = Graph();
  Map<int, String> _nameMap = {};

  @override
  void initState() {
    super.initState();

    comm.getOrganizationalInfo().then((orgInfo) {
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
            padding: const EdgeInsets.all(25.0),
            child: _graph.nodeCount() > 0 ? Center(
              child: InteractiveViewer(
                boundaryMargin: const EdgeInsets.all(10.0),
                constrained: false,
                minScale: 0.1,
                maxScale: 1.0,
                child: GraphView(
                  graph: _graph,
                  algorithm: BuchheimWalkerAlgorithm(builder, TreeEdgeRenderer(builder)),
                  builder: (Node node) {
                    int id = node.key!.value;

                    return Card(
                      color: widget.orgUnit == null || widget.orgUnit!.id != id ? Colors.grey[100] : const Color(Constants.teogBlue),
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
                )
              )
            ) : const Center(child: Text("loading departments..."))
          )
        )
      )
    );
  }
}

//TODO: to ensure consistency this should not include successors -> determine them on server side
class DepartmentFilter {
  final OrganizationalUnit parent;
  final List<int> successors;

  DepartmentFilter(this.parent, this.successors);
}