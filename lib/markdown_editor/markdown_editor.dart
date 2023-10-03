import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/markdown_editor/get_url.dart';
import 'package:flutter_app/objects/link_element.dart';

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
  TextSelection lastKnownPosition = const TextSelection.collapsed(offset: 0);

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(selectionListener);
  }

  void selectionListener() {
    lastKnownPosition = widget.controller.selection;
  }

  // wraps the selected text with ** (bold)
  void boldText() {
    modifyText((selected) => '**$selected**');
  }

  // wraps the selected text with __ (italics)
  void italicsText() {
    modifyText((selected) => '_${selected}_');
  }

  // wraps the selected text with == (highlight)
  void highlightText() {
    modifyText((selected) => '==$selected==');
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
        modifyText(
          select: false,
          (selected) => url!,
        );
        return;
      }

      modifyText((selected) {
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

    if (indexOfSelected == -1) {
      // replace the entire text
      widget.controller.value = widget.controller.value.copyWith(
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

  // writes a tab character where the cursor is
  void writeTab() {
    final text = widget.controller.text;

    final selection = widget.controller.selection;

    const tab = '\t';

    final newText = text.replaceRange(
      selection.start,
      null,
      tab,
    );

    widget.controller.value = widget.controller.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: selection.start + tab.length),
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
        const CharacterActivator('v', meta: true): insertLink,
        const CharacterActivator('v', control: true): insertLink,
        const CharacterActivator('.', meta: true): increaseHeading,
        const CharacterActivator('.', control: true): increaseHeading,
        const CharacterActivator(',', meta: true): decreaseHeading,
        const CharacterActivator(',', control: true): decreaseHeading,
        const SingleActivator(
          LogicalKeyboardKey.keyH,
          control: true,
          shift: true,
        ): highlightText,
        const SingleActivator(
          LogicalKeyboardKey.keyH,
          meta: true,
          shift: true,
        ): highlightText,
        const SingleActivator(LogicalKeyboardKey.enter): checkForList,
        const SingleActivator(LogicalKeyboardKey.tab): () {},
        const SingleActivator(LogicalKeyboardKey.tab, shift: true): () {},
      },
      child: Column(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: <Widget>[
                _Button(
                  tooltip: 'Bold (Ctrl + B)',
                  icon: const Icon(Icons.format_bold),
                  onPressed: boldText,
                ),
                _Button(
                  tooltip: 'Italics (Ctrl + I)',
                  icon: const Icon(Icons.format_italic),
                  onPressed: italicsText,
                ),
                _Button(
                  tooltip: 'Insert Link (Ctrl + V)',
                  icon: const Icon(Icons.link),
                  onPressed: () async {
                    String initialText = '';
                    String initialUrl = '';

                    final selectedText = widget.controller.selection.textInside(
                      widget.controller.text,
                    );

                    if (LinkElement.pattern.hasMatch(selectedText)) {
                      final match =
                          LinkElement.pattern.firstMatch(selectedText);

                      initialText = match?.group(1) ?? '';
                      initialUrl = match?.group(2) ?? '';
                    } else {
                      initialText = selectedText;

                      final clipboard =
                          await Clipboard.getData(Clipboard.kTextPlain);

                      initialUrl = (clipboard?.text ?? '').trim();
                    }

                    if (!context.mounted) {
                      return;
                    }

                    GetUrl(
                      initialText: initialText,
                      initialUrl: initialUrl,
                      onGet: (({String text, String url}) data) {
                        maintainSelection();

                        insertLink(data.text, data.url);
                      },
                    ).show(context);
                  },
                ),
                _Button(
                  tooltip: 'Increase Heading (Ctrl + .)',
                  icon: const Icon(Icons.text_increase),
                  onPressed: increaseHeading,
                ),
                _Button(
                  tooltip: 'Decrease Heading (Ctrl + ,)',
                  icon: const Icon(Icons.text_decrease),
                  onPressed: decreaseHeading,
                ),
                _Button(
                  tooltip: 'Highlight (Ctrl + Shift + H)',
                  icon: const Icon(Icons.h_mobiledata_sharp),
                  onPressed: highlightText,
                ),
              ],
            ),
          ),
          TextField(
            controller: widget.controller,
            maxLines: 10,
            onTapOutside: (_) {
              maintainSelection();
            },
          ),
        ],
      ),
    );
  }

  void maintainSelection() {
    widget.controller.selection = lastKnownPosition;
  }
}

class _Button extends StatelessWidget {
  const _Button({
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  final String? tooltip;
  final Widget icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: ColoredBox(
        color: Colors.transparent,
        child: SizedBox.square(
          dimension: 50,
          child: Tooltip(message: tooltip ?? '', child: icon),
        ),
      ),
    );
  }
}
