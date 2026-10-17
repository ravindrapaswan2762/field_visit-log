import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/database/app_database.dart';
import 'core/network/api_client.dart';
import 'core/network/connectivity_service.dart';
import 'core/theme/app_theme.dart';
import 'features/visits/data/datasources/visit_local_datasource.dart';
import 'features/visits/data/datasources/visit_remote_datasource.dart';
import 'features/visits/data/repositories/visit_repository_impl.dart';
import 'features/visits/domain/usecases/create_visit.dart';
import 'features/visits/domain/usecases/get_visit_details.dart';
import 'features/visits/domain/usecases/get_visits.dart';
import 'features/visits/domain/usecases/sync_pending_visits.dart';
import 'features/visits/presentation/providers/visit_provider.dart';
import 'routing/app_router.dart';

class FieldVisitApp extends StatelessWidget {
  const FieldVisitApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Dependency wiring — kept in one place for clarity.
    // In a larger project, use a DI framework like get_it.
    final db = AppDatabase.instance;
    final local = VisitLocalDatasource(db: db);
    final remote = VisitRemoteDatasource(apiClient: ApiClient());
    final repo = VisitRepositoryImpl(
      localDatasource: local,
      remoteDatasource: remote,
    );
    final connectivityService = ConnectivityService();

    return ChangeNotifierProvider(
      create: (_) => VisitProvider(
        getVisits: GetVisits(repo),
        createVisit: CreateVisit(repo),
        getVisitDetails: GetVisitDetails(repo),
        syncPendingVisits: SyncPendingVisits(repo),
        connectivityService: connectivityService,
      ),
      child: MaterialApp(
        title: 'Field Visit Log',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        debugShowCheckedModeBanner: false,
        onGenerateRoute: AppRouter.onGenerateRoute,
        initialRoute: AppRouter.visitList,
      ),
    );
  }
}
