// ignore_for_file: constant_identifier_names

part of 'app_pages.dart';

abstract class Routes {
  Routes._();
  static const MAP = _Paths.MAP;
  static const CHECKIN = _Paths.CHECKIN;
}

abstract class _Paths {
  _Paths._();
  static const MAP = '/map';
  static const CHECKIN = '/checkin';
 

}
