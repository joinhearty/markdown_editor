import 'package:markdown_editor/src/elements/element.dart';

class ItalicElement extends Element {
  const ItalicElement();

  @override
  String toHtml(String input) {
    return input.replaceAllMapped(
        RegExp(
          '_(.+?)_',
          multiLine: true,
          dotAll: true,
        ), (match) {
      final text = match.group(1);

      return '<i>$text</i>';
    });
  }

  @override
  String toMarkdown(String input) {
    return input.replaceAllMapped(
        RegExp(
          '<i>(.+?)</i>',
          multiLine: true,
          dotAll: true,
        ), (match) {
      final text = match.group(1);

      return '_${text}_';
    });
  }
}
