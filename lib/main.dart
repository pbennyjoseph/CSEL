import 'package:CSEL/models/favorite.dart';
import 'package:CSEL/models/internet.dart';
import 'package:CSEL/screens/home.dart';
import 'package:CSEL/screens/login.dart';
import 'package:CSEL/screens/profile.dart';
import 'package:data_connection_checker/data_connection_checker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'const.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<FavoriteLinksModel>(
          create: (context) => FavoriteLinksModel(),
        ),
        StreamProvider<DataConnectionStatus>(
          create: (context) =>
              DataConnectivityService().connectivityStreamController.stream,
        ),
      ],
      child: MaterialApp(
          title: 'CSEL',
          theme: ThemeData(
            primaryColor: themeColor,
            cardTheme: CardTheme(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
                side: BorderSide(color: Colors.black),
              ),
              clipBehavior: Clip.hardEdge,
            ),
          ),
          initialRoute: '/',
          routes: {
            '/': (context) => LoginPage(),
            '/home': (context) => HomeScreen(
                  currentUserId: null,
                ),
            '/profile': (context) => UserProfile(),
          }),
    );
  }
}
