import 'package:flutter_app/objects/html_element.dart';

class HeaderElement extends HtmlElement {
  const HeaderElement();

  @override
  String toHtml(String input) {
    final pattern = RegExp(r'^(#+) (.+)$', multiLine: true);

    return input.replaceAllMapped(pattern, (match) {
      final headerLevel = match.group(1)!.length.clamp(0, 6);
      final text = match.group(2);

      return '<h$headerLevel>$text</h$headerLevel>';
    });
  }

  @override
  String toMarkdown(String input) {
    final pattern = RegExp(r'<h([1-6])>(.+)</h[1-6]>', multiLine: true);

    return input.replaceAllMapped(pattern, (match) {
      final headerLevel = match.group(1);
      final text = match.group(2);

      return '${'#' * int.parse(headerLevel!)} $text';
    });
  }
}
