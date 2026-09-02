import 'package:get_it/get_it.dart';
import 'package:handlebar/features/crepe/services/collector_service.dart';
import 'package:handlebar/features/home/presentation/view_models/participant_home_view_model.dart';
import 'package:handlebar/features/settings/presentation/view_models/participant_settings_view_model.dart';

import 'package:handlebar/features/research_group/data/research_group_collector_repository.dart';
import 'package:handlebar/features/research_group/data/research_group_membership_repository.dart';
import 'package:handlebar/features/research_group/data/research_group_repository.dart';
import 'package:handlebar/features/auth/presentation/view_models/create_study_view_model.dart';

import '../core/network/api_client.dart';
import '../core/storage/secure_storage.dart';
import '../core/storage/auth_token_store.dart';
import '../core/shared_services/device_info_service.dart';

import '../features/auth/data/auth_repository.dart';
import '../features/auth/presentation/view_models/login_viewmodel.dart';
import '../features/auth/presentation/view_models/signup_viewmodel.dart';
import '../features/crepe/data/snapshot_repository.dart';
import '../features/crepe/presentation/view_models/accessibility_view_model.dart';
import '../features/crepe/services/crepe_service.dart';
import '../features/home/presentation/view_models/researcher_home_view_model.dart';
import '../features/terms/data/terms_repository.dart';
import '../features/crepe/data/crepe_event_repository.dart';
import '../features/terms/presentation/view_models/terms_view_model.dart';

final getIt = GetIt.instance;

void setupLocator() {
  // ---------------------------------------------------------------------------
  // CORE SERVICES
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
  // REPOSITORIES
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

  // ---------------------------------------------------------------------------
  // VIEWMODELS
  // ---------------------------------------------------------------------------

  getIt.registerFactory(() => SignupViewModel(
        authRepo: getIt(),
        authStore: getIt(),
        groupRepo: getIt(),
        crepeService: getIt(),
      ));

  getIt.registerFactory(() => LoginViewModel(
        authRepo: getIt(),
        authStore: getIt(),
        termsRepo: getIt(),
        crepeService: getIt(),
      ));

  getIt.registerFactory(() => TermsViewModel(
        authRepo: getIt(),
        termsRepo: getIt(),
      ));

  getIt.registerFactory(() => AccessibilityViewModel(
        authRepo: getIt(),
        crepeService: getIt(),
      ));

  getIt.registerFactory(() => ResearcherHomeViewModel(rgRepo: getIt()));

  getIt.registerFactory(() => CreateStudyViewModel(rgRepo: getIt()));

  getIt.registerFactory(() => ParticipantHomeViewModel(rgRepo: getIt()));

  getIt.registerFactory(() => ParticipantSettingsViewModel(
        getIt<SecureStorage>(),
        getIt<CrepeService>(),
      ));
}
