// ignore_for_file: constant_identifier_names

part of 'app_pages.dart';

abstract class Routes {
  Routes._();
  static const HOME = _Paths.HOME;
  static const MAP = _Paths.MAP;
  static const CHECKIN = _Paths.CHECKIN;
  static const PROFILE = _Paths.PROFILE;
}

abstract class _Paths {
  _Paths._();
  static const HOME = '/home';
  static const MAP = '/map';
  static const CHECKIN = '/checkin';
  static const PROFILE = '/profile';

}
