import 'package:flutter_app/objects/html_element.dart';

class OrderedList extends HtmlElement {
  const OrderedList();

  @override
  String toHtml(String input) {
    final pattern = RegExp(r'^(?:\s*)\d+\.(?: (.*))?$', multiLine: true);

    var text = input.replaceAllMapped(pattern, (match) {
      final text = match.group(1) ?? '';

      return '<oli>$text</oli>';
    });

    final buffer = StringBuffer();

    final segments = text.split('\n');

    var inGroup = false;
    for (var i = 0; i < segments.length; i++) {
      var segment = segments[i];
      if (segment.startsWith('<oli>')) {
        segment = segment.replaceAll('<oli>', '<li>');
        segment = segment.replaceAll('</oli>', '</li>');

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

  @override
  String toMarkdown(String input) {
    final orderedListPattern = RegExp(r'<ol>([\s\S]*?)<\/ol>', multiLine: true);

    return input.replaceAllMapped(orderedListPattern, (match) {
      final list = match.group(1);

      final segments = list!.split('<li>');

      final buffer = StringBuffer();

      for (var i = 1; i < segments.length; i++) {
        var segment = segments[i];

        segment = segment.replaceAll('</li>', '');

        buffer
          ..write(i)
          ..write('. ')
          ..write(segment);
      }

      return buffer.toString();
    });
  }
}
