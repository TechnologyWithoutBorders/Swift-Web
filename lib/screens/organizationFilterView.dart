import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';

import 'package:teog_swift/utilities/networkFunctions.dart' as Comm;
import 'package:teog_swift/utilities/organizationalRelation.dart';
import 'package:teog_swift/utilities/organizationalUnit.dart';
import 'package:teog_swift/utilities/messageException.dart';

class OrganizationFilterView extends StatefulWidget {
  OrganizationFilterView({Key key}) : super(key: key);

  @override
  _OrganizationFilterViewState createState() => _OrganizationFilterViewState();
}

class _OrganizationFilterViewState extends State<OrganizationFilterView> {
  Graph _graph = Graph();
  Map<int, String> _nameMap = Map();

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

  @override
  Widget build(BuildContext context) {
    BuchheimWalkerConfiguration builder = BuchheimWalkerConfiguration();

    return Dialog(alignment: Alignment.center,
      child: FractionallySizedBox(widthFactor: 0.9, heightFactor: 0.9,
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(25.0),
            child: _graph.nodeCount() > 0 ? Center(
              child: GraphView(
                graph: _graph,
                algorithm: BuchheimWalkerAlgorithm(builder, TreeEdgeRenderer(builder)),
                builder: (Node node) {
                  int id = node.key.value;

                  return Card(
                    color: Colors.grey[100],
                    child: TextButton(
                      child: Text(_nameMap[id], style: TextStyle(fontSize: 15, color: Colors.black, fontWeight: FontWeight.bold)),
                      onPressed: () => {}
                    ),
                  );
                }
              ),
            ) : Center(child: Text("loading departments..."))
          )
        )
      )
    );
  }
}