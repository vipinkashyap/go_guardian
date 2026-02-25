import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_guardian/go_guardian.dart';

import 'src/router.dart';

void main() {
  if (kDebugMode) GoGuardian.observer = DebugGuardObserver();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'go_guardian demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
