import 'package:get/get.dart';
import 'package:adf_ui/core/controllers/session_controller.dart';

// Example 1: Using session data in a widget
class UserProfileWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final sessionController = Get.find<SessionController>();
    
    return Obx(() {
      if (!sessionController.isLoggedIn) {
        return Text('Not logged in');
      }
      
      return Column(
        children: [
          Text('Welcome, ${sessionController.userName ?? 'User'}!'),
          Text('User ID: ${sessionController.userId}'),
          // Add more user info here
        ],
      );
    });
  }
}

// Example 2: Checking authentication in a controller
class HomeController extends GetxController {
  final SessionController sessionController = Get.find<SessionController>();
  
  @override
  void onInit() {
    super.onInit();
    
    // Check if user is authenticated
    if (!sessionController.isLoggedIn) {
      Get.offAllNamed('/signin');
      return;
    }
    
    // Use user data
    loadUserSpecificData(sessionController.userId!);
  }
  
  void loadUserSpecificData(String userId) {
    // Load data specific to this user
    print('Loading data for user: $userId');
  }
}

// Example 3: Making authenticated API calls
class ApiService extends GetConnect {
  final SessionController sessionController = Get.find<SessionController>();
  
  @override
  void onInit() {
    super.onInit();
    
    // Add interceptor to automatically add auth header
    httpClient.addRequestModifier<dynamic>((request) async {
      if (sessionController.isLoggedIn) {
        request.headers['Authorization'] = 'Bearer ${sessionController.token}';
      }
      return request;
    });
  }
  
  Future<Response> getUserData() async {
    if (!sessionController.isLoggedIn) {
      throw Exception('User not authenticated');
    }
    
    return await get('/api/user/${sessionController.userId}');
  }
}

// Example 4: Route guard middleware
class AuthMiddleware extends GetMiddleware {
  final SessionController sessionController = Get.find<SessionController>();
  
  @override
  RouteSettings? redirect(String? route) {
    // Check if user is authenticated and session is valid
    if (!sessionController.checkSessionValidity()) {
      return RouteSettings(name: '/signin');
    }
    
    return null; // Continue to requested route
  }
}