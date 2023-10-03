import 'package:flutter_app/objects/html_element.dart';

class ItalicElement extends HtmlElement {
  const ItalicElement() : super('__');

  @override
  String replace(String input) {
    return input.replaceAllMapped(
        RegExp(
          '$markdownSymbol(.+?)$markdownSymbol',
          multiLine: true,
          dotAll: true,
        ), (match) {
      final text = match.group(1);

      return '<i>$text</i>';
    });
  }
}
