import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:bloc/bloc.dart';
import 'package:fluttercon/common/data/enums/bookmark_status.dart';
import 'package:fluttercon/common/repository/api_repository.dart';
import 'package:fluttercon/common/repository/db_repository.dart';
import 'package:fluttercon/common/utils/notification_service.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'bookmark_session_state.dart';
part 'bookmark_session_cubit.freezed.dart';

class BookmarkSessionCubit extends Cubit<BookmarkSessionState> {
  BookmarkSessionCubit({
    required ApiRepository apiRepository,
    required DBRepository dBRepository,
  }) : super(const BookmarkSessionState.initial()) {
    _apiRepository = apiRepository;
    _dBRepository = dBRepository;
  }

  late ApiRepository _apiRepository;
  late DBRepository _dBRepository;

  Future<void> bookmarkSession({
    required int sessionId,
    int? index,
  }) async {
    try {
      emit(BookmarkSessionState.loading(index: index));
      final message = await _apiRepository.bookmarkSession(sessionId);

      final bookmarkStatus = BookmarkStatus.fromString(message);

      await _dBRepository.updateSession(
        sessionId: sessionId,
        bookmarkStatus: bookmarkStatus == BookmarkStatus.bookmarked,
      );

      if (bookmarkStatus == BookmarkStatus.bookmarked) {
        final session = await _dBRepository.getSession(sessionId);
        final endTime = session?.endDateTime;
        final notifcationTime = endTime?.subtract(const Duration(minutes: 5));

        await NotificationService().createScheduledNotification(
          id: sessionId,
          channelKey: 'session_channel',
          title: '${session?.title} feedback',
          body: 'Please provide feedback for the session you ${session?.title} '
              'just attended',
          notificationTime: notifcationTime,
        );
      }
      emit(
        BookmarkSessionState.loaded(
          message: message,
          status: bookmarkStatus,
        ),
      );
    } catch (e) {
      emit(BookmarkSessionState.error(e.toString()));
    }
  }
}
