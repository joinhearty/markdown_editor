import 'package:flutter_app/objects/html_element.dart';

class LinkElement extends HtmlElement {
  const LinkElement();

  @override
  String replace(String input) {
    final pattern =
        RegExp(r'\[(.+?)\]\((.+?)\)', multiLine: true, dotAll: true);

    return input.replaceAllMapped(pattern, (match) {
      final text = match.group(1);
      final link = match.group(2);

      return '<a href="$link">$text</a>';
    });
  }
}
