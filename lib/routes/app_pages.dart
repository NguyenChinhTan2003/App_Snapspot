// ignore_for_file: constant_identifier_names


import 'package:app_snapspot/presentations/auth/bindings/auth_binding.dart';
import 'package:app_snapspot/presentations/auth/views/login_view.dart';
import 'package:app_snapspot/presentations/profile/bindings/profile_binding.dart';
import 'package:app_snapspot/presentations/profile/views/profile_view.dart';
import 'package:app_snapspot/presentations/checkin/bindings/checkin_binding.dart';
import 'package:app_snapspot/presentations/checkin/views/checkin_view.dart';
import 'package:app_snapspot/presentations/home/bindings/home_binding.dart';
import 'package:app_snapspot/presentations/home/views/home_view.dart';
import 'package:app_snapspot/presentations/map/bindings/map_binding.dart';
import 'package:app_snapspot/presentations/map/views/map_view.dart';
import 'package:get/get.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();
  static const INITIAL = Routes.HOME;

  static final routes = [
    GetPage(
      name: _Paths.HOME,
      page: () =>  const HomeView(),
      binding: HomeBinding(),
    ),
     GetPage(
      name: Routes.MAP,
      page: () => const MapPage(),
      binding: MapBinding(),
    ),
    GetPage(
      name: _Paths.CHECKIN,
      page: () =>  const CheckinView(),
      binding: CheckinBinding(),
    ),
    GetPage(
      name: Routes.PROFILE,
      page: () => const ProfileView(),
      binding: ProfileBinding(),
    ),
    GetPage(
      name: Routes.LOGIN,
      page: () => const LoginView(),
      binding: AuthBinding(),
    ),
  ];
}
