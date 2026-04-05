// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Database)
const databaseProvider = DatabaseProvider._();

final class DatabaseProvider extends $NotifierProvider<Database, AppDatabase> {
  const DatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'databaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$databaseHash();

  @$internal
  @override
  Database create() => Database();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppDatabase>(value),
    );
  }
}

String _$databaseHash() => r'66611f167b3d6000cd3fd2c5fee669210d1228b3';

abstract class _$Database extends $Notifier<AppDatabase> {
  AppDatabase build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AppDatabase, AppDatabase>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AppDatabase, AppDatabase>,
              AppDatabase,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
