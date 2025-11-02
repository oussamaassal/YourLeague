import '../entities/stadium.dart';

abstract class StadiumRepo {
  // Create stadium
  Future<void> createStadium(Stadium stadium);

  // Read stadiums
  Future<Stadium?> getStadium(String stadiumId);
  Future<List<Stadium>> getAllStadiums();
  Future<List<Stadium>> getStadiumsByUser(String userId);
  Stream<List<Stadium>> watchAllStadiums();
  Stream<Stadium?> watchStadium(String stadiumId);

  // Update stadium
  Future<void> updateStadium(Stadium stadium);

  // Delete stadium
  Future<void> deleteStadium(String stadiumId);
}

