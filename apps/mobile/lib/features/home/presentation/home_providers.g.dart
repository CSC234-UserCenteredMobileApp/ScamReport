// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$homeApiHash() => r'4205b497b145d9ea11dc6f07687a1fb3eeb2ae95';

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
String _$homeRepositoryHash() => r'4bca507a74381fe38d30de02855a9339fe041f25';

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
String _$homeStatsHash() => r'e4a30e686cc314ef1fa5b9ee55454468f7e61c11';

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
String _$recentAlertsHash() => r'22d141e44c502c1b413cfae1165dbdd54f46a145';

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
String _$recentReportsHash() => r'b36e63ce3a5cbdab8840bf3d1e5ef050f8f4363c';

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
