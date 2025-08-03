import 'dart:async';
import 'package:app_snapspot/applications/services/global_binding.dart';
import 'package:app_snapspot/core/common_widgets/reset_app_widget.dart';
import 'package:app_snapspot/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:get/get_navigation/src/routes/transitions_type.dart';

import 'flavors.dart';


FutureOr<void> main() async {
  GlobalBinding().dependencies();
  runApp(
    ResetAppWidget(
      child: GetMaterialApp(
        title: F.title,
        debugShowCheckedModeBanner: false,
        initialRoute: AppPages.INITIAL,
        getPages: AppPages.routes,
        defaultTransition: Transition.rightToLeft,
        
      ),
      
    ),
  );
}