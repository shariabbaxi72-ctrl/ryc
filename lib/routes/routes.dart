import 'package:flutter/material.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/auth/welcome_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/admin/admin_expert_screen.dart';
import '../screens/admin/admin_vehicle_screen.dart';
import '../screens/admin/admin_user_screen.dart';
import '../screens/admin/admin_problem_screen.dart';
import '../screens/expert/expert.dart';
import '../screens/user/user.dart';
import '../screens/user/view/dashboard_view.dart';
class AppRoutes {

  static const String splash = '/splash';

  static const String welcome='/welcome';

  static const String signup='/signup';

  static const String login='/login';
  
  static const String admin='/admin-screen';

 static const adminExpert = '/admin-expert';
 static const adminVehicle = '/admin-vehicle';
 static const adminUser = '/admin-user';
 static const adminProblem = '/admin-problem';

 static const String expert='/expert-screen';

 static const String user='/user-screen';


  static Map<String, WidgetBuilder> routes = {
    splash: (context) => SplashScreen(),
    welcome:(context)=> WelcomeScreen(),
    signup:(context)=>SignupScreen(),
    login:(context)=>LoginScreen(),
   // admin:(context)=>AdminScreen(),

   // user: (context) => const DashboardView(),


   // adminExpert:(context)=>AdminExpertScreen(),
   // adminVehicle:(context)=>AdminVehicleScreen(),
   // adminUser:(context)=>AdminUserScreen(),



   // adminProblem:(context)=>AdminProblemScreen(),
    expert:(context)=>ExpertHomeScreen(expertId: 0),
    user:(context)=>UserHomeScreen(),
  };
}
