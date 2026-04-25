import 'package:get_it/get_it.dart';
import '../../data/repositories/anime_repository_impl.dart';
import '../../domain/repositories/anime_repository.dart';
import '../../data/services/anime_service.dart';
import '../../core/services/log_service.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  getIt.registerLazySingleton<LogService>(() => LogService());
  getIt.registerLazySingleton<AnimeService>(() => AnimeService());
  getIt.registerLazySingleton<AnimeRepository>(
    () => AnimeRepositoryImpl(getIt<AnimeService>()),
  );
}