import 'package:flutter/material.dart';
import 'package:ryc/routes/routes.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
  backgroundColor: Colors.white,

    

  
  body: Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset('assets/images/splash.png',
        width: 200,),
        SizedBox(height: 30,),

        ElevatedButton(onPressed: (){
          Navigator.pushNamed(context, AppRoutes.signup);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 37, 31, 73),
          minimumSize: Size(200, 45),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            
          )
        ),
         child: Text("SignUp" ,style: TextStyle(color: Colors.white),),),

         SizedBox(height: 15),
         ElevatedButton(onPressed: (){

          Navigator.pushNamed(context, AppRoutes.login);
         },
         style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 107, 106, 106),
          minimumSize: Size(200, 45),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
         ),
         
          child: Text("Login",style: TextStyle(color: Colors.white),),),


      ],
    ),
  ),

    );
  }
}
///////////////////////////////

// import 'package:flutter/material.dart';
// import 'package:ryc/routes/routes.dart';
//
// class WelcomeScreen extends StatelessWidget {
//   const WelcomeScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     // Theme colors for consistency
//     const Color primaryColor = Color(0xFF1B2E4B);
//     const Color secondaryColor = Colors.grey;
//
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Container(
//         width: double.infinity,
//         padding: const EdgeInsets.symmetric(horizontal: 30),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Spacer(flex: 2),
//
//             // --- IMAGE / LOGO ---
//             Container(
//               decoration: BoxDecoration(
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.05),
//                     blurRadius: 20,
//                     offset: const Offset(0, 10),
//                   ),
//                 ],
//               ),
//               child: Image.asset(
//                 'assets/images/splash.png',
//                 width: 250,
//               ),
//             ),
//
//             const SizedBox(height: 40),
//
//             // --- TEXT SECTION ---
//             const Text(
//               "Get Started",
//               style: TextStyle(
//                 fontSize: 28,
//                 fontWeight: FontWeight.w900,
//                 color: primaryColor,
//                 letterSpacing: 1.0,
//               ),
//             ),
//             const SizedBox(height: 10),
//             const Text(
//               "Join us today and experience the best\ncar repair services at your fingertips.",
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: 15,
//                 color: Colors.grey,
//                 height: 1.5,
//               ),
//             ),
//
//             const Spacer(),
//
//             // --- SIGNUP BUTTON (Premium Gradient Look) ---
//             GestureDetector(
//               onTap: () => Navigator.pushNamed(context, AppRoutes.signup),
//               child: Container(
//                 width: double.infinity,
//                 height: 55,
//                 decoration: BoxDecoration(
//                   color: primaryColor,
//                   borderRadius: BorderRadius.circular(15),
//                   boxShadow: [
//                     BoxShadow(
//                       color: primaryColor.withOpacity(0.3),
//                       blurRadius: 12,
//                       offset: const Offset(0, 5),
//                     ),
//                   ],
//                 ),
//                 child: const Center(
//                   child: Text(
//                     "CREATE ACCOUNT",
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                       letterSpacing: 1.2,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//
//             const SizedBox(height: 20),
//
//             // --- LOGIN BUTTON (Clean Outlined Look) ---
//             OutlinedButton(
//               onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
//               style: OutlinedButton.styleFrom(
//                 minimumSize: const Size(double.infinity, 55),
//                 side: const BorderSide(color: primaryColor, width: 2),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(15),
//                 ),
//               ),
//               child: const Text(
//                 "LOG IN",
//                 style: TextStyle(
//                   color: primaryColor,
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                   letterSpacing: 1.2,
//                 ),
//               ),
//             ),
//
//             const SizedBox(height: 60),
//           ],
//         ),
//       ),
//     );
//   }
// }