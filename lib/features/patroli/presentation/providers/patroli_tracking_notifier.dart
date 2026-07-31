import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'patroli_foreground_task.dart';

class PatroliTrackingState {
  final bool isActive;
  final int? patroliId;
  final List<LatLng> points;

  const PatroliTrackingState({
    this.isActive = false,
    this.patroliId,
    this.points = const [],
  });

  PatroliTrackingState copyWith({
    bool? isActive,
    int? patroliId,
    List<LatLng>? points,
  }) {
    return PatroliTrackingState(
      isActive: isActive ?? this.isActive,
      patroliId: patroliId ?? this.patroliId,
      points: points ?? this.points,
    );
  }
}

class PatroliTrackingNotifier extends StateNotifier<PatroliTrackingState> {
  final ApiClient _api;
  Timer? _timer;

  PatroliTrackingNotifier(this._api) : super(const PatroliTrackingState());

  Future<void> start(
    int patroliId,
    int intervalSeconds, {
    List<LatLng> existingPoints = const [],
    String kode = 'Patroli',
  }) async {
    if (state.isActive) return;
    state = PatroliTrackingState(
      isActive: true,
      patroliId: patroliId,
      points: List.of(existingPoints),
    );
    await startPatroliForegroundService(kode);
    _recordPoint(); // rekam titik pertama segera
    _timer = Timer.periodic(
      Duration(seconds: intervalSeconds),
      (_) => _recordPoint(),
    );
  }

  Future<void> _recordPoint() async {
    if (!state.isActive || state.patroliId == null) return;
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
      final now = DateTime.now().toUtc();
      final nowStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')} '
          '${now.hour.toString().padLeft(2, '0')}:'
          '${now.minute.toString().padLeft(2, '0')}:'
          '${now.second.toString().padLeft(2, '0')}';

      await _api.callKw(
        model: 'digital_kamtibmas.patroli_titik',
        method: 'create',
        args: [
          {
            'patroli_id': state.patroliId,
            'latitude': pos.latitude,
            'longitude': pos.longitude,
            'waktu_rekam': nowStr,
          }
        ],
      );

      if (state.isActive) {
        final newPoints = [...state.points, LatLng(pos.latitude, pos.longitude)];
        state = state.copyWith(points: newPoints);
        updatePatroliForegroundNotification(newPoints.length);
      }
    } catch (_) {
      // Non-fatal: coba lagi di interval berikutnya
    }
  }

  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    final id = state.patroliId;
    state = const PatroliTrackingState();
    await stopPatroliForegroundService();
    if (id != null) {
      try {
        await _api.callKw(
          model: 'digital_kamtibmas.patroli',
          method: 'action_selesai',
          args: [
            [id]
          ],
        );
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final patroliTrackingProvider =
    StateNotifierProvider<PatroliTrackingNotifier, PatroliTrackingState>((ref) {
  return PatroliTrackingNotifier(ref.watch(apiClientProvider));
});
