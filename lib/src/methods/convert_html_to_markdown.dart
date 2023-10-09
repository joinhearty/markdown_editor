import 'package:markdown_editor/src/elements/elements.dart';

String convertHtmlToMarkdown(String input) {
  var text = input.trim();

  for (final element in elements) {
    text = element.toMarkdown(text);
  }

  text = text.replaceAll('<br>', '\n');

  return text;
}
