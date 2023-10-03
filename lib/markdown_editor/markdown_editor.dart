import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MarkdownEditor extends StatefulWidget {
  const MarkdownEditor({
    super.key,
    required this.controller,
  });

  final TextEditingController controller;

  @override
  State<MarkdownEditor> createState() => _MarkdownEditorState();
}

class _MarkdownEditorState extends State<MarkdownEditor> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(selectionListener);
  }

  void selectionListener() {
    // check if the text is being selected
    final selection = widget.controller.selection;

    if (selection.baseOffset == selection.extentOffset) {
      print('no selection');
      return;
    }

    print('selection, start: ${selection.start}, end: ${selection.end}');
  }

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
    try {
      final clipboard = await Clipboard.getData(Clipboard.kTextPlain);

      final url = clipboard?.text;

      if (url == null) {
        return;
      }

      // ensure that the url is valid
      final pattern = RegExp(
        r'^(?:(?:http|https):\/\/)?[\w\-_]+(?:\.[\w\-_]+)+[\w\-.,@?^=%&:;/~\\+#]*$',
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
    } catch (e) {
      // do nothing
    }
  }

  void modifyText(
    String Function(String) modifier, {
    bool select = true,
  }) {
    final selectedText =
        widget.controller.selection.textInside(widget.controller.text);

    final text = widget.controller.text;

    final selection = widget.controller.selection;

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

        widget.controller.value = widget.controller.value.copyWith(
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
      extentOffset: selection.start + selectedText.length + startLength,
    );

    if (!select) {
      textSelection = TextSelection.collapsed(
        offset: selection.start + selectedText.length + startLength,
      );
    }

    if (selectedText.isEmpty) {
      textSelection = TextSelection.collapsed(
        offset:
            selection.start + selectedText.length + (modifiedText.length ~/ 2),
      );
    }

    widget.controller.value = widget.controller.value.copyWith(
      text: newText,
      selection: textSelection,
    );
  }

  // increases the heading level of the line where the cursor is
  void increaseHeading() {
    final text = widget.controller.text;

    final selection = widget.controller.selection;

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

    widget.controller.value = widget.controller.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: lineEnd + newLine.length),
    );
  }

  void decreaseHeading() {
    final text = widget.controller.text;

    final selection = widget.controller.selection;

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

    widget.controller.value = widget.controller.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: lineEnd + newLine.length),
    );
  }

  void checkForList() {
    final text = widget.controller.text;

    final selection = widget.controller.selection;

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
      widget.controller.value = widget.controller.value.copyWith(
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

      widget.controller.value = widget.controller.value.copyWith(
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

    widget.controller.value = widget.controller.value.copyWith(
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
        controller: widget.controller,
        maxLines: 10,
      ),
    );
  }
}
