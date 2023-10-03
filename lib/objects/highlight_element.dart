import 'package:flutter_app/objects/html_element.dart';

class HighlightElement extends HtmlElement {
  const HighlightElement();

  @override
  String replace(String input) {
    final pattern = RegExp(r'==(.+?)==', multiLine: true, dotAll: true);

    return input.replaceAllMapped(pattern, (match) {
      final text = match.group(1);

      return '<mark>$text</mark>';
    });
  }
}
