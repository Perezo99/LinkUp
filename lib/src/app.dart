import 'package:flutter/material.dart';
import 'package:linkup/src/pages/home.dart';

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      
      title: 'Link Up',
      theme: ThemeData(
        primaryColor: Colors.red[900],
      ),
      home: Home(),
      
    );
  }
}
