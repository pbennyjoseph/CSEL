import 'dart:io';

import 'package:CSEL/const.dart';
import 'package:CSEL/main.dart';
import 'package:CSEL/models/favorite.dart';
import 'package:CSEL/screens/favorite.dart';
import 'package:CSEL/screens/post.dart';
import 'package:CSEL/screens/profile.dart';
import 'package:CSEL/screens/showDoc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:data_connection_checker/data_connection_checker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({
    Key key,
    @required this.currentUserId,
    this.userName,
    this.photoUrl,
    this.isAdmin,
  }) : super(key: key);
  final String currentUserId;
  final bool isAdmin;
  final String userName;
  final String photoUrl;

  @override
  _HomeScreenState createState() => _HomeScreenState(
      currentUserId: currentUserId,
      userName: userName,
      photoUrl: photoUrl,
      isAdmin: isAdmin ?? false);
}

class _HomeScreenState extends State<HomeScreen> {
  _HomeScreenState(
      {@required this.currentUserId,
      this.userName,
      this.photoUrl,
      this.isAdmin});

  final String userName;
  final bool isAdmin;
  final String photoUrl;
  final String currentUserId;
  final GoogleSignIn googleSignIn = GoogleSignIn();

  bool isLoading = false;
  List<Choice> choices = const <Choice>[
    const Choice(title: 'Log out', icon: Icons.exit_to_app),
  ];

  Set<String> favoritxed;
  FavoriteLinksModel _favoriteLinksModel;
  Stream<QuerySnapshot> linkStream;

  void initState() {
    super.initState();
    linkStream = Firestore.instance
        .collection('CSEL_links')
//        .orderBy('votes', descending: true)
        .snapshots();
  }


  Future<bool> onBackPress() {
    openDialog();
    return Future.value(false);
  }

  Future<Null> openDialog() async {
    switch (await showDialog(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            contentPadding:
                EdgeInsets.only(left: 0.0, right: 0.0, top: 0.0, bottom: 0.0),
            children: <Widget>[
              Container(
                color: themeColor,
                margin: EdgeInsets.all(0.0),
                padding: EdgeInsets.only(bottom: 10.0, top: 10.0),
                height: 100.0,
                child: Column(
                  children: <Widget>[
                    Container(
                      child: Icon(
                        Icons.exit_to_app,
                        size: 30.0,
                        color: Colors.white,
                      ),
                      margin: EdgeInsets.only(bottom: 10.0),
                    ),
                    Text(
                      'Exit app',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Are you sure to exit app?',
                      style: TextStyle(color: Colors.white70, fontSize: 14.0),
                    ),
                  ],
                ),
              ),
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, 0);
                },
                child: Row(
                  children: <Widget>[
                    Container(
                      child: Icon(
                        Icons.cancel,
                        color: primaryColor,
                      ),
                      margin: EdgeInsets.only(right: 10.0),
                    ),
                    Text(
                      'CANCEL',
                      style: TextStyle(
                          color: primaryColor, fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              ),
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, 1);
                },
                child: Row(
                  children: <Widget>[
                    Container(
                      child: Icon(
                        Icons.check_circle,
                        color: primaryColor,
                      ),
                      margin: EdgeInsets.only(right: 10.0),
                    ),
                    Text(
                      'YES',
                      style: TextStyle(
                          color: primaryColor, fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              ),
            ],
          );
        })) {
      case 0:
        break;
      case 1:
        exit(0);
        break;
    }
  }

