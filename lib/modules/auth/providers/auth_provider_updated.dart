import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:adf_ui/core/utils/app_config.dart';
import 'package:adf_ui/core/utils/global_functions.dart';
import 'package:adf_ui/core/utils/storage_manager.dart';
import 'package:adf_ui/core/controllers/session_controller.dart';

import 'package:adf_ui/main.dart';
import 'package:adf_ui/modules/exception/app_exception.dart';
import 'package:adf_ui/routes/app_pages.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:adf_ui/core/utils/logger.dart';

class AuthProvider extends GetConnect {
  String authurl = "${AppConfig.getInstanceDefault()!.apiurl}/sec/auth";
  String authlogin =
      "${AppConfig.getInstanceDefault()!.apiwsmobiss}/user/login";
  String clientid = AppConfig.getInstanceDefault()!.clientid;
  String clientsecret = AppConfig.getInstanceDefault()!.clientsecret;

  // Get session controller instance
  SessionController get sessionController => SessionController.instance;

  AuthProvider() {
    if (!kReleaseMode && AppConfig.getInstanceDefault()?.env != "prod") {
      allowAutoSignedCert = true;
    }
  }

  @override
  void onInit() {
    httpClient.defaultContentType = "application/json";
    httpClient.timeout = const Duration(seconds: 8);
    
    // Add interceptor to automatically add auth header and update last activity
    httpClient.addRequestModifier<dynamic>((request) async {
      if (sessionController.isLoggedIn) {
        request.headers['Authorization'] = 'Bearer ${sessionController.token}';
        // Update last activity on each API call
        await sessionController.updateLastActivity();
      }
      return request;
    });
    
    // Add response interceptor to handle token expiration
    httpClient.addResponseModifier<dynamic>((request, response) async {
      if (response.statusCode == 401) {
        // Token expired, logout user
        await logout();
      }
      return response;
    });
    
    super.onInit();
  }

  Future<bool> login(Map<String, dynamic> data) async {
    final appLoc = getAppLocalizations(Get.context!);
    final url =
        "$authlogin?userid=${data["Userid"]}&password=${data["Password"]}";
    logger.i(url);

    try {
      final response = await httpClient.get(url);
      logger.i(response.body);

      if (response.body != null && response.body['Status'] == true) {
        final result = response.body['Result'];
        
        // Create session using SessionController
        await sessionController.createSession(
          token: result['Token'],
          userId: result['UserId'],
          userName: result['NamaAgen'],
        );
        
        return true;
      } else {
        gShowDialog(message: response.body['Message'] ?? appLoc.errorDef);
        return false;
      }
    } on AppException catch (e) {
      logger.i(e);
      gShowDialog(message: e.message);
      return false;
    } on SocketException {
      gShowDialog(message: appLoc.errorNoConnection);
      return false;
    } on TimeoutException {
      gShowDialog(message: appLoc.errorTimeout);
      return false;
    } catch (e) {
      gShowDialog(message: "${appLoc.errorDef}: $e");
      return false;
    }
  }

  Future<void> updateGoogleToken(String? gtoken) async {
    final url = "$authurl/updategtoken";
    if (gtoken != null && sessionController.isLoggedIn) {
      try {
        String ua = AppConfig.getInstanceDefault()!.userAgent;
        var bodyPost =
            kIsWeb ? {"googletokenweb": gtoken} : {"googletoken": gtoken};

        final response =
            await httpClient.put(url, body: jsonEncode(bodyPost), headers: {
          "Authorization": "Bearer ${sessionController.token}",
          if (!kIsWeb) HttpHeaders.userAgentHeader: ua
        });
        
        currentServerTime.value = DateTime.parse(response.body["timestamp"]);
        logger.d(response.body);
      } catch (e) {
        logger.i(e);
        rethrow;
      }
    }
  }

  Future<void> logout() async {
    try {
      // Clear session data
      await sessionController.clearSession();
      
      // Navigate to sign in page
      Get.offAllNamed(Routes.SIGNIN);
    } catch (e) {
      logger.i(e);
      rethrow;
    }
  }

  Future<bool> signup(Map<String, dynamic> data) async {
    final url = "$authurl/signup";
    final auth = base64.encode(utf8.encode("$clientid$clientsecret"));
    String ua = AppConfig.getInstanceDefault()!.userAgent;
    try {
      final response = await httpClient.post(
        url,
        body: json.encode(data),
        headers: {
          "Authorization": "Basic $auth",
          if (!kIsWeb) HttpHeaders.userAgentHeader: ua
        },
      );
      checkResponse(response);
      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<String> activateUser(Map<String, dynamic> data) async {
    final url = "$authurl/activateuser";
    final auth = base64.encode(utf8.encode("$clientid$clientsecret"));
    String ua = AppConfig.getInstanceDefault()!.userAgent;
    try {
      final response = await httpClient.post(
        url,
        body: json.encode(data),
        headers: {
          "Authorization": "Basic $auth",
          if (!kIsWeb) HttpHeaders.userAgentHeader: ua
        },
      );
      checkResponse(response);
      currentServerTime.value = DateTime.parse(response.body["timestamp"]);
      return response.body["data"];
    } catch (e) {
      rethrow;
    }
  }

  Future<String> resendEmail(Map<String, dynamic> data) async {
    final url = "$authurl/resendemail";
    final auth = base64.encode(utf8.encode("$clientid$clientsecret"));
    String ua = AppConfig.getInstanceDefault()!.userAgent;
    try {
      final response = await httpClient.post(
        url,
        body: json.encode(data),
        headers: {
          "Authorization": "Basic $auth",
          if (!kIsWeb) HttpHeaders.userAgentHeader: ua
        },
      );
      checkResponse(response);
      currentServerTime.value = DateTime.parse(response.body["timestamp"]);
      return response.body["data"];
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> changePassword(Map<String, dynamic> data) async {
    final appLoc = getAppLocalizations(Get.context!);
    final url = "$authurl/changepwd";

    try {
      String ua = AppConfig.getInstanceDefault()!.userAgent;
      final response = await httpClient.post(
        url,
        headers: {
          "Authorization": "Bearer ${sessionController.token ?? ""}",
          if (!kIsWeb) HttpHeaders.userAgentHeader: ua
        },
        body: json.encode(data),
      );
      checkResponse(response);
      currentServerTime.value = DateTime.parse(response.body["timestamp"]);
      return response.body;
    } on AppException catch (e) {
      gShowDialog(message: e.message);
      rethrow;
    } on AuthException catch (e) {
      gShowDialog(message: e.message, onPressed: () => gToLoginPage());
      rethrow;
    } on SocketException {
      gShowDialog(message: appLoc.errorNoConnection);
      rethrow;
    } on TimeoutException {
      gShowDialog(message: appLoc.errorTimeout);
      rethrow;
    } catch (e) {
      gShowDialog(message: appLoc.errorDef);
      rethrow;
    }
  }

  Future<String> forgetPassword(Map<String, dynamic> data) async {
    final url = "$authurl/forgetpwd";
    final auth = base64.encode(utf8.encode("$clientid$clientsecret"));
    String ua = AppConfig.getInstanceDefault()!.userAgent;
    try {
      final response = await httpClient.post(
        url,
        body: json.encode(data),
        headers: {
          "Authorization": "Basic $auth",
          if (!kIsWeb) HttpHeaders.userAgentHeader: ua
        },
      );
      checkResponse(response);
      currentServerTime.value = DateTime.parse(response.body["timestamp"]);
      return response.body["data"];
    } catch (e) {
      rethrow;
    }
  }

  Future<void> resetPassword(Map<String, dynamic> data) async {
    final url = "$authurl/resetpwd";
    final auth = base64.encode(utf8.encode("$clientid$clientsecret"));
    String ua = AppConfig.getInstanceDefault()!.userAgent;
    try {
      final response = await httpClient.post(
        url,
        body: json.encode(data),
        headers: {
          "Authorization": "Basic $auth",
          if (!kIsWeb) HttpHeaders.userAgentHeader: ua
        },
      );
      checkResponse(response);
      currentServerTime.value = DateTime.parse(response.body["timestamp"]);
    } catch (e) {
      rethrow;
    }
  }

  // Helper method to check if user is authenticated
  bool get isAuthenticated => sessionController.isLoggedIn;
  
  // Helper method to get current user info
  String? get currentUserId => sessionController.userId;
  String? get currentUserName => sessionController.userName;
  String? get currentToken => sessionController.token;
}