import 'package:douban/widght/seach_page.dart';
import 'package:flutter/material.dart';

import '../utils/constants_page.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: new SeachPage(seachTitle: Constancts.HOME_SEAACH_TITLE),
    );
  }
}
