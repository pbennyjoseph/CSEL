import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class ShowDocument extends StatefulWidget {
  ShowDocument({Key key, @required this.docId}) : super(key: key);
  final String docId;
  @override
  _ShowDocumentState createState() => _ShowDocumentState(docId: docId);
}

class _ShowDocumentState extends State<ShowDocument> {
  _ShowDocumentState({@required this.docId});
  final String docId;
  bool isLoading = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('View Link Details'),
      ),
      body: StreamBuilder(
          stream: Firestore.instance
              .collection('CSEL_links')
              .document(docId)
              .snapshots(),
          builder: (context, snapshot) {
            return _buildBody(context, snapshot);
          }),
    );
  }

  Widget _buildBody(BuildContext context, AsyncSnapshot snapshot) {
    if (snapshot.hasData) {
      return _buildDoc(context, snapshot);
    } else {
      return CircularProgressIndicator(
        strokeWidth: 2.0,
      );
    }
  }

  Widget _buildDoc(BuildContext context, AsyncSnapshot snapshot) {
    if (snapshot.hasError) {
      return Text('An Error Occured');
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          Card(
            child: ListTile(
              title: Text(snapshot.data['title']),
            ),
          ),
          Card(
            child: ListTile(
              title: Text(
                'URL (long press to copy)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onLongPress: () {
                Clipboard.setData(
                  ClipboardData(text: snapshot.data['url']),
                );
                Scaffold.of(context).showSnackBar(
                  SnackBar(
                    content: Text('URL copied to clipboard'),
                  ),
                );
              },
              trailing: IconButton(
                onPressed: () {
                  Firestore.instance
                      .collection('CSEL_links')
                      .document(docId)
                      .updateData({
                    'clicks': FieldValue.increment(1),
                  });
                  _launchURL(snapshot.data['url']);
                },
                icon: Icon(Icons.exit_to_app),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('Liked by ' +
                    snapshot.data['votes'].toString() +
                    ' user(s)'),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('Clicks: ' + snapshot.data['clicks'].toString()),
              ),
            ),
          ),
        ],
      );
    }
  }

  Future<Null> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    }
  }
}
