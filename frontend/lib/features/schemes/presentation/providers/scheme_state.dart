import 'package:equatable/equatable.dart';
import '../../domain/entities/scheme.dart';

enum SchemeStatus { initial, loading, loaded, detailsLoading, detailsLoaded, saving, saved, error }

class SchemeState extends Equatable {
  final SchemeStatus status;
  final List<Scheme> schemes;
  final Scheme? selectedScheme;
  final String? errorMessage;

  const SchemeState({
    required this.status,
    required this.schemes,
    this.selectedScheme,
    this.errorMessage,
  });

  factory SchemeState.initial() {
    return const SchemeState(status: SchemeStatus.initial, schemes: []);
  }

  factory SchemeState.loading() {
    return const SchemeState(status: SchemeStatus.loading, schemes: []);
  }

  factory SchemeState.loaded(List<Scheme> schemes) {
    return SchemeState(status: SchemeStatus.loaded, schemes: schemes);
  }

  factory SchemeState.error(String message) {
    return SchemeState(
      status: SchemeStatus.error,
      schemes: const [],
      errorMessage: message,
    );
  }

  SchemeState copyWith({
    SchemeStatus? status,
    List<Scheme>? schemes,
    Scheme? selectedScheme,
    String? errorMessage,
  }) {
    return SchemeState(
      status: status ?? this.status,
      schemes: schemes ?? this.schemes,
      selectedScheme: selectedScheme ?? this.selectedScheme,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, schemes, selectedScheme, errorMessage];
}
