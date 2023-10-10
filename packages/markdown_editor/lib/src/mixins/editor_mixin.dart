import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

mixin EditorMixin {
  TextEditingController get controller;

  // wraps the selected text with ** (bold)
  void boldText() {
    _modifyText((selected) => '**$selected**');
  }

  // wraps the selected text with __ (italics)
  void italicsText() {
    _modifyText((selected) => '_${selected}_');
  }

  // wraps the selected text with == (highlight)
  void highlightText() {
    _modifyText((selected) => '==$selected==');
  }

  // wraps the selected text with []() (link)
  //
  // gets link from clipboard if not provided
  Future<void> insertLink([String? text, String? link]) async {
    try {
      var url = link;

      if (url == null) {
        final clipboard = await Clipboard.getData(Clipboard.kTextPlain);

        url = clipboard?.text;
      }

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
        _modifyText(
          select: false,
          (selected) => url!,
        );
        return;
      }

      _modifyText((selected) {
        var alt = selected;

        if (text != null) {
          alt = text;
        }

        return '[$alt]($url)';
      });
    } catch (e) {
      // do nothing
    }
  }

  void _modifyText(
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

    if (indexOfSelected == -1) {
      // replace the entire text
      controller.value = controller.value.copyWith(
        text: newText,
        selection: TextSelection.collapsed(
          offset: selection.start + modifiedText.length,
        ),
      );

      return;
    }

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
      extentOffset: selection.start + selectedText.length + startLength,
    );

    if (!select) {
      textSelection = TextSelection.collapsed(
        offset: selection.start +
            selectedText.length +
            startLength +
            modifiedText.length,
      );
    } else if (selectedText.isEmpty) {
      textSelection = TextSelection.collapsed(
        offset: selection.start + selectedText.length + modifiedText.length,
      );
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
}
