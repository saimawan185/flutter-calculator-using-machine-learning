import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:calculator/model/historyitem.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

class CalculatorProvider with ChangeNotifier {
  String equation = '';
  String result = '';

  final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  void getText(context, image) async {
    try {
      final RecognizedText recognizedText = await textRecognizer
          .processImage(InputImage.fromFile(File(image!.path)));

      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          addToEquation(
            ' + ',
            false,
            context,
          );
          var value = line.text.toString();
          value = value.replaceAll(RegExp('[oOØC]'), '0');
          value = value.replaceAll(RegExp('[sSś]'), '5');
          value = value.replaceAll(RegExp('[iIl(|!]'), '1');
          value = value.replaceAll('b', '6');
          value = value.replaceAll(RegExp('[&B]'), '8');
          value = value.replaceAll(' ', '');
          value = value.replaceAll('a', '2');
          log("Final Data: ${value}");
          addToEquation(
            value,
            true,
            context,
          );
        }
      }

      textRecognizer.close();
    } catch (e) {
      print('Error taking picture: $e');
    }
  }

  pickImage(context, source) async {
    final image = await ImagePicker()
        .pickImage(source: source, preferredCameraDevice: CameraDevice.rear);

    getText(context, image);
  }

  botttomSheett(context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          height: 120,
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              InkWell(
                splashColor: Colors.transparent,
                focusColor: Colors.transparent,
                hoverColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onTap: () async {
                  await Permission.camera.request();
                  Navigator.pop(context);
                  pickImage(context, ImageSource.camera);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Icon(Icons.camera_alt_outlined),
                    const SizedBox(
                      width: 8,
                    ),
                    Text("Camera")
                  ],
                ),
              ),
              SizedBox(
                height: 6,
              ),
              Divider(
                color: Colors.black54,
              ),
              SizedBox(
                height: 6,
              ),
              InkWell(
                splashColor: Colors.transparent,
                focusColor: Colors.transparent,
                hoverColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onTap: () async {
                  await Permission.mediaLibrary.request();
                  await Permission.photos.request();
                  Navigator.pop(context);
                  pickImage(context, ImageSource.gallery);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Icon(Icons.image),
                    const SizedBox(
                      width: 8,
                    ),
                    Text("Gallery")
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void addToEquation(String sign, bool canFirst, BuildContext context) {
    if (equation == '') {
      if (sign == '.') {
        equation = '0.';
      } else if (canFirst) {
        equation = sign;
      }
    } else {
      if (sign == "AC") {
        equation = '';
        result = '';
      } else if (sign == "⌫") {
        if (equation.endsWith(' ')) {
          equation = '${equation.substring(0, equation.length - 3)}';
        } else {
          equation = '${equation.substring(0, equation.length - 1)}';
        }
      } else if (equation.endsWith('.') && sign == '.') {
        return;
      } else if (equation.endsWith(' ') && sign == '.') {
        equation = equation + '0.';
      } else if (equation.endsWith(' ') && canFirst == false) {
        equation = '${equation.substring(0, equation.length - 3) + sign}';
      } else if (sign == '=') {
        final historyItem = HistoryItem()
          ..title = result
          ..subtitle = equation;
        Hive.box<HistoryItem>('history').add(historyItem);
        // showToast(context, 'Saved');
      } else {
        equation = equation + sign;
      }
    }
    if (equation == '0') {
      equation = '';
    }
    try {
      var privateResult = equation.replaceAll('÷', '/').replaceAll('×', '*');
      Parser p = Parser();
      Expression exp = p.parse(privateResult);
      ContextModel cm = ContextModel();
      result = '${exp.evaluate(EvaluationType.REAL, cm)}';
      if (result.endsWith('.0')) {
        result = result.substring(0, result.length - 2);
      }
    } catch (e) {
      result = '';
    }
    notifyListeners();
  }
}
