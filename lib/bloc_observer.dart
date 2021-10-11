import 'package:bloc/bloc.dart';

class BlocErrorObservedEvent {
  final BlocBase bloc;
  final Object error;
  final StackTrace stackTrace;

  const BlocErrorObservedEvent(this.bloc, this.error, this.stackTrace);
}

abstract class BlocErrorBlocState {
  const BlocErrorBlocState();
}

class NoError extends BlocErrorBlocState {}

class ErrorObserved extends BlocErrorBlocState {
  final BlocBase bloc;
  final Object error;
  final StackTrace stackTrace;

  const ErrorObserved(this.bloc, this.error, this.stackTrace);
}

class BlocErrorBloc extends Bloc<BlocErrorObservedEvent, BlocErrorBlocState> {
  BlocErrorBloc() : super(NoError());

  @override
  Stream<BlocErrorBlocState> mapEventToState(
    BlocErrorObservedEvent event,
  ) async* {
    yield ErrorObserved(event.bloc, event.error, event.stackTrace);
  }
}

class SimpleBlocObserver extends BlocObserver {
  final BlocErrorBloc errorBloc;

  SimpleBlocObserver(this.errorBloc);

  @override
  void onEvent(Bloc bloc, Object? event) {
    print('eventObserved: $event');
    super.onEvent(bloc, event);
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    print('transitionObserved: $transition');
    super.onTransition(bloc, transition);
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    print('errorObserved: $error');
    errorBloc.add(BlocErrorObservedEvent(bloc, error, stackTrace));
    super.onError(bloc, error, stackTrace);
  }
}
