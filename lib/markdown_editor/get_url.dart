import 'package:flutter/material.dart';

class GetUrl extends StatefulWidget {
  const GetUrl({
    required this.initialText,
    required this.initialUrl,
    required this.onGet,
    super.key,
  });

  final String initialText;
  final String initialUrl;
  final void Function(({String text, String url})) onGet;

  void show(BuildContext context) {
    showGeneralDialog<void>(
      context: context,
      routeSettings: const RouteSettings(name: '/get-url'),
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      pageBuilder: (context, _, __) => Material(
        type: MaterialType.transparency,
        child: this,
      ),
    );
  }

  @override
  State<GetUrl> createState() => _GetUrlState();
}

class _GetUrlState extends State<GetUrl> {
  final urlController = TextEditingController();
  final textController = TextEditingController();

  @override
  void initState() {
    super.initState();

    textController.text = widget.initialText;

    if (validateUrl(widget.initialUrl)) {
      urlController.text = widget.initialUrl;
    }

    urlController.addListener(onTextChanged);
    textController.addListener(onTextChanged);
  }

  @override
  void dispose() {
    urlController.dispose();
    textController.dispose();
    super.dispose();
  }

  void onTextChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: MediaQuery.sizeOf(context).width * 0.5,
        child: Material(
          type: MaterialType.transparency,
          child: Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).dialogBackgroundColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      'Insert URL',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: 'Text',
                            ),
                            controller: textController,
                            autofocus: true,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: 'URL',
                            ),
                            controller: urlController,
                            autofocus: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: !isValid
                                ? null
                                : () {
                                    final url = urlController.text.trim();
                                    final text = textController.text.trim();

                                    Navigator.of(context).pop();

                                    widget.onGet(
                                      (text: text, url: url),
                                    );
                                  },
                            child: const Text('Done'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool validateUrl(String url) {
    final pattern = RegExp(
      r'^(?:(?:http|https):\/\/)?[\w\-_]+(?:\.[\w\-_]+)+[\w\-.,@?^=%&:;/~\\+#]*$',
      caseSensitive: false,
      multiLine: false,
    );

    return pattern.hasMatch(url);
  }

  bool get isValid {
    bool canSave = true;

    canSave &= validateUrl(urlController.text.trim());
    canSave &= textController.text.trim().isNotEmpty;

    return canSave;
  }
}
