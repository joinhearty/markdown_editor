# Simple Markdown Editor

[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]
[![License: MIT][license_badge]][license_link]

This is a minimalistic Markdown editor application built using Dart and Flutter. It allows you to edit Markdown documents with ease, but please note that it currently supports a limited set of Markdown elements, including:

- **Bold**
- **Header**
- **Highlight**
- **Italic**
- **Link**
- **Ordered List**
- **Unordered List**

## Getting Started

To use this Markdown editor in your Flutter project, follow these steps:

### Add Dependency

Open your project's `pubspec.yaml` file and add the `markdown_editor` package to your dependencies:

```yaml
dependencies:
  flutter:
    sdk: flutter
  markdown_editor: ^latest_version
```

Make sure to replace `latest_version` with the latest version of the `markdown_editor` package available on [pub.dev](https://pub.dev/packages/markdown_editor).

### Import the Package

In the Dart file where you want to use the Markdown editor, import the package like this:

```dart
import 'package:flutter/material.dart';
import 'package:markdown_editor/markdown_editor.dart';
```

### Use the MarkdownEditor Widget

Here's an example of how to use the Markdown editor in your Flutter application:

```dart
class SimpleMarkdownEditor extends StatelessWidget {
  const SimpleMarkdownEditor({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Markdown Editor'),
      ),
      body: Column(
        children: <Widget>[
          const SizedBox(height: 16),
          MarkdownEditor(
            controller: TextEditingController(),
            onChanged: (text) {
              print(text);
            },
          ),
        ],
      ),
    );
  }
}
```

Now, you can run your Flutter application, and the Markdown editor will be available in the specified screen or widget.

## Markdown Converter

This package provides two methods: `convertHtmlToMarkdown` and `convertMarkdownToHtml` for converting between Markdown and HTML.

### Convert HTML to Markdown

You can use the `convertHtmlToMarkdown` method to convert HTML content to Markdown:

```dart
import 'package:markdown_editor/markdown_converter.dart';

// HTML content to be converted
String htmlContent = '<p>This is <strong>bold</strong> and <em>italic</em> text.</p>';

// Convert HTML to Markdown
String markdownText = convertHtmlToMarkdown(htmlContent);

print(markdownText); // This is **bold** and *italic* text.
```

### Convert Markdown to HTML

You can use the `convertMarkdownToHtml` method to convert Markdown content to HTML:

```dart
import 'package:markdown_editor/markdown_converter.dart';

// Markdown content to be converted
String markdownText = '**This is bold** and *this is italic* text.';

// Convert Markdown to HTML
String htmlContent = convertMarkdownToHtml(markdownText);

print(htmlContent); // <p><strong>This is bold</strong> and <em>this is italic</em> text.</p>
```

These methods allow you to easily switch between Markdown and HTML formats in your Flutter application.

## Contributing

If you'd like to contribute to the `markdown_editor` package or report issues, you can do so on its [GitHub repository](https://github.com/mrgnhnt96/markdown_editor).

## Limitations

Please note that this Markdown editor currently supports only a limited set of Markdown elements as mentioned above. Additional Markdown elements may be added in future updates.

## License

This Markdown editor is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

Happy Markdown editing! 📝

[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis
