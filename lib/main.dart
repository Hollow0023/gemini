import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:intl/intl.dart';
import 'chat_message.dart';
import 'chat_user.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

void main() {
  runApp(const MyApp());
}

const apiKey = "AIzaSyCAIOvHM8JnyWEhPkUfqW3Qxdmkaqgt2q4";

const myUser = ChatUser(
    name: "ユーザー",
    color: Colors.white,
    messageColor: Colors.black,
    messageBackgroundColor: Color.fromARGB(255, 251, 255, 214),
    icon: Icon(Icons.person, color: Color.fromARGB(255, 56, 143, 82)));
const partnerUser = ChatUser(
    name: "Gemini 無料版",
    color: Colors.white,
    messageColor: Colors.black,
    messageBackgroundColor: Color.fromARGB(255, 239, 251, 248),
    icon: Icon(Icons.person, color: Color.fromARGB(189, 52, 132, 236)));

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _scrollController = ScrollController();
  final _textController = TextEditingController();
  late ChatSession _chat;
  late GenerativeModel _model;
  String voiceInput = '';
  String sendText = '';

//以下音声入力
  String lastWords = '';
  String lastError = '';
  String lastStatus = '';
  bool isRecording = false;
  stt.SpeechToText speech = stt.SpeechToText();

  Future<void> _speak() async {
    if (lastStatus == 'listening') {
      _stop();
    } else {
      bool available = await speech.initialize(
          onError: errorListener, onStatus: statusListener);
      if (available) {
        speech.listen(onResult: resultListener);
      } else {
        print("The user has denied the use of speech recognition");
      }
    }
    setState(() {
      isRecording = true;
    });
  }

  Future<void> _stop() async {
    speech.stop();
    setState(() {
      isRecording = false;
    });
  }

  void resultListener(SpeechRecognitionResult result) {
    setState(() {
      voiceInput = result.recognizedWords;
      _textController.text = voiceInput;
    });
  }

  void errorListener(SpeechRecognitionError error) {
    setState(() {
      lastError = '${error.errorMsg} - ${error.permanent}';
    });
  }

  void statusListener(String status) {
    setState(() {
      lastStatus = status;
    });
  }
// 音声入力ここまで

//以下読み上げ
  bool isSpeaking = false;
  String? Output = '';
  String speakOutput = '';
  FlutterTts flutterTts = FlutterTts();
  Future<void> _output() async {
    if (Output != null) {
      speakOutput = Output as String;
    }
    await flutterTts.setLanguage("ja-JP");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);
    await flutterTts.speak(speakOutput);
    setState(() {
      isSpeaking = true;
    });
  }

  Future<void> _stopOutput() async {
    await flutterTts.stop();
    setState(() {
      isSpeaking = false;
    });
  }
//読み上げここまで

  @override
  void initState() {
    _model = GenerativeModel(
      model: 'gemini-pro',
      apiKey: apiKey,
    );
    _chat = _model.startChat();
    super.initState();
  }

  final List<ChatMessage> _messages = [];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Google AI Dart SDK (Gemini)',
      theme:
          ThemeData(primarySwatch: Colors.red, canvasColor: Colors.transparent),
      home: Scaffold(
        appBar: AppBar(title: const Text('Google AI Dart SDK (Gemini)')),
        backgroundColor: const Color.fromARGB(189, 52, 132, 236),
        body: Column(
          children: [
            Expanded(
              child: Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  child: GroupedListView<ChatMessage, DateTime>(
                    controller: _scrollController,
                    elements: _messages,
                    order: GroupedListOrder.DESC,
                    sort: true,
                    reverse: true,
                    floatingHeader: true,
                    useStickyGroupSeparators: true,
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                    groupBy: (ChatMessage m) => DateTime(
                        m.sendDate.year, m.sendDate.month, m.sendDate.day),
                    groupHeaderBuilder: (ChatMessage m) {
                      return Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: DecoratedBox(
                                decoration: const BoxDecoration(
                                    color: Color.fromARGB(190, 18, 87, 177),
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(8.0))),
                                child: Padding(
                                  padding: const EdgeInsets.all(6),
                                  child: Text(
                                    DateFormat('yyyy年MM月dd日')
                                        .format(m.sendDate),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 12),
                                  ),
                                ),
                              ),
                            )
                          ]);
                    },
                    itemBuilder: (context, m) {
                      var isPartner = (m.user == partnerUser);
                      return Row(
                        mainAxisAlignment: isPartner
                            ? MainAxisAlignment.start
                            : MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: isPartner
                                ? CrossAxisAlignment.start
                                : CrossAxisAlignment.end,
                            children: [
                              Row(
                                children: [
                                  if (m.user.icon != null)
                                    CircleAvatar(
                                        radius: 10,
                                        backgroundColor: Colors.white,
                                        child: Icon(m.user.icon!.icon,
                                            size: 16,
                                            color: m.user.icon!.color)),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        left: 3, right: 5),
                                    child: Text(m.user.name,
                                        style: TextStyle(color: m.user.color)),
                                  ),
                                ],
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Card(
                                      elevation: 3,
                                      color: m.user.messageBackgroundColor,
                                      shadowColor: Colors.black45,
                                      shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(18.0))),
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 0, vertical: 0),
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                            top: 6.0,
                                            bottom: 6.0,
                                            left: 15.0,
                                            right: 15.0),
                                        child: m.message,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  )),
            ),
            Container(
              color: Colors.grey[200],
              padding: const EdgeInsets.only(bottom: 15, left: 50, right: 50, top: 15),
              child: TextField(
                controller: _textController,
                minLines: 1,
                maxLines: 5,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(24)),
                  focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(24)),
                      borderSide: BorderSide(color: Colors.blue, width: 2)),
                  prefixIcon: IconButton(
                    onPressed: isSpeaking ? _stopOutput : _output,
                    icon: Icon(isSpeaking ? Icons.stop : Icons.speaker,
                        color: Colors.blue),
                  ),
                  suffixIcon: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(
                      onPressed: () async {
                        if (_textController.text.isEmpty &&
                            voiceInput.isEmpty) return;
                        sendText = _textController.text.isNotEmpty
                            ? _textController.text
                            : voiceInput;
                        setState(() {
                          final message = ConstrainedBox(
                            constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width - 100),
                            child: SelectableText(sendText),
                          );
                          _messages.add(ChatMessage(
                              user: myUser,
                              message: message,
                              sendDate: DateTime.now()));
                          _textController.clear();
                          voiceInput = ''; // 送信後にvoiceInputをクリア
                        });
                        await Future.delayed(
                            const Duration(milliseconds: 100));
                        setState(() {
                          final spinkit = SpinKitThreeBounce(
                            itemBuilder: (context, index) =>
                                const DecoratedBox(decoration: BoxDecoration(color: Color.fromARGB(255, 28, 108, 212))),size: 16,);
                          final futureBuilder = FutureBuilder(
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                                return ConstrainedBox(
                                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width - 100),
                                  child: SelectableText(snapshot.data!),
                                );
                              }
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return spinkit;
                              }
                              if (snapshot.hasError) {
                                return Text("エラーが発生しました(${snapshot.error!})");
                              }
                              return const Text("エラーが発生しました");
                            },
                            future: Future.delayed(
                                const Duration(milliseconds: 500), () async { 
                                  final response = await _chat
                                  .sendMessage(Content.text(sendText));
                              print(response.text);
                              Output = response.text;
                              return response.text ?? "エラーが発生しました";
                            }),
                          );
                          _messages.add(ChatMessage(
                              user: partnerUser,
                              message: futureBuilder,
                              sendDate: DateTime.now()));
                        });
                      },
                      icon: const Icon(Icons.send, color: Colors.blue),
                    ),
                    IconButton(
                      onPressed: isRecording ? _stop : _speak,
                      icon: Icon(isRecording ? Icons.stop : Icons.mic,
                          color: Colors.blue),
                    ),
                  ]),
                ),
              )
            )
          ],
        ),
      ),
    );
  }
}
