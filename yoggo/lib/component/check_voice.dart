import 'package:flutter/material.dart';
import 'package:yoggo/size_config.dart';
import 'home/view/home_screen.dart';
import './record_retry.dart';
import 'package:audioplayers/audioplayers.dart';

class CheckVoice extends StatefulWidget {
  final String infenrencedVoice;

  const CheckVoice({
    super.key,
    required this.infenrencedVoice,
  });

  @override
  _CheckVoiceState createState() => _CheckVoiceState();
}

class _CheckVoiceState extends State<CheckVoice> {
  AudioPlayer audioPlayer = AudioPlayer();

  // void playAudio(String audioUrl) async {
  //   await audioPlayer.play(UrlSource(audioUrl));
  // }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
        body: Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('lib/images/bkground.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            height: SizeConfig.defaultSize!,
          ),
          Expanded(
            flex: 1,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'LOVEL',
                      style: TextStyle(
                        fontFamily: 'Modak',
                        fontSize: SizeConfig.defaultSize! * 5,
                      ),
                    ),
                  ],
                ),
                Positioned(
                  left: 2 * SizeConfig.defaultSize!,
                  child: IconButton(
                    icon: const Icon(Icons.cancel),
                    onPressed: () {
                      audioPlayer.stop();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HomeScreen(),
                        ),
                      );
                    },
                    //color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'Complete! Here is your voice!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 3 * SizeConfig.defaultSize!,
                color: const Color.fromARGB(255, 194, 120, 209),
                fontFamily: 'BreeSerif',
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  children: [
                    TextSpan(
                      children: [
                        TextSpan(
                          text:
                              'This dialogue highlights the mermaid\'s realization of the value\n',
                          style: TextStyle(
                              fontSize: 1.6 * SizeConfig.defaultSize!,
                              color: Colors.black,
                              fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text:
                              'of her voice, its intangible beauty, and its role in her pursuit of\n',
                          style: TextStyle(
                              fontSize: 1.6 * SizeConfig.defaultSize!,
                              color: Colors.black,
                              fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text:
                              'true love and self-discovery. Despite losing her voice, she finds \n ',
                          style: TextStyle(
                              fontSize: 1.6 * SizeConfig.defaultSize!,
                              color: Colors.black,
                              fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text:
                              'the strength to communicate through her heart and believes that \n',
                          style: TextStyle(
                              fontSize: 1.6 * SizeConfig.defaultSize!,
                              color: Colors.black,
                              fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text:
                              'love goes beyond words. The journey becomes  an opportunity for her\n',
                          style: TextStyle(
                              fontSize: 1.6 * SizeConfig.defaultSize!,
                              color: Colors.black,
                              fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text:
                              'to uncover her true essence and understand the essence of love and freedom.\n',
                          style: TextStyle(
                              fontSize: 1.6 * SizeConfig.defaultSize!,
                              color: Colors.black,
                              fontWeight: FontWeight.bold),
                        ),
                        // TextSpan(
                        //   text:
                        //       'and passions within me will not easily fade away. Love transcends\n',
                        //   style: TextStyle(
                        //       fontSize: 16.0,
                        //       color: Colors.black,
                        //       fontWeight: FontWeight.bold),
                        // ),
                        // TextSpan(
                        //   text:
                        //       'language. In this quest to reclaim my precious voice, I will discover my\n',
                        //   style: TextStyle(
                        //       fontSize: 16.0,
                        //       color: Colors.black,
                        //       fontWeight: FontWeight.bold),
                        // ),
                        // TextSpan(
                        //   text:
                        //       'true self and learn the ways of love and freedom."',
                        //   style: TextStyle(
                        //       fontSize: 16.0,
                        //       color: Colors.black,
                        //       fontWeight: FontWeight.bold),
                        // ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        audioPlayer.stop();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AudioRecorderRetry(
                                // rerecord: true,
                                // mustDelete: widget.path,
                                ),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(8.0), // 원하는 모양의 네모 박스로 변경
                        ),
                        backgroundColor:
                            const Color.fromARGB(255, 194, 120, 209),
                      ),
                      child: const Text(
                        ' Record Again ',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    SizedBox(
                      width: 3.0 * SizeConfig.defaultSize!,
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.play_arrow,
                        size: 3 * SizeConfig.defaultSize!,
                        color: const Color.fromARGB(255, 194, 120, 209),
                      ),
                      onPressed: () {
                        audioPlayer.play(UrlSource(widget.infenrencedVoice));
                      },
                    ),
                    SizedBox(
                      width: 3 * SizeConfig.defaultSize!,
                    ),
                    TextButton(
                      onPressed: () {
                        audioPlayer.stop();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HomeScreen(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(8.0), // 원하는 모양의 네모 박스로 변경
                        ),
                        backgroundColor:
                            const Color.fromARGB(255, 194, 120, 209),
                      ),
                      child: const Text(
                        '    I love it!    ',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    ));
  }
}
