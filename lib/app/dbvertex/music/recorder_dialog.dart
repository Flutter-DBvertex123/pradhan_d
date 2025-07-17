import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../widgets/app_toast.dart';

class RecorderDialog extends StatefulWidget {
  const RecorderDialog({super.key});

  static Future<File?> show() {
    return Get.generalDialog(
      barrierDismissible: false,
      barrierLabel: 'music-preview',
      pageBuilder: (context, animation, secondaryAnimation) {
        return AlertDialog(
          content: RecorderDialog(),
        );
      },
      transitionDuration: Duration(milliseconds: 280),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: animation,
          child: child,
        );
      },
    );
  }

  @override
  State<RecorderDialog> createState() => _RecorderDialogState();
}

class _RecorderDialogState extends State<RecorderDialog> {
  bool animate = false;
  int duration = 0;

  final record = AudioRecorder();
  Timer? timer;

  @override
  void initState() {
    super.initState();
    startRecording();
  }

  Future<void> startRecording() async {
    final req = await record.hasPermission();

    if (!req) {
      longToastMessage("Permission denied");
      return;
    }

    final tempDir = await getTemporaryDirectory();
    final tempPath = '${tempDir.path}/recording.wav';

    await record.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,  // Use AAC encoder
        bitRate: 32000,              // 32 kbps bit rate
        sampleRate: 16000,           // 16 kHz sample rate
      ),
      path: tempPath,
    );
    timer = Timer.periodic(Duration(seconds: 1), (timer) => setState(() => duration++));
  }

  Future<void> stopRecording() async {
    try {
      timer?.cancel();
      final filePath = await record.stop();
      if (filePath != null && filePath.isNotEmpty) {
        final oldFile = File(filePath);
        final newFile = oldFile.renameSync('${oldFile.parent.path}/Recording - Pradhaan.wav');
        Get.back(result: newFile);
      } else {
        longToastMessage("Recording failed");
      }
    } catch (error) {
      longToastMessage("Recording failed: $error");
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    record.cancel();
    record.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _createBoom(),
          SizedBox(height: 8.w),
          Text('Tap to save recording')
        ],
      ),
    );
  }

  Widget _createBoom() {
    final width = MediaQuery.sizeOf(context).width;

    animate = duration % 2 == 0;

    return Center(
      child: SizedBox(
        width: width * 0.2,
        height: width * 0.2,
        child: GestureDetector(
          onTap: stopRecording,
          child: Stack(
            alignment: Alignment.center,
            // fit: StackFit.expand,
            children: [
              // Outer Pulsating Ring
              AnimatedContainer(
                duration: const Duration(milliseconds: 800),
                width: width * (animate ? 0.2 : 0.15),
                height: width * (animate ? 0.2 : 0.15),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(animate ? 0.3 : 0.0),
                  borderRadius: BorderRadius.circular(width),
                ),
              ),

              // Inner Button
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: width * (animate ? 0.12 : 0.15),
                height: width * (animate ? 0.12 : 0.15),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(animate ? 1.0 : 0.7),
                  borderRadius: BorderRadius.circular(width), // Circle to Rounded Square
                  border: Border.all(
                    color: Colors.red,
                    width: animate ? 2 : 4, // Border gets thinner when recording
                  ),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 90),
                width: width * (animate ? 0 : 0.15),
                height: width * (animate ? 0 : 0.15),
                alignment: Alignment.center,
                child: Text(
                  duration.toStringAsFixed(0),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: width * 0.05
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
