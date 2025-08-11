import 'package:flutter/material.dart';
import 'routes.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CNC G-Code Monitor',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      onGenerateRoute: AppRoutes.generateRoute,
      initialRoute: '/',
      home: const Scaffold(
        body: Center(child: Text('Добро пожаловать в систему мониторинга ЧПУ')),
      ),
    );
  }
}