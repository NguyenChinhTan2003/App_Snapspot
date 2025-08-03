// ignore_for_file: constant_identifier_names

import 'package:app_snapspot/presentations/map/bindings/map_binding.dart';
import 'package:app_snapspot/presentations/map/views/map_view.dart';
import 'package:get/get.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();
  static const INITIAL = Routes.MAP;

  static final routes = [
    GetPage(
      name: _Paths.MAP,
      page: () => const MapPage(),
      binding: MapBinding(),
    ),
   
  
  ];
}
