import 'package:flutter_app/objects/html_element.dart';

class HeaderElement extends HtmlElement {
  const HeaderElement();

  @override
  String replace(String input) {
    final pattern = RegExp(r'^(#+) (.+)$', multiLine: true);

    return input.replaceAllMapped(pattern, (match) {
      final headerLevel = match.group(1)!.length;
      final text = match.group(2);

      return '<h$headerLevel>$text</h$headerLevel>';
    });
  }
}
