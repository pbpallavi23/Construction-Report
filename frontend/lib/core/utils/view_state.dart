import '../network/api_failure.dart';

enum ViewStatus { idle, loading, success, error }

class ViewState<T> {
  const ViewState._(this.status, {this.data, this.failure});

  final ViewStatus status;
  final T? data;
  final ApiFailure? failure;

  const ViewState.idle() : this._(ViewStatus.idle);
  const ViewState.loading() : this._(ViewStatus.loading);
  const ViewState.success(T data) : this._(ViewStatus.success, data: data);
  const ViewState.error(ApiFailure failure)
      : this._(ViewStatus.error, failure: failure);

  bool get isLoading => status == ViewStatus.loading;
  bool get isSuccess => status == ViewStatus.success;
  bool get isError => status == ViewStatus.error;
  bool get isIdle => status == ViewStatus.idle;

  bool get hasData => data != null;
}
