import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/stadium.dart';
import '../../domain/repos/stadium_repo.dart';
import '../../domain/errors/stadium_exceptions.dart';
import 'stadium_states.dart';

class StadiumCubit extends Cubit<StadiumState> {
  final StadiumRepo stadiumRepo;
  String? _currentUserId; // Track current user for security checks

  StadiumCubit({required this.stadiumRepo}) : super(StadiumInitial());

  void setCurrentUserId(String? userId) {
    _currentUserId = userId;
  }

  // Create stadium
  Future<void> createStadium({
    required String name,
    required String city,
    required String address,
    required int capacity,
    required double pricePerHour,
    List<String> imageUrls = const [],
    String? userId,
    double? latitude,
    double? longitude,
    String? phoneNumber,
    String? description,
  }) async {
    try {
      emit(StadiumLoading());

      final stadium = Stadium(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name.trim(),
        city: city.trim(),
        address: address.trim(),
        capacity: capacity,
        pricePerHour: pricePerHour,
        imageUrls: imageUrls,
        userId: userId ?? _currentUserId,
        latitude: latitude,
        longitude: longitude,
        phoneNumber: phoneNumber?.trim(),
        description: description?.trim(),
        createdAt: fs.Timestamp.now(),
      );

      await stadiumRepo.createStadium(stadium);
      emit(StadiumOperationSuccess('Stadium created successfully'));
      await getAllStadiums(); // Refresh list
    } on StadiumValidationException catch (e) {
      emit(StadiumError(e.message));
    } catch (e) {
      emit(StadiumError('Failed to create stadium: ${e.toString()}'));
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
    } on StadiumNotFoundException catch (e) {
      emit(StadiumError(e.message));
    } catch (e) {
      emit(StadiumError('Failed to get stadium: ${e.toString()}'));
    }
  }

  // Get all stadiums
  Future<void> getAllStadiums() async {
    try {
      emit(StadiumLoading());
      final stadiums = await stadiumRepo.getAllStadiums();
      emit(StadiumsLoaded(stadiums));
    } catch (e) {
      emit(StadiumError('Failed to get stadiums: ${e.toString()}'));
    }
  }

  // Get stadiums by user
  Future<void> getStadiumsByUser(String userId) async {
    try {
      emit(StadiumLoading());
      final stadiums = await stadiumRepo.getStadiumsByUser(userId);
      emit(StadiumsLoaded(stadiums));
    } catch (e) {
      emit(StadiumError('Failed to get stadiums: ${e.toString()}'));
    }
  }

  // Watch all stadiums (stream)
  Stream<List<Stadium>> watchAllStadiums() {
    return stadiumRepo.watchAllStadiums();
  }

  // Update stadium (with security check)
  Future<void> updateStadium(Stadium stadium) async {
    try {
      emit(StadiumLoading());

      // Security check: Verify user owns the stadium
      if (!stadium.isOwner(_currentUserId)) {
        emit(StadiumError('You do not have permission to update this stadium'));
        return;
      }

      await stadiumRepo.updateStadium(stadium);
      emit(StadiumOperationSuccess('Stadium updated successfully'));
      await getAllStadiums(); // Refresh list
    } on StadiumPermissionException catch (e) {
      emit(StadiumError(e.message));
    } on StadiumValidationException catch (e) {
      emit(StadiumError(e.message));
    } catch (e) {
      emit(StadiumError('Failed to update stadium: ${e.toString()}'));
    }
  }

  // Delete stadium (with security check)
  Future<void> deleteStadium(String stadiumId) async {
    try {
      emit(StadiumLoading());

      // Security check: Verify user owns the stadium
      final stadium = await stadiumRepo.getStadium(stadiumId);
      if (stadium == null) {
        emit(StadiumError('Stadium not found'));
        return;
      }

      if (!stadium.isOwner(_currentUserId)) {
        emit(StadiumError('You do not have permission to delete this stadium'));
        return;
      }

      await stadiumRepo.deleteStadium(stadiumId);
      emit(StadiumOperationSuccess('Stadium deleted successfully'));
      await getAllStadiums(); // Refresh list
    } on StadiumPermissionException catch (e) {
      emit(StadiumError(e.message));
    } on StadiumNotFoundException catch (e) {
      emit(StadiumError(e.message));
    } catch (e) {
      emit(StadiumError('Failed to delete stadium: ${e.toString()}'));
    }
  }
}

