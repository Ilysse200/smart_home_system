import 'package:flutter/material.dart';

class BlankPage extends StatelessWidget {
  static const routeName = '/blankPage';

  const BlankPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blank'),
      ),
    );
  }
}