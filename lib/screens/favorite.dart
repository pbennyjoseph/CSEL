import 'package:CSEL/models/favorite.dart';
import 'package:CSEL/screens/showDoc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:data_connection_checker/data_connection_checker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FavoriteScreen extends StatefulWidget {
  FavoriteScreen({Key key, @required this.currentUserId}) : super(key: key);
  final String currentUserId;
  @override
  _FavoriteScreenState createState() =>
      _FavoriteScreenState(userId: currentUserId);
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  _FavoriteScreenState({@required this.userId});
  final String userId;
  bool isActiveTransaction = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Your Favorite Links'),
        actions: [
          Builder(
            builder: (context) {
              return IconButton(
                onPressed: () {
                  if (isActiveTransaction) return;
                  isActiveTransaction = true;
                  if (Provider.of<FavoriteLinksModel>(context, listen: false)
                      .syncOnline(userId)) {
                    Scaffold.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Successfully synced your favorites'),
                      ),
                    );
                  } else {
                    Scaffold.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to sync your favorites'),
                      ),
                    );
                  }
                  isActiveTransaction = false;
                },
                icon: Icon(Icons.sync),
              );
            },
          ),
        ],
      ),
      body: Provider.of<DataConnectionStatus>(context) ==
              DataConnectionStatus.disconnected
          ? Center(
              child: Text('No Internet'),
            )
          : _favoriteView(),
    );
  }

  Widget _favoriteView() {
    final Iterable<Card> tiles =
        Provider.of<FavoriteLinksModel>(context).favorite.map(
      (String x) {
        return Card(
          child: FutureBuilder(
            future:
                Firestore.instance.collection('CSEL_links').document(x).get(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return ListTile(
                  title: Text('Loading..'),
                );
              }
              return ListTile(
                title: Text(snapshot.data['title']),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ShowDocument(docId: x),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );

    final List<Widget> divided =
        ListTile.divideTiles(tiles: tiles, context: context).toList();
    return ListView(
      children: divided,
    );
  }
}
