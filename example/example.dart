import 'package:flutter/material.dart';
import 'package:markdown_editor/markdown_editor.dart';

class Example extends StatelessWidget {
  const Example({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: <Widget>[
          const Text('Markdown Editor'),
          const SizedBox(height: 16),
          MarkdownEditor(
            controller: TextEditingController(),
            onChanged: (text) {
              print(text);
            },
          ),
        ],
      ),
    );
  }
}
