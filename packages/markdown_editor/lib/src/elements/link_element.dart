import 'package:markdown_editor/src/elements/element.dart';

class LinkElement extends Element {
  const LinkElement();

  static RegExp pattern =
      RegExp(r'\[(.+?)\]\((.+?)\)', multiLine: true, dotAll: true);

  @override
  String toHtml(String input) {
    return input.replaceAllMapped(pattern, (match) {
      final text = match.group(1);
      final link = match.group(2);

      return '<a href="$link">$text</a>';
    });
  }

  @override
  String toMarkdown(String input) {
    return input.replaceAllMapped(
        RegExp(
          r'<a href="(.+?)">(.+?)</a>',
          multiLine: true,
          dotAll: true,
        ), (match) {
      final text = match.group(2);
      final link = match.group(1);

      return '[$text]($link)';
    });
  }
}
