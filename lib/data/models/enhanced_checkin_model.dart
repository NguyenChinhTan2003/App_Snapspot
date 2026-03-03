import 'package:app_snapspot/data/models/checkin_model.dart';
import 'package:app_snapspot/data/models/user_profile_model.dart';
import 'package:app_snapspot/data/models/category_model.dart';
import 'package:app_snapspot/data/models/vibe_model.dart';

class EnhancedCheckInModel {
  final CheckInModel checkIn;
  final ProfileModel? profile;
  final CategoryModel? category;
  final VibeModel? vibe;

  EnhancedCheckInModel({
    required this.checkIn,
    this.profile,
    this.category,
    this.vibe,
  });
}
