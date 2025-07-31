import 'package:video_compress/video_compress.dart';

class VideoCompressor {


static Future<MediaInfo?> compressVideo(String videoPath) async {
  try {
    // Optional: show a loading indicator
    await VideoCompress.setLogLevel(0); // Reduce logs
    VideoCompress.cancelCompression();  // Ensure no other job is running

    final MediaInfo? compressedVideo = await VideoCompress.compressVideo(
      videoPath,
      quality: VideoQuality.Res1920x1080Quality
      , // Options: Low, Medium, High, etc.
      deleteOrigin: false, // Set to true to remove original file
      includeAudio: true,
    );

    if (compressedVideo == null) {
      print('Video compression failed.');
      return null;
    }

    print('Compressed video path: ${compressedVideo.path}');
    print('Original size: ${compressedVideo.filesize}');
    return compressedVideo;
  } catch (e) {
    print('Error compressing video: $e');
    return null;
  }
}

}