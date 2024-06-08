import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';

class TunerScreen extends StatefulWidget {
  @override
  _TunerScreenState createState() => _TunerScreenState();
}

class _TunerScreenState extends State<TunerScreen> {
  FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  List<double> _samples = [];

  @override
  void initState() {
    super.initState();
    _recorder.openRecorder();
  }

  void _startRecording() async {
    await _recorder.startRecorder(
      codec: Codec.pcm16,
      toStream: (data) {
        setState(() {
          _samples = data.cast<double>(); // Convert List<int> to List<double>
        });
      },
    );
  }

  void _stopRecording() async {
    await _recorder.stopRecorder();
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ToneMaster'),
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _startRecording,
            child: Text('Start Recording'),
          ),
          ElevatedButton(
            onPressed: _stopRecording,
            child: Text('Stop Recording'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _samples.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_samples[index].toString()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
