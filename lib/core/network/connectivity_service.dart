import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connectivity_service.g.dart';

@riverpod
class ConnectivityService extends _$ConnectivityService {
  @override
  Stream<bool> build() {
    return Connectivity().onConnectivityChanged.map((results) {
      return !results.contains(ConnectivityResult.none);
    });
  }
}
