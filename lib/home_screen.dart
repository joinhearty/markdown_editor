import 'package:flutter/material.dart';
import 'package:flutter_app/objects/bold_element.dart';
import 'package:flutter_app/objects/header_element.dart';
import 'package:flutter_app/objects/italic_element.dart';
import 'package:flutter_app/objects/ordered_list.dart';
import 'package:flutter_app/objects/unordered_list.dart';
import 'package:flutter_html/flutter_html.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final controller = TextEditingController();
  String html = '';

  @override
  void initState() {
    super.initState();
    controller.addListener(onTextChanged);
  }

  void onTextChanged() {
    final text = convertToHtml(controller.text);

    setState(() {
      html = text;
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: ColoredBox(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: <Widget>[
                SafeArea(
                  child: TextField(
                    controller: controller,
                    maxLines: 5,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(border: Border.all()),
                    child: SingleChildScrollView(
                      child: Html(data: html),
                    ),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String convertToHtml(String input) {
  var text = input.trim();

  const elements = [
    BoldElement(),
    ItalicElement(),
    HeaderElement(),
    OrderedList(),
    UnorderedList(),
  ];

  for (final element in elements) {
    text = element.replace(text);
  }

  text = text.replaceAll('\n', '<br>');

  return text;
}
