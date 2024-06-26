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
  String? detectedNote;
  Map<String, double>? octaveFrequencies;
  Map<String, List<double>>? noteRanges;

  // 追加: 周波数をドイツ音名に変換する関数
  String frequencyToNoteName(double frequency) {
    List<String> noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"];
    double a4 = 440.0;
    int noteNumber = (12 * (log(frequency / a4) / log(2))).round() + 57;
    int octave = (noteNumber / 12).floor() - 1;
    String noteName = noteNames[noteNumber % 12];
    return "$noteName$octave";
  }

  Map<String, List<double>> calculateNoteRanges(double baseFrequency) {
    List<String> noteNames = ["A", "A#", "B", "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#"];
    Map<String, List<double>> ranges = {};

    for (int octave = 0; octave <= 8; octave++) {
      for (int i = 0; i < noteNames.length; i++) {
        double frequency = baseFrequency * pow(2, (octave - 4) + i / 12);
        double lowerBound = frequency / pow(2, 1 / 24);
        double upperBound = frequency * pow(2, 1 / 24);
        String noteNameWithOctave = '${noteNames[i]}${octave}';
        ranges[noteNameWithOctave] = [lowerBound, upperBound];
      }
    }
    return ranges;
  }

  /// Check if microphone permission is granted.
  Future<bool> checkPermission() async => await Permission.microphone.isGranted;

  /// Request the microphone permission.
  Future<void> requestPermission() async => await Permission.microphone.request();

  void printFrequencyAndRange(double frequency, Map<String, List<double>> ranges) {
    for (var entry in ranges.entries) {
      String note = entry.key;
      double lowerBound = entry.value[0];
      double upperBound = entry.value[1];

      if (frequency >= lowerBound && frequency <= upperBound) {
        print('Frequency: $frequency Hz');
        print('Note: $note, Range: min: $lowerBound, max: $upperBound');
        return;
      }
    }
    // print('Frequency: $frequency Hz is out of range!');
  }

  @override
  void initState() {
    super.initState();
    noteRanges = calculateNoteRanges(440.0); // A=440Hzを基準にする例
  }

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

    printFrequencyAndRange(frequency, noteRanges!); // 追加: 検出された周波数と範囲を表示

    // // 倍音を取得 とりあえず現状不要なので追加実装用に残しておく
    // List<double> harmonics = [];
    // for (int i = 1; i <= 5; i++) {
    //   // 上位5つの倍音を取得
    //   int harmonicIndex = (maxIndex * i);
    //   if (harmonicIndex < magnitudes.length) {
    //     double harmonicFrequency = harmonicIndex * sampleRate! / buffer.length;
    //     harmonics.add(harmonicFrequency);
    //   }
    // }
    // print('Detected frequency: $frequency Hz');
    // print('Harmonics: $harmonics');

    setState(() {
      latestBuffer = buffer;
      detectedFrequency = frequency;
      detectedNote = frequencyToNoteName(frequency); // 追加: 検出された音名を保存
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

    AudioStreamer().sampleRate = 58000;
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
                Text('Detected note: ${detectedNote ?? ""}'),
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
