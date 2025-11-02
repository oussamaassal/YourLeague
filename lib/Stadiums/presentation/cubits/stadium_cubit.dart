import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/stadium.dart';
import '../../domain/repos/stadium_repo.dart';
import 'stadium_states.dart';

class StadiumCubit extends Cubit<StadiumState> {
  final StadiumRepo stadiumRepo;

  StadiumCubit({required this.stadiumRepo}) : super(StadiumInitial());

  // Create stadium
  Future<void> createStadium({
    required String name,
    required String city,
    required String address,
    required int capacity,
    required double pricePerHour,
    String imageUrl = '',
    String? userId,
  }) async {
    try {
      emit(StadiumLoading());

      final stadium = Stadium(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        city: city,
        address: address,
        capacity: capacity,
        pricePerHour: pricePerHour,
        imageUrl: imageUrl,
        userId: userId,
        createdAt: fs.Timestamp.now(),
      );

      await stadiumRepo.createStadium(stadium);
      emit(StadiumOperationSuccess('Stadium created successfully'));
      await getAllStadiums(); // Refresh list
    } catch (e) {
      emit(StadiumError('Failed to create stadium: $e'));
    }
  }

  // Get single stadium
  Future<void> getStadium(String stadiumId) async {
    try {
      emit(StadiumLoading());
      final stadium = await stadiumRepo.getStadium(stadiumId);
      if (stadium != null) {
        emit(StadiumLoaded(stadium));
      } else {
        emit(StadiumError('Stadium not found'));
      }
    } catch (e) {
      emit(StadiumError('Failed to get stadium: $e'));
    }
  }

  // Get all stadiums
  Future<void> getAllStadiums() async {
    try {
      emit(StadiumLoading());
      final stadiums = await stadiumRepo.getAllStadiums();
      emit(StadiumsLoaded(stadiums));
    } catch (e) {
      emit(StadiumError('Failed to get stadiums: $e'));
    }
  }

  // Get stadiums by user
  Future<void> getStadiumsByUser(String userId) async {
    try {
      emit(StadiumLoading());
      final stadiums = await stadiumRepo.getStadiumsByUser(userId);
      emit(StadiumsLoaded(stadiums));
    } catch (e) {
      emit(StadiumError('Failed to get stadiums: $e'));
    }
  }

  // Watch all stadiums (stream)
  Stream<List<Stadium>> watchAllStadiums() {
    return stadiumRepo.watchAllStadiums();
  }

  // Update stadium
  Future<void> updateStadium(Stadium stadium) async {
    try {
      emit(StadiumLoading());
      await stadiumRepo.updateStadium(stadium);
      emit(StadiumOperationSuccess('Stadium updated successfully'));
      await getAllStadiums(); // Refresh list
    } catch (e) {
      emit(StadiumError('Failed to update stadium: $e'));
    }
  }

  // Delete stadium
  Future<void> deleteStadium(String stadiumId) async {
    try {
      emit(StadiumLoading());
      await stadiumRepo.deleteStadium(stadiumId);
      emit(StadiumOperationSuccess('Stadium deleted successfully'));
      await getAllStadiums(); // Refresh list
    } catch (e) {
      emit(StadiumError('Failed to delete stadium: $e'));
    }
  }
}

