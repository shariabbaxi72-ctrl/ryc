import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ryc/routes/routes.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();

    
    Timer(Duration(seconds: 3), () {
      Navigator.pushReplacementNamed(context, AppRoutes.welcome);
    
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            Image.asset(
              'assets/images/splash.png',
              width: 350,
              height: 250,
              
            ),

            SizedBox(height: 2),

            Text(
              "Welcome to Repair Your Car",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: const Color.fromARGB(255, 98, 97, 97),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
