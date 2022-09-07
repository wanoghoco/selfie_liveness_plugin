import 'package:flutter/material.dart';
import 'dart:io';

import 'package:selfie_liveness/selfie_liveness.dart';

void main() {
  runApp(const ElatechLiveliness());
}

class ElatechLiveliness extends StatelessWidget {
  const ElatechLiveliness({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: MyApp());
  }
}

class MyApp extends StatelessWidget {
  MyApp({Key? key}) : super(key: key);
  final listenable = ValueNotifier("");

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
        body: ValueListenableBuilder(
            valueListenable: listenable,
            builder: (context, value, child) {
              return SizedBox(
                height: size.height,
                width: size.width,
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      listenable.value != ""
                          ? Image.file(File(listenable.value))
                          : const SizedBox(),
                      Text(listenable.value),
                      ElevatedButton(
                          onPressed: () async {
                            listenable.value = await SelfieLiveness.detectLiveness(
                                msgselfieCapture:
                                    "Place your face inside the oval shaped panel",
                                msgBlinkEye: "Blink your eyes to capture");
                          },
                          child: const Text("Click Me"))
                    ]),
              );
            }));
  }
}
