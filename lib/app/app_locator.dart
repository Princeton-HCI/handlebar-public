import 'package:get_it/get_it.dart';
import 'package:handlebar/features/crepe/services/collector_service.dart';

import 'package:handlebar/features/research_group/data/research_group_collector_repository.dart';
import 'package:handlebar/features/research_group/data/research_group_membership_repository.dart';
import 'package:handlebar/features/research_group/data/research_group_repository.dart';

import '../core/network/api_client.dart';
import '../core/storage/secure_storage.dart';
import '../core/storage/auth_token_store.dart';
import '../core/shared_services/device_info_service.dart';

import '../features/auth/data/auth_repository.dart';
import '../features/crepe/data/snapshot_repository.dart';
import '../features/crepe/services/crepe_service.dart';
import '../features/terms/data/terms_repository.dart';
import '../features/crepe/data/crepe_event_repository.dart';

final getIt = GetIt.instance;

void setupLocator() {
  // ---------------------------------------------------------------------------
  // 1. CORE SERVICES
  // ---------------------------------------------------------------------------
  getIt.registerLazySingleton<SecureStorage>(() => SecureStorage());
  getIt.registerLazySingleton<DeviceInfoService>(() => DeviceInfoService());
  getIt.registerLazySingleton<CrepeService>(() => CrepeService());
  getIt.registerLazySingleton<CollectorService>(() => CollectorService());

  // AuthTokenStore requires SecureStorage
  getIt.registerLazySingleton<AuthTokenStore>(
      () => AuthTokenStore(getIt<SecureStorage>()));

  // ApiClient requires AuthTokenStore
  getIt.registerLazySingleton<ApiClient>(
      () => ApiClient(getIt<AuthTokenStore>()));

  // ---------------------------------------------------------------------------
  // 2. REPOSITORIES
  // ---------------------------------------------------------------------------
  getIt.registerLazySingleton<AuthRepository>(() => AuthRepository(
        getIt<ApiClient>(),
        getIt<AuthTokenStore>(),
        getIt<SecureStorage>(),
        getIt<DeviceInfoService>(),
      ));

  getIt.registerLazySingleton<TermsRepository>(
      () => TermsRepository(getIt<ApiClient>()));

  getIt.registerLazySingleton<SnapshotRepository>(
      () => SnapshotRepository(getIt<ApiClient>()));

  getIt.registerLazySingleton<CrepeEventRepository>(() => CrepeEventRepository(
        getIt<ApiClient>(),
        getIt<AuthTokenStore>(),
      ));

  getIt.registerLazySingleton<ResearchGroupRepository>(
      () => ResearchGroupRepository(getIt<ApiClient>()));

  getIt.registerLazySingleton<ResearchGroupMembershipRepository>(
      () => ResearchGroupMembershipRepository(getIt<ApiClient>()));

  getIt.registerLazySingleton<ResearchGroupCollectorRepository>(
      () => ResearchGroupCollectorRepository(getIt<ApiClient>()));
}
