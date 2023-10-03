import 'package:flutter_app/objects/html_element.dart';

class OrderedList extends HtmlElement {
  const OrderedList() : super(r'\d\.');

  @override
  String replace(String input) {
    final pattern = RegExp(r'^\d+. (.*)$', multiLine: true);

    var text = input.replaceAllMapped(pattern, (match) {
      final text = match.group(1);

      return '<li>$text</li>';
    });

    final buffer = StringBuffer();

    final segments = text.split('\n');

    var inGroup = false;
    for (var i = 0; i < segments.length; i++) {
      final segment = segments[i];
      if (segment.startsWith('<li>')) {
        if (inGroup) {
          buffer.write(segment);
        } else {
          inGroup = true;

          buffer
            ..write('<ol>')
            ..write(segment);
        }
      } else if (inGroup) {
        inGroup = false;

        buffer
          ..write('</ol> ')
          ..write(segment);
      } else {
        buffer.write(segment);
      }

      if (i == segments.length - 1 && inGroup) {
        buffer.writeln('</ol> ');
      } else {
        buffer.writeln();
      }
    }

    return buffer.toString();
  }
}
