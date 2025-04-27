import 'package:get_it/get_it.dart';
import '../../data/repositories/anime_repository_impl.dart';
import '../../domain/repositories/anime_repository.dart';
import '../../data/services/anime_service.dart';
import '../../presentation/providers/anime_provider.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  // Services
  getIt.registerLazySingleton<AnimeService>(() => AnimeService());

  // Repositories
  getIt.registerLazySingleton<AnimeRepository>(
    () => AnimeRepositoryImpl(getIt<AnimeService>()),
  );

  // Providers
  getIt.registerFactory(() => AnimeProvider(getIt<AnimeRepository>()));
}
