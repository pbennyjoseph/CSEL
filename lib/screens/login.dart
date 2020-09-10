import 'dart:async';

import 'package:CSEL/models/favorite.dart';
import 'package:CSEL/screens/home.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:data_connection_checker/data_connection_checker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  LoginPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  SharedPreferences prefs;

  bool isLoading = false;
  bool isLoggedIn = false;
  var listener;

  FirebaseUser currentUser;

  @override
  void initState() {
    super.initState();
    listener = DataConnectionChecker().onStatusChange.listen((status) {
      switch (status) {
        case DataConnectionStatus.connected:
          break;
        case DataConnectionStatus.disconnected:
          break;
      }
    });
    isSignedIn();
  }

  void dispose() {
    listener.cancel();
    super.dispose();
  }

  void isSignedIn() async {
    this.setState(() {
      isLoading = true;
    });

    prefs = await SharedPreferences.getInstance();
    isLoggedIn = await googleSignIn.isSignedIn();

    GoogleSignInAccount googleUser = await googleSignIn.signIn();

    if(googleUser == null){
      setState(() {
        isLoading = false;
      });
      return;
    }

    GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    final AuthCredential credential = GoogleAuthProvider.getCredential(
      idToken: googleAuth.idToken,
      accessToken: googleAuth.accessToken,
    );

    if (isLoggedIn) {
      FirebaseUser firebaseUser =
          (await firebaseAuth.signInWithCredential(credential)).user;
      final QuerySnapshot result = await Firestore.instance
          .collection('CSEL_users')
          .where('id', isEqualTo: firebaseUser.uid)
          .getDocuments();
      final List<DocumentSnapshot> documents = result.documents;
      Provider.of<FavoriteLinksModel>(context, listen: false)
          .favorite
          .addAll(List.from(documents[0]['favLinks']));
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(
            currentUserId: prefs.getString('id'),
            userName: prefs.getString('name'),
            photoUrl: prefs.getString('photoUrl'),
            isAdmin: prefs.getBool('isAdmin'),
          ),
        ),
      );
    }

    this.setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign in to CSEL'),
      ),
      body: _googleSignInButton(),
    );
  }

  Future<Null> handleSignIn() async {
    prefs = await SharedPreferences.getInstance();
    this.setState(() {
      isLoading = true;
    });

    GoogleSignInAccount googleUser = await googleSignIn.signIn();

    if(googleUser == null){
      setState(() {
        isLoading = false;
      });
      return;
    }

    GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    final AuthCredential credential = GoogleAuthProvider.getCredential(
      idToken: googleAuth.idToken,
      accessToken: googleAuth.accessToken,
    );

    FirebaseUser firebaseUser =
        (await firebaseAuth.signInWithCredential(credential)).user;

    if (firebaseUser != null) {
      final QuerySnapshot result = await Firestore.instance
          .collection('CSEL_users')
          .where('id', isEqualTo: firebaseUser.uid)
          .getDocuments();
      final List<DocumentSnapshot> documents = result.documents;
      if (documents.length == 0) {
        Firestore.instance
            .collection('CSEL_users')
            .document(firebaseUser.uid)
            .setData({
          'name': firebaseUser.displayName,
          'photoUrl': firebaseUser.photoUrl,
          'id': firebaseUser.uid,
          'createdAt': DateTime.now().millisecondsSinceEpoch.toString(),
          'aboutMe': "",
          'admin': false,
          'favLinks': null,
        });
        currentUser = firebaseUser;
        await prefs.setString('id', firebaseUser.uid);
        await prefs.setString('name', firebaseUser.displayName);
        await prefs.setString('photoUrl', firebaseUser.photoUrl);
        await prefs.setBool('isAdmin', false);
      } else {
        Provider.of<FavoriteLinksModel>(context, listen: false)
            .favorite
            .addAll(List.from(documents[0]['favLinks']));
        await prefs.setString('id', documents[0]['id']);
        await prefs.setString('name', documents[0]['name']);
        await prefs.setString('photoUrl', documents[0]['photoUrl']);
        await prefs.setString('aboutMe', documents[0]['aboutMe']);
        await prefs.setBool('isAdmin', documents[0]['admin']);
      }
      Fluttertoast.showToast(msg: "Sign in Success");
      this.setState(() {
        isLoading = false;
      });
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(
            currentUserId: firebaseUser.uid,
            userName: firebaseUser.displayName,
            photoUrl: firebaseUser.photoUrl,
            isAdmin: prefs.getBool('isAdmin'),
          ),
        ),
      );
    } else {
      Fluttertoast.showToast(msg: "Sign in Failed");
      this.setState(() {
        isLoading = false;
      });
    }
  }

  Widget _googleSignInButton() {
    return Center(
      child: Provider.of<DataConnectionStatus>(context) ==
              DataConnectionStatus.disconnected
          ? Text('No Internet')
          : RaisedButton(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(32.0),
              ),
              padding: EdgeInsets.all(8.0),
              color: Colors.white,
              onPressed: handleSignIn,
              // onPressed: () {
              //   if (isLoading) return;
              //   setState(() {
              //     isLoading = true;
              //   });
              //   Future.delayed(const Duration(milliseconds: 2000), () {
              //     setState(() {
              //       isLoading = false;
              //     });
              //     Navigator.push(
              //       context,
              //       MaterialPageRoute(
              //         builder: (context) => HomeScreen(
              //           currentUserId: prefs.getString('id'),
              //           userName: prefs.getString('name'),
              //           photoUrl: prefs.getString('photoUrl'),
              //         ),
              //       ),
              //     );
              //   });
              // },
              child: AnimatedSize(
                duration: Duration(milliseconds: 250),
                vsync: this,
                curve: Curves.linear,
                child: isLoading
                    ? SizedBox(
                        height: 24.0,
                        width: 24.0,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2.0,
                        ),
                      )
                    : _signInRow(),
              ),
            ),
    );
  }

  Widget _signInRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ClipOval(
          child: Image.asset(
            'images/google_icon.png',
            width: 24.0,
          ),
        ),
        SizedBox(
          width: 8.0,
        ),
        Text(
          'Sign in with Google',
        ),
      ],
    );
  }
}
