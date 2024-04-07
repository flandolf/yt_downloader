import 'dart:io';

import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:yt_downloader/dark_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _pathController = TextEditingController();

  String filePath = "";

  Video? globalVideo;
  late List<StreamInfo> availableStreams;
  StreamInfo? selectedStream;

  // Quality options
  List<String> qualityOptions = [];

  String selectedQuality = '';

  bool isDownloading = false;

  Future download() async {
    setState(() {
      isDownloading = true;
    });
    if (await checkPath(_urlController.text) == false) {
      return;
    }
    var yt = YoutubeExplode();
    var manifest = await yt.videos.streamsClient.getManifest(globalVideo?.id);
    var audio = manifest.audioOnly.first;
    var video = manifest.videoOnly;

    var audioStream = yt.videos.streamsClient.get(audio);
    var videoStream = yt.videos.streamsClient.get(video.firstWhere((element) {
      return element.videoQualityLabel == selectedQuality;
    }));

    var audioFile = File('$filePath/${globalVideo?.title}.m4a').openWrite();
    var videoFile = File('$filePath/${globalVideo?.title}.mp4').openWrite();

    await audioStream.pipe(audioFile);
    await videoStream.pipe(videoFile);

    await audioFile.flush();
    await videoFile.flush();
    if (Platform.isWindows) {
      await Process.run(r'.\ffmpeg\bin\ffmpeg.exe', [
        '-i',
        '$filePath\\${globalVideo?.title}.m4a',
        '-i',
        '$filePath\\${globalVideo?.title}.mp4',
        '-c',
        'copy',
        '$filePath\\${globalVideo?.title}.mkv'
      ]);
    } else {
      FFmpegKit.executeAsync(
          '-i $filePath/${globalVideo?.title}.m4a -i $filePath/${globalVideo?.title}.mp4 -c copy $filePath/${globalVideo?.title}.mkv');
    }

    await audioFile.close();
    await videoFile.close();
    await File('$filePath/${globalVideo?.title}.m4a').delete();
    await File('$filePath/${globalVideo?.title}.mp4').delete();

    setState(() {
      isDownloading = false;
    });
  }

  Future<bool> checkPath(url) async {
    RegExp regExp = RegExp(
        r"^((?:https?:)?//)?((?:www|m)\.)?(youtube(-nocookie)?\.com|youtu.be)(/(?:[\w\-]+\?v=|embed/|live/|v/)?)([\w\-]+)(\S+)?$");

    return regExp.hasMatch(url);
  }

  Future pickPath() async {
    String? result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      setState(() {
        filePath = result;
        _pathController.text = filePath;
      });
    }
  }

  Future retrieveData() async {
    if (await checkPath(_urlController.text)) {
    } else {
      return;
    }
    var yt = YoutubeExplode();
    var video = await yt.videos.get(
      _urlController.text,
    );

    var manifest = await yt.videos.streamsClient.getManifest(video.id);
    var streamList = <String>[];
    for (var stream in manifest.videoOnly) {
      if (streamList.contains(stream.videoQualityLabel)) {
        continue;
      } else {
        streamList.add(stream.videoQualityLabel);
      }
    }
    setState(() {
      globalVideo = video;
      qualityOptions = streamList;
      selectedQuality = streamList.first;
    });
  }

  String formatDuration(Duration duration) {
    String hours = (duration.inHours % 24).toString().padLeft(2, '0');
    String minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    String seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  String formatNumberWithCommas(int number) {
    final formatter = NumberFormat('#,###');
    return formatter.format(number);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
              icon: const Icon(Icons.sunny),
              onPressed: () {
                Provider.of<DarkProvider>(context, listen: false).toggleDark();
              },
            )
          ],
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Youtube Downloader'),
              Text('Version 1.0.0 by @flandlolf',
                  style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        readOnly: true,
                        controller: _pathController,
                        decoration: const InputDecoration(
                          labelText: 'Path to save',
                          border: UnderlineInputBorder(),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.folder),
                      onPressed: pickPath,
                    )
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _urlController,
                  decoration: const InputDecoration(
                    labelText: 'Youtube URL',
                    border: UnderlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    FilledButton(
                        onPressed: retrieveData,
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text('Search')
                          ],
                        )),
                    const SizedBox(width: 16),
                    if (globalVideo != null)
                      FilledButton(
                          onPressed: download,
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.download,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text('Download')
                            ],
                          )),
                  ],
                ),
                if (globalVideo != null) ...[
                  Row(
                    children: [
                      ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                              globalVideo!.thumbnails.highResUrl,
                              width: 240,
                              height: 120,
                              fit: BoxFit.cover)),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          Text('Title: ${globalVideo!.title}'),
                          const SizedBox(height: 8),
                          Text('Author: ${globalVideo!.author}'),
                          const SizedBox(height: 8),
                          Text(
                              'Duration: ${formatDuration(globalVideo!.duration!)}'),
                          const SizedBox(height: 8),
                          Text('Views: ${formatNumberWithCommas(globalVideo!.engagement.viewCount)}'),
                          const SizedBox(height: 8),
                          Text('Likes: ${formatNumberWithCommas(globalVideo!.engagement.likeCount!)}'),
                          const SizedBox(height: 8),
                        ],
                      )
                    ],
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    itemCount: qualityOptions.length,
                    itemBuilder: (context, index) {
                      return RadioListTile(
                        title: Text(qualityOptions[index]),
                        value: qualityOptions[index],
                        groupValue: selectedQuality,
                        onChanged: (value) {
                          setState(() {
                            selectedQuality = value.toString();
                          });
                        },
                      );
                    },
                  ),
                  if (isDownloading) ...[
                    const SizedBox(height: 16),
                    const LinearProgressIndicator()
                  ]
                ],
              ],
            ),
          ),
        ));
  }
}
