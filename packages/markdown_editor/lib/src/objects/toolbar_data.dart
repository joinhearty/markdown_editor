import 'package:flutter/material.dart';
import 'package:markdown_editor/src/objects/button_data.dart';

class ToolbarData {
  const ToolbarData({
    this.bold,
    this.italic,
    this.highlight,
    this.link,
    this.increaseHeading,
    this.decreaseHeading,
    this.decoration,
    this.height = 50,
  });

  final ButtonData? bold;
  final ButtonData? italic;
  final ButtonData? highlight;
  final ButtonData? link;
  final ButtonData? increaseHeading;
  final ButtonData? decreaseHeading;
  final Decoration? decoration;
  final double height;
}
