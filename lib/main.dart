import 'package:flutter/material.dart';
import 'package:tone_master/tuner.dart';

void main() => runApp(new AudioStreamingApp());

class AudioStreamingApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Tuner(),
    );
  }
}
