import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MarkdownEditor extends StatelessWidget {
  const MarkdownEditor({
    super.key,
    required this.controller,
  });

  final TextEditingController controller;

  // wraps the selected text with ** (bold)
  void boldText() {
    modifyText((selected) => '**$selected**');
  }

  // wraps the selected text with __ (italics)
  void italicsText() {
    modifyText((selected) => '__${selected}__');
  }

  // wraps the selected text with []() (link)
  Future<void> pasteLink() async {
    final clipboard = await Clipboard.getData('text/plain');

    final url = clipboard?.text;

    if (url == null) {
      return;
    }

    // ensure that the url is valid
    final pattern = RegExp(
      r'^(?:http|https):\/\/[\w\-_]+(?:\.[\w\-_]+)+[\w\-.,@?^=%&:;/~\\+#]*$',
      caseSensitive: false,
      multiLine: false,
    );

    if (!pattern.hasMatch(url)) {
      modifyText(
        select: false,
        (selected) => url,
      );
      return;
    }

    modifyText((selected) => '[$selected]($url)');
  }

  void modifyText(
    String Function(String) modifier, {
    bool select = true,
  }) {
    final selectedText = controller.selection.textInside(controller.text);

    final text = controller.text;

    final selection = controller.selection;

    final modifiedText = modifier(selectedText);

    final newText =
        text.replaceRange(selection.start, selection.end, modifiedText);

    final indexOfSelected = modifiedText.indexOf(selectedText);

    assert(indexOfSelected != -1, 'selected text not found in modified text');

    final startLength = indexOfSelected;
    final endLength = modifiedText.length - selectedText.length - startLength;

    try {
      // check the prefix/suffix of the selected text to see if this modification
      // has already been set, if so, remove it
      final prefix = text.substring(
        selection.start - startLength,
        selection.start,
      );
      final prefixHasMatch = prefix == modifiedText.substring(0, prefix.length);

      final suffix = text.substring(
        selection.end,
        selection.end + endLength,
      );
      final suffixHasMatch = suffix ==
          modifiedText.substring(
            modifiedText.length - suffix.length,
          );

      if (prefixHasMatch && suffixHasMatch) {
        final newText = text.replaceRange(
          selection.start - startLength,
          selection.end + endLength,
          selectedText,
        );

        controller.value = controller.value.copyWith(
          text: newText,
          selection: TextSelection(
            baseOffset: selection.start - startLength,
            extentOffset: selection.start - startLength + selectedText.length,
          ),
        );

        return;
      }
    } catch (_) {
      // do nothing, this is just to catch out of bounds errors
    }

    var textSelection = TextSelection(
      baseOffset: selection.start + startLength,
      extentOffset: selection.end + endLength,
    );

    if (!select) {
      textSelection =
          TextSelection.collapsed(offset: selection.end + endLength);
    }

    controller.value = controller.value.copyWith(
      text: newText,
      selection: textSelection,
    );
  }

  // increases the heading level of the line where the cursor is
  void increaseHeading() {
    final text = controller.text;

    final selection = controller.selection;

    final segments = text.split('\n');

    var lineEnd = 0;
    String? line;
    for (final segment in segments) {
      if (lineEnd + segment.length < selection.baseOffset) {
        lineEnd += segment.length + 1;
      } else {
        line = segment;
        break;
      }
    }

    if (line == null) {
      return;
    }

    final heading = RegExp(r'^(#+) ');
    var newLine = line.replaceAllMapped(heading, (match) {
      final headingLevel = match.group(1)?.length;

      final newHeadingLevel = min(6, (headingLevel ?? 0) + 1);

      final newHeading = '#' * newHeadingLevel;

      return '$newHeading ';
    });

    if (!heading.hasMatch(newLine)) {
      newLine = '# $newLine';
    }

    final newText = text.replaceRange(
      lineEnd,
      lineEnd + line.length,
      newLine,
    );

    controller.value = controller.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: lineEnd + newLine.length),
    );
  }

  void decreaseHeading() {
    final text = controller.text;

    final selection = controller.selection;

    final segments = text.split('\n');

    var lineEnd = 0;
    String? line;
    for (final segment in segments) {
      if (lineEnd + segment.length < selection.baseOffset) {
        lineEnd += segment.length + 1;
      } else {
        line = segment;
        break;
      }
    }

    if (line == null) {
      return;
    }

    final heading = RegExp(r'^(#+) ');
    var newLine = line.replaceAllMapped(heading, (match) {
      final headingLevel = match.group(1)?.length;

      final newHeadingLevel = max(0, (headingLevel ?? 0) - 1);

      if (newHeadingLevel == 0) {
        return '';
      }

      final newHeading = '#' * newHeadingLevel;

      return '$newHeading ';
    });

    final newText = text.replaceRange(
      lineEnd,
      lineEnd + line.length,
      newLine,
    );

    controller.value = controller.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: lineEnd + newLine.length),
    );
  }

  void checkForList() {
    final text = controller.text;

    final selection = controller.selection;

    final segments = text.split('\n');

    var lineEnd = 0;
    String? line;
    for (final segment in segments) {
      if (lineEnd + segment.length < selection.baseOffset) {
        lineEnd += segment.length + 1;
      } else {
        line = segment;
        break;
      }
    }

    if (line == null) {
      return;
    }

    final list = RegExp(r'^(\s*)([-*+]|(\d+)\.) (.*)');
    if (!list.hasMatch(line)) {
      // add new new (as normal behavior)
      controller.value = controller.value.copyWith(
        text: text.replaceRange(
          selection.start,
          selection.end,
          '\n',
        ),
        selection: TextSelection.collapsed(offset: selection.end + 1),
      );
      return;
    }

    final match = list.firstMatch(line)!;

    final indent = match.group(1);
    final bullet = match.group(2);
    final number = match.group(3);
    final content = match.group(4);

    if (content?.isEmpty ?? true) {
      // remove the bullet/number
      final newText = text.replaceRange(
        lineEnd,
        lineEnd + line.length,
        '',
      );

      controller.value = controller.value.copyWith(
        text: newText,
        selection: TextSelection.collapsed(offset: lineEnd),
      );

      return;
    }

    String newLine = '';
    if (number != null) {
      final newNumber = int.parse(number) + 1;

      newLine = '$indent$newNumber. ';
    } else if (bullet != null) {
      newLine = '$indent- ';
    }

    newLine = '\n$newLine';

    final newText = text.replaceRange(
      lineEnd + line.length,
      null,
      newLine,
    );

    controller.value = controller.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(
        offset: lineEnd + line.length + newLine.length,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const CharacterActivator('b', meta: true): boldText,
        const CharacterActivator('b', control: true): boldText,
        const CharacterActivator('i', meta: true): italicsText,
        const CharacterActivator('i', control: true): italicsText,
        const CharacterActivator('v', meta: true): pasteLink,
        const CharacterActivator('v', control: true): pasteLink,
        const CharacterActivator('.', meta: true): increaseHeading,
        const CharacterActivator('.', control: true): increaseHeading,
        const CharacterActivator(',', meta: true): decreaseHeading,
        const CharacterActivator(',', control: true): decreaseHeading,
        const SingleActivator(LogicalKeyboardKey.enter): checkForList,
      },
      child: TextField(
        controller: controller,
        maxLines: 5,
      ),
    );
  }
}
