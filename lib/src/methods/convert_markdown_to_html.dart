import 'package:markdown_editor/src/elements/elements.dart';

String convertMarkdownToHtml(String input) {
  var text = input.trim();

  for (final element in elements) {
    text = element.toHtml(text);
  }

  text = text.replaceAll('\n', '<br>');

  return text;
}
