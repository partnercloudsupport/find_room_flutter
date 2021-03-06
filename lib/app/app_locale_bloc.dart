import 'dart:ui';

import 'package:find_room/bloc/bloc_provider.dart';
import 'package:find_room/shared_pref_util.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tuple/tuple.dart';

final supportedLocaleTitles = <Locale, String>{
  const Locale('en', ''): 'English - en',
  const Locale('vi', ''): 'Tiếng Việt - vi',
};

///
/// BLoC handling change [Locale] and get stream of [Locale]s
/// Used to support multi language in app
///
class LocaleBloc implements BaseBloc {
  ///
  /// Sinks
  ///
  final Sink<Locale> changeLocale;

  ///
  /// Streams
  ///
  final ValueObservable<Locale> locale$;

  ///
  /// [Tuple2] with [Tuple2.item1] is result (true for successfully, false for failure),
  /// [Tuple2.item2] is error (nullable)
  ///
  final Stream<Tuple2<bool, Object>> changeLocaleResult$;

  ///
  /// Clean up
  ///
  final void Function() _dispose;

  LocaleBloc._(
    this.changeLocale,
    this.locale$,
    this._dispose,
    this.changeLocaleResult$,
  );

  factory LocaleBloc(SharedPrefUtil sharePrefUtil) {
    assert(sharePrefUtil != null, 'sharePrefUtil cannot be null');

    final changeLocaleController = PublishSubject<Locale>(sync: true);
    final localeController = BehaviorSubject<Locale>(sync: true);

    final changeLocaleResult$ =
        changeLocaleController.distinct().switchMap((locale) {
      return Observable.fromFuture(
              sharePrefUtil.saveSelectedLanguageCode(locale.languageCode))
          .map((result) => Tuple2(result, null))
          .onErrorReturnWith((e) => Tuple2(false, e));
    }).publish();

    final listen = (Locale locale) {
      ///
      /// listen, if not equal, then add to controller
      ///
      if (locale != localeController.value) {
        print('[DEBUG] Real change locale $locale :v');
        localeController.add(locale);
      }
    };

    final subscriptions = [
      sharePrefUtil.selectedLanguageCode$
          .map((code) => Locale(code, ''))
          .listen(listen),
      changeLocaleResult$.connect(),
    ];

    return LocaleBloc._(
      changeLocaleController.sink,
      localeController.stream,
      () {
        changeLocaleController.close();
        localeController.close();
        subscriptions.forEach((s) => s.cancel());
      },
      changeLocaleResult$,
    );
  }

  @override
  void dispose() => _dispose();
}
