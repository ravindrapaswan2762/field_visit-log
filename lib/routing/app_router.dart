import 'package:flutter/material.dart';
import '../features/visits/presentation/screens/add_visit_screen.dart';
import '../features/visits/presentation/screens/visit_details_screen.dart';
import '../features/visits/presentation/screens/visit_list_screen.dart';

class AppRouter {
  AppRouter._();

  static const String visitList = '/';
  static const String addVisit = '/add-visit';
  static const String visitDetails = '/visit-details';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case visitList:
        return MaterialPageRoute(builder: (_) => const VisitListScreen());

      case addVisit:
        return MaterialPageRoute(
          builder: (_) => const AddVisitScreen(),
          fullscreenDialog: true,
        );

      case visitDetails:
        final visitId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => VisitDetailsScreen(visitId: visitId),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('Unknown route: ${settings.name}')),
          ),
        );
    }
  }
  
}
