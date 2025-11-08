import 'package:handlebar/features/research_group/data/research_group_collector_repository.dart';
import 'package:handlebar/features/research_group/data/research_group_membership_repository.dart';
import 'package:handlebar/features/research_group/data/research_group_repository.dart';

import '../core/network/api_client.dart';
import '../core/storage/secure_storage.dart';
import '../core/storage/auth_token_store.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/terms/data/terms_repository.dart';
import '../features/crepe/data/crepe_event_repository.dart';
import '../core/shared_services/device_info_service.dart';

/// Mini DI for now

final secureStorage = SecureStorage();
final tokens = AuthTokenStore(secureStorage);
final apiClient = ApiClient(tokens);
final deviceInfo = DeviceInfoService();

final authRepo = AuthRepository(apiClient, tokens, secureStorage, deviceInfo);
final termsRepo = TermsRepository(apiClient);
final crepeRepo = CrepeEventRepository(apiClient, tokens);
final groupRepo = ResearchGroupRepository(apiClient);
final membershipRepo = ResearchGroupMembershipRepository(apiClient);
final rgCollectorRepo = ResearchGroupCollectorRepository(apiClient);
