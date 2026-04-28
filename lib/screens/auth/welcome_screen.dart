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