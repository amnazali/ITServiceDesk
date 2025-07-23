import 'package:get/get.dart';
import 'package:adf_ui/core/controllers/session_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Register SessionController as a permanent singleton
    Get.put<SessionController>(SessionController(), permanent: true);
  }
}