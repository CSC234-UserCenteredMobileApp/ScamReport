// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$homeApiHash() => r'9eed5906a7efd640fd6350c7ba25285cce8b5998';

/// See also [homeApi].
@ProviderFor(homeApi)
final homeApiProvider = Provider<HomeApi>.internal(
  homeApi,
  name: r'homeApiProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$homeApiHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HomeApiRef = ProviderRef<HomeApi>;
String _$homeRepositoryHash() => r'2ab8947f5ab9284f4757758acb94b8f18bbdf493';

/// See also [homeRepository].
@ProviderFor(homeRepository)
final homeRepositoryProvider = Provider<HomeRepository>.internal(
  homeRepository,
  name: r'homeRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$homeRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HomeRepositoryRef = ProviderRef<HomeRepository>;
String _$homeStatsHash() => r'9a6090efa8055c11deb8936bfe0fdbc5c24c3045';

/// See also [homeStats].
@ProviderFor(homeStats)
final homeStatsProvider = FutureProvider<HomeStats>.internal(
  homeStats,
  name: r'homeStatsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$homeStatsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HomeStatsRef = FutureProviderRef<HomeStats>;
String _$recentAlertsHash() => r'6bdad792f9f2377d7a0772d6a3092186bea17440';

/// See also [recentAlerts].
@ProviderFor(recentAlerts)
final recentAlertsProvider = FutureProvider<List<RecentAlert>>.internal(
  recentAlerts,
  name: r'recentAlertsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$recentAlertsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RecentAlertsRef = FutureProviderRef<List<RecentAlert>>;
String _$recentReportsHash() => r'0441b12ff0c23eb60ee8a991e9431585d23abc6a';

/// See also [recentReports].
@ProviderFor(recentReports)
final recentReportsProvider = FutureProvider<List<RecentReport>>.internal(
  recentReports,
  name: r'recentReportsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$recentReportsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RecentReportsRef = FutureProviderRef<List<RecentReport>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
