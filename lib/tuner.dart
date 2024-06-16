import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audio_streamer/audio_streamer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fftea/fftea.dart';

class Tuner extends StatefulWidget {
  @override
  TunerState createState() => TunerState();
}

class TunerState extends State<Tuner> {
  int? sampleRate;
  bool isRecording = false;
  List<double> audio = [];
  List<double>? latestBuffer;
  double? recordingTime;
  StreamSubscription<List<double>>? audioSubscription;
  double? detectedFrequency;

  /// Check if microphone permission is granted.
  Future<bool> checkPermission() async => await Permission.microphone.isGranted;

  /// Request the microphone permission.
  Future<void> requestPermission() async => await Permission.microphone.request();

  /// Call-back on audio sample.
  void onAudio(List<double> buffer) async {
    audio.addAll(buffer);

    // Get the actual sampling rate, if not already known.
    sampleRate ??= await AudioStreamer().actualSampleRate;
    recordingTime = audio.length / sampleRate!;

    // ウィンドウ関数を適用
    final window = Window.hanning(buffer.length);
    final windowedBuffer = List<double>.generate(buffer.length, (i) => buffer[i] * window[i]);

    // FFTを実行して周波数スペクトルを取得
    final fft = FFT(windowedBuffer.length);
    final freq = fft.realFft(windowedBuffer);
    final magnitudes = freq.discardConjugates().magnitudes();

    // 最大振幅の周波数成分を取得
    int maxIndex = magnitudes.indexOf(magnitudes.reduce(max));
    double frequency = maxIndex * sampleRate! / buffer.length;

    print('Detected frequency: $frequency Hz');

    setState(() {
      latestBuffer = buffer;
      detectedFrequency = frequency;
    });
  }

  void handleError(Object error) {
    setState(() => isRecording = false);
    print(error);
  }

  /// Start audio sampling.
  void start() async {
    if (!(await checkPermission())) {
      await requestPermission();
    }

    AudioStreamer().sampleRate = 44100;
    audioSubscription = AudioStreamer().audioStream.listen(onAudio, onError: handleError);

    setState(() => isRecording = true);
  }

  /// Stop audio sampling.
  void stop() async {
    audioSubscription?.cancel();
    setState(() => isRecording = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
          Container(
              margin: EdgeInsets.all(25),
              child: Column(children: [
                Container(
                  child: Text(isRecording ? "Mic: ON" : "Mic: OFF", style: TextStyle(fontSize: 25, color: Colors.blue)),
                  margin: EdgeInsets.only(top: 20),
                ),
                Text(''),
                Text('Max amp: ${latestBuffer?.reduce(max)}'),
                Text('Min amp: ${latestBuffer?.reduce(min)}'),
                Text('Detected frequency: ${detectedFrequency?.toStringAsFixed(2)} Hz'),
                Text('${recordingTime?.toStringAsFixed(2)} seconds recorded.'),
              ])),
        ])),
        floatingActionButton: FloatingActionButton(
          backgroundColor: isRecording ? Colors.red : Colors.green,
          child: isRecording ? Icon(Icons.stop) : Icon(Icons.mic),
          onPressed: isRecording ? stop : start,
        ),
      );
}
