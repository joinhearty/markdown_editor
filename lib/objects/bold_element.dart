import 'package:flutter_app/objects/html_element.dart';

class BoldElement extends HtmlElement {
  const BoldElement();

  @override
  String replace(String input) {
    return input.replaceAllMapped(
        RegExp(
          r'\*\*(.+?)\*\*',
          multiLine: true,
          dotAll: true,
        ), (match) {
      final text = match.group(1);

      return '<b>$text</b>';
    });
  }
}