  void onItemMenuPress(Choice choice) {
    if (choice.title == 'Log out') {
      handleSignOut();
    } else {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => UserProfile()));
    }
  }

  Future<Null> handleSignOut() async {
    this.setState(() {
      isLoading = true;
    });

    await FirebaseAuth.instance.signOut();
    await googleSignIn.disconnect();
    await googleSignIn.signOut();

    this.setState(() {
      isLoading = false;
    });

    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => MyApp()),
        (Route<dynamic> route) => false);
  }

  @override
  Widget build(BuildContext context) {
    _favoriteLinksModel = Provider.of<FavoriteLinksModel>(context);
    return Scaffold(
      drawer: _buildDrawer(),
      floatingActionButton: Builder(
        builder: (context) {
          return FloatingActionButton.extended(
            backgroundColor: Colors.amber[400],
            foregroundColor: Colors.black,
            splashColor: Colors.amber,
            clipBehavior: Clip.hardEdge,
            icon: Icon(Icons.add),
            label: Text('Add link'),
            onPressed: () {
              if (isAdmin) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => PostScreen(),
                  ),
                );
              } else
                Scaffold.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text('Seems like you don\'t have permission to post'),
                  ),
                );
            },
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      appBar: AppBar(
        title: Text(
          'All Links',
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: <Widget>[
          PopupMenuButton<Choice>(
            onSelected: onItemMenuPress,
            itemBuilder: (BuildContext context) {
              return choices.map((Choice choice) {
                return PopupMenuItem<Choice>(
                    value: choice,
                    child: Row(
                      children: <Widget>[
                        Icon(
                          choice.icon,
                          color: primaryColor,
                        ),
                        Container(
                          width: 10.0,
                        ),
                        Text(
                          choice.title,
                          style: TextStyle(color: primaryColor),
                        ),
                      ],
                    ));
              }).toList();
            },
          ),
        ],
      ),
      body: WillPopScope(
        child: Stack(
          children: <Widget>[
            // List
            Container(
              child: Provider.of<DataConnectionStatus>(context) ==
                      DataConnectionStatus.disconnected
                  ? Center(
                      child: Text('No Internet'),
                    )
                  : StreamBuilder(
                      stream: linkStream,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2.0,
                            ),
                          );
                        } else {
                          return ListView.builder(
                            padding: EdgeInsets.all(10.0),
                            itemBuilder: (context, index) => _buildItem(
                                context, snapshot.data.documents[index]),
                            itemCount: snapshot.data.documents.length,
                          );
                        }
                      },
                    ),
            ),

            // Loading
            Positioned(
              child: isLoading
                  ? Opacity(
                      opacity: 1.0,
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                        ),
                      ),
                    )
                  : Container(),
            )
          ],
        ),
        onWillPop: onBackPress,
      ),
    );
  }

  Widget _buildItem(BuildContext context, DocumentSnapshot documentSnapshot) {
    return Card(
      child: _myListTile(context, documentSnapshot),
    );
  }

  Widget _myListTile(BuildContext context, DocumentSnapshot documentSnapshot) {
    bool _isFavorite =
        _favoriteLinksModel.contains(documentSnapshot.documentID);
    return ListTile(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  ShowDocument(docId: documentSnapshot.documentID)),
        );
      },
      title: Text(documentSnapshot.data['title']),
      leading: Icon(Icons.attach_file),
      trailing: IconButton(
        onPressed: () {
          setState(() {
            if (_isFavorite) {
              Firestore.instance
                  .collection('CSEL_links')
                  .document(documentSnapshot.documentID)
                  .updateData({'votes': FieldValue.increment(-1)});
              // Firestore.instance
              //     .collection('users')
              //     .where('id', isEqualTo: currentUserId)
              //     .getDocuments();
              _favoriteLinksModel.remove(
                  documentSnapshot.documentID, currentUserId);
            } else {
              Firestore.instance
                  .collection('CSEL_links')
                  .document(documentSnapshot.documentID)
                  .updateData({'votes': FieldValue.increment(1)});
              _favoriteLinksModel.add(
                  documentSnapshot.documentID, currentUserId);
            }

            // Provider.of<FavoriteLinksModel>(context, listen: false)
            // .syncOnline(currentUserId);
          });
        },
        icon: _isFavorite
            ? Icon(
                Icons.favorite,
                color: Colors.red,
              )
            : Icon(Icons.favorite_border),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        children: <Widget>[
          DrawerHeader(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  minRadius: 16.0,
                  maxRadius: 32.0,
                  child: photoUrl == null
                      ? Icon(Icons.account_circle)
                      : ClipOval(
                          child: Image.network(photoUrl),
                        ),
                ),
                SizedBox(height: 8.0),
                Text(userName ?? 'Anonymous'),
              ],
            ),
          ),
          // ListTile(
          //   leading: Icon(
          //     Icons.account_circle,
          //     color: Colors.grey[800],
          //   ),
          //   title: Text('Profile'),
          //   onTap: () => print('clicked fav'),
          // ),
          ListTile(
            leading: Icon(
              Icons.favorite_border,
              color: Colors.red,
            ),
            title: Text('Favorites'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      FavoriteScreen(currentUserId: currentUserId),
                ),
              );
            },
          ),
          // ListTile(
          //   leading: Icon(
          //     Icons.people_outline,
          //     color: Colors.black,
          //   ),
          //   title: Text('Users'),
          //   onTap: () => print('clicked users'),
          // ),
        ],
      ),
    );
  }
}

class Choice {
  const Choice({this.title, this.icon});

  final String title;
  final IconData icon;
}
