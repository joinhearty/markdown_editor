import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:markdown_editor/markdown_editor.dart';
import 'package:markdown_editor/src/elements/link_element.dart';

class MarkdownEditor extends StatefulWidget {
  const MarkdownEditor({
    super.key,
    this.controller,
    this.onChanged,
    this.textField,
  });

  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final TextField? textField;

  @override
  State<MarkdownEditor> createState() => _MarkdownEditorState();
}

class _MarkdownEditorState extends State<MarkdownEditor> with EditorMixin {
  TextSelection lastKnownPosition = const TextSelection.collapsed(offset: 0);
  late final TextEditingController _controller;

  @override
  TextEditingController get controller => _controller;

  @override
  void initState() {
    super.initState();

    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(selectionListener);
  }

  @override
  void dispose() {
    _controller.removeListener(selectionListener);

    if (widget.controller == null) {
      _controller.dispose();
    }

    super.dispose();
  }

  void selectionListener() {
    lastKnownPosition = controller.selection;
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
      lineEnd + line.length,
      newLine,
    );

    controller.value = controller.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(
        offset: lineEnd + line.length + newLine.length,
      ),
    );
  }

  void maintainSelection() {
    controller.selection = lastKnownPosition;
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

                    final selectedText = controller.selection.textInside(
                      controller.text,
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

                    GetUrlDialog(
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
          widget.textField?.copyWith(
                onTapOutside: (_) {
                  maintainSelection();
                  widget.textField?.onTapOutside?.call(_);
                },
              ) ??
              TextField(
                controller: controller,
                maxLines: 10,
                onChanged: widget.onChanged,
                onTapOutside: (_) {
                  maintainSelection();
                },
              ),
        ],
      ),
    );
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

extension _TextFieldX on TextField {
  TextField copyWith({
    void Function(PointerDownEvent)? onTapOutside,
  }) {
    return TextField(
      key: key,
      controller: controller,
      focusNode: focusNode,
      undoController: undoController,
      decoration: decoration,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      style: style,
      strutStyle: strutStyle,
      textAlign: textAlign,
      textAlignVertical: textAlignVertical,
      textDirection: textDirection,
      readOnly: readOnly,
      showCursor: showCursor,
      autofocus: autofocus,
      obscuringCharacter: obscuringCharacter,
      obscureText: obscureText,
      autocorrect: autocorrect,
      smartDashesType: smartDashesType,
      smartQuotesType: smartQuotesType,
      enableSuggestions: enableSuggestions,
      maxLines: maxLines,
      minLines: minLines,
      expands: expands,
      maxLength: maxLength,
      maxLengthEnforcement: maxLengthEnforcement,
      onChanged: onChanged,
      onEditingComplete: onEditingComplete,
      onSubmitted: onSubmitted,
      onAppPrivateCommand: onAppPrivateCommand,
      inputFormatters: inputFormatters,
      enabled: enabled,
      cursorWidth: cursorWidth,
      cursorHeight: cursorHeight,
      cursorRadius: cursorRadius,
      cursorOpacityAnimates: cursorOpacityAnimates,
      cursorColor: cursorColor,
      selectionHeightStyle: selectionHeightStyle,
      selectionWidthStyle: selectionWidthStyle,
      keyboardAppearance: keyboardAppearance,
      scrollPadding: scrollPadding,
      dragStartBehavior: dragStartBehavior,
      enableInteractiveSelection: enableInteractiveSelection,
      selectionControls: selectionControls,
      onTap: onTap,
      onTapOutside: onTapOutside ?? this.onTapOutside,
      mouseCursor: mouseCursor,
      buildCounter: buildCounter,
      scrollController: scrollController,
      scrollPhysics: scrollPhysics,
      autofillHints: autofillHints,
      contentInsertionConfiguration: contentInsertionConfiguration,
      clipBehavior: clipBehavior,
      restorationId: restorationId,
      scribbleEnabled: scribbleEnabled,
      enableIMEPersonalizedLearning: enableIMEPersonalizedLearning,
      contextMenuBuilder: contextMenuBuilder,
      canRequestFocus: canRequestFocus,
      spellCheckConfiguration: spellCheckConfiguration,
      magnifierConfiguration: magnifierConfiguration,
    );
  }
}
