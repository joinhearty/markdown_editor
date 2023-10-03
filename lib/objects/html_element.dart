abstract class HtmlElement {
  const HtmlElement(this.markdownSymbol);

  final String markdownSymbol;

  String replace(String input);
}
