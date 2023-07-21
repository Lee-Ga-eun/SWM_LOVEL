import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yoggo/component/home/view/home_screen.dart';
import 'package:yoggo/component/login_screen.dart';

// class SplashScreen extends StatelessWidget {
//   const SplashScreen({super.key});

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static var splashUp = true;

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String? token;

  @override
  void initState() {
    super.initState();
    getToken();
    //navigateToHome(); // Call the navigateToHome function on initState
  }

  Future navigateToHome() async {
    await Future.delayed(const Duration(seconds: 2)); // Delay for 2 seconds
    Navigator.pushReplacement(
      // Replace the current screen with the home screen
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  Future<void> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString('token');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.yellow, // Set the background color to yellow
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('lib/images/bkground.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Builder(builder: (BuildContext context) {
          // if (token != null) {
          return const HomeScreen();
          // } else {
          //   return LoginScreen();
          // }
        }
            // return StreamBuilder<firebase_auth.User?>(
            //   stream: firebase_auth.FirebaseAuth.instance.authStateChanges(),
            //   builder: (BuildContext context) {
            //     if (!snapshot.hasData) {
            //       return LoginScreen();
            //     } else {
            //       print(snapshot);
            //       return HomeScreen();
            /*
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.network(
                          'https://ulpaiggkhrfbfuvteqkq.supabase.co/storage/v1/object/sign/yoggo-storage/logo_v0.1.png?token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1cmwiOiJ5b2dnby1zdG9yYWdlL2xvZ29fdjAuMS5wbmciLCJpYXQiOjE2ODYwNjQ4MTksImV4cCI6MTE2ODYwNjQ4MTh9.6EEFRhZZVyEDVbBt326I7lZBY439Ufagj_ou43986ys&t=2023-06-06T15%3A20%3A20.023Z',
                          height: 100,
                        ),
                        // const Text(
                        //   'YOGGO',
                        //   style: TextStyle(
                        //     fontSize: 32,
                        //     fontWeight: FontWeight.bold,
                        //   ),
                        // ),
                        const SizedBox(height: 16),
                        AnimatedTextKit(
                          animatedTexts: [
                            TypewriterAnimatedText(
                              'Welcome to Fairy Tale!',
                              textStyle: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              speed: const Duration(milliseconds: 200),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );*/
            //  }
            //     },
            //   );
            // },
            ),
      ),
    );
  }
}
