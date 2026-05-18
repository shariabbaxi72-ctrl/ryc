// // import 'dart:async';
// // import 'package:flutter/material.dart';
// // import 'package:ryc/routes/routes.dart';
// //
// // class SplashScreen extends StatefulWidget {
// //   @override
// //   _SplashScreenState createState() => _SplashScreenState();
// // }
// //
// // class _SplashScreenState extends State<SplashScreen> {
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //
// //
// //     Timer(Duration(seconds: 5), () {
// //       Navigator.pushReplacementNamed(context, AppRoutes.welcome);
// //
// //     });
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: Colors.white,
// //
// //       body: Center(
// //         child: Column(
// //           mainAxisAlignment: MainAxisAlignment.center,
// //           children: [
// //
// //             Image.asset(
// //               'assets/images/splash.png',
// //               width: 350,
// //               height: 250,
// //
// //             ),
// //
// //             SizedBox(height: 2),
// //
// //             Text(
// //               "Welcome to Repair Your Car",
// //               style: TextStyle(
// //                 fontSize: 26,
// //                 fontWeight: FontWeight.bold,
// //                 color: const Color.fromARGB(255, 98, 97, 97),
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }
// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:ryc/routes/routes.dart';
//
// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});
//
//   @override
//   _SplashScreenState createState() => _SplashScreenState();
// }
//
// class _SplashScreenState extends State<SplashScreen> {
//   @override
//   void initState() {
//     super.initState();
//     // 5 seconds ka timer for navigation
//     Timer(const Duration(seconds: 5), () {
//       Navigator.pushReplacementNamed(context, AppRoutes.welcome);
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Container(
//         width: double.infinity,
//         height: double.infinity,
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Spacer(flex: 3),
//
//             // --- IMAGE WITH SOFT SHADOW ---
//             Container(
//               decoration: BoxDecoration(
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.08),
//                     blurRadius: 30,
//                     offset: const Offset(0, 15),
//                   ),
//                 ],
//               ),
//               child: Image.asset(
//                 'assets/images/splash.png',
//                 width: 300,
//                 height: 220,
//                 fit: BoxFit.contain,
//               ),
//             ),
//
//             const SizedBox(height: 50),
//
//             // --- PREMIUM TYPOGRAPHY ---
//             const Text(
//               "REPAIR YOUR CAR",
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: 32,
//                 fontWeight: FontWeight.w900, // Thickest weight
//                 color: Color(0xFF1B2E4B), // Your theme color
//                 letterSpacing: 2.0,
//               ),
//             ),
//
//             const SizedBox(height: 10),
//
//
//
//             const Spacer(flex: 2),
//
//             // --- CLEAN NATIVE LOADER ---
//             const SizedBox(
//               width: 30,
//               height: 30,
//               child: CircularProgressIndicator(
//                 strokeWidth: 3,
//                 valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1B2E4B)),
//               ),
//             ),
//
//             const SizedBox(height: 15),
//
//             const Text(
//               "Getting things ready...",
//               style: TextStyle(
//                 fontSize: 12,
//                 color: Colors.grey,
//                 letterSpacing: 0.5,
//                 fontStyle: FontStyle.italic,
//               ),
//             ),
//
//             const SizedBox(height: 50),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ryc/routes/routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // 5 seconds ka timer for navigation
    Timer(const Duration(seconds: 5), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.welcome);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea( // Taake notch ya status bar se bacha ja sakay
        child: SingleChildScrollView( // FIX: Overflow se bachne ke liye scroll add kiya
          child: Container(
            width: double.infinity,
            // Screen ki total height set kar di taake content center mein rahay
            height: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 3),

                // --- IMAGE WITH SOFT SHADOW ---
                Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/splash.png',
                    width: 280, // Size thora kam kiya taake choti screen pe fit aaye
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 40),

                // --- PREMIUM TYPOGRAPHY ---
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    "REPAIR YOUR CAR",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28, // Font thora optimize kiya
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1B2E4B),
                      letterSpacing: 2.0,
                    ),
                  ),
                ),

                const Spacer(flex: 2),

                // --- CLEAN NATIVE LOADER ---
                const SizedBox(
                  width: 25,
                  height: 25,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1B2E4B)),
                  ),
                ),

                const SizedBox(height: 15),

                const Text(
                  "Getting things ready...",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    letterSpacing: 0.5,
                    fontStyle: FontStyle.italic,
                  ),
                ),

                const SizedBox(height: 40), // Bottom padding fix
              ],
            ),
          ),
        ),
      ),
    );
  }
}