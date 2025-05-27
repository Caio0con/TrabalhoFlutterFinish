import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class TextInput extends StatefulWidget {
  final void Function(String) updateFunction;
  final String textLabel;

  const TextInput(
      {super.key, required this.updateFunction, required this.textLabel});

  @override
  State<StatefulWidget> createState() {
    return _textInput();
  }
}

class _textInput extends State<TextInput> {
  final textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return TextField(
        decoration: InputDecoration(labelText: widget.textLabel),
        controller: textController,
        onChanged: widget.updateFunction);
  }
}
