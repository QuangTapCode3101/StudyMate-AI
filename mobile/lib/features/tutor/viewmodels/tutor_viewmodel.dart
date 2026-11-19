import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../models/tutor_models.dart';
import '../repositories/tutor_repository.dart';
import '../services/citation_mapper.dart';
import '../services/connection_status.dart';
import '../services/internet_probe.dart';
import '../services/sse_event_parser.dart';
import '../services/sse_stream_client.dart';

/// ViewModel của màn hình AI Tutor (SCR-05), gồm:
///  - TASK-401: chọn ngữ cảnh Môn học • Chủ đề, quản lý phiên chat, lưu SQLite.
///  - TASK-402: gửi Quick Action / câu hỏi, nhận chữ chạy dần qua SSE, lưu khi done,
///    xử lý mất mạng và HTTP 429 (có nút Thử lại).
///  - TASK-403: gọi API sinh Mini-Quiz 3 câu cho MDL-02.
class TutorViewModel extends ChangeNotifier {
  TutorViewModel({
    TutorRepository? repository,
    SseStreamClient? sseClient,
    Future<bool> Function()? internetProbe,
    this.useMock = false,
  })  : _repository = repository ?? TutorRepository(),
        _sseClient = sseClient ?? SseStreamClient(),
        _internetProbe = internetProbe ?? hasInternetAccess;

  final TutorRepository _repository;
  final SseStreamClient _sseClient;
  final Future<bool> Function() _internetProbe;

  /// Bật để gửi header X-Mock-Mode: true (Backend trả dữ liệu giả, không tốn quota Gemini).
  final bool useMock;

  static const int _maxHistoryMessages = 6;
  static const int _maxSessionTitleLength = 40;
  static const Duration _connectionCheckInterval = Duration(seconds: 15);

  // --- Trạng thái hiển thị ---------------------------------------------------
  List<TutorContext> _topics = [];
  TutorContext? _topicContext;
  List<SourceChunkModel> _sourceChunks = [];
  List<ChatSessionModel> _sessions = [];
  ChatSessionModel? _session;
  List<ChatMessageModel> _messages = [];

  bool _isLoading = true;
  bool _isStreaming = false;
  TutorActionMode? _selectedMode;
  String? _errorMessage;
  bool _canRetry = false;

  int _remainingQuota = 20;
  int _maxQuota = 20;
  TutorConnectionStatus _connection = TutorConnectionStatus.checking;
  bool _isCheckingConnection = false;
  Timer? _connectionTimer;

  // --- Trạng thái nội bộ -----------------------------------------------------
  StreamSubscription<TutorStreamEvent>? _subscription;
  Completer<void>? _streamCompleter;
  int _streamToken = 0;
  int? _selectingTopicId;
  TutorActionMode? _pendingMode;
  String? _pendingPrompt;
  bool _disposed = false;
  bool _isStopping = false;
  bool _isResending = false;

  List<TutorContext> get topics => _topics;
  TutorContext? get topicContext => _topicContext;
  List<ChatSessionModel> get sessions => _sessions;
  ChatSessionModel? get currentSession => _session;
  List<ChatMessageModel> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isStreaming => _isStreaming;
  TutorActionMode? get selectedMode => _selectedMode;
  String? get errorMessage => _errorMessage;
  bool get canRetry => _canRetry;
  int get remainingQuota => _remainingQuota;
  int get maxQuota => _maxQuota;
  bool get isBackendOnline => _connection == TutorConnectionStatus.online;
  TutorConnectionStatus get connectionStatus => _connection;
  bool get isCheckingConnection => _isCheckingConnection;

  /// Mất mạng / Backend không chạy thì khóa mọi thao tác cần gọi AI.
  bool get isAiAvailable => _connection.isAiAvailable;

  /// Chỉ cho bấm nút Dừng khi bong bóng AI đã xuất hiện (luồng đã bắt đầu chạy).
  bool get canStop =>
      _isStreaming && !_isStopping && _messages.any((m) => m.isStreaming);

  /// Vị trí câu hỏi MỚI NHẤT của người dùng nếu đang được phép sửa, -1 nếu không.
  /// Chỉ sửa câu mới nhất, vì sửa câu ở giữa sẽ làm các câu trả lời phía sau mất ý nghĩa.
  int get editableMessageIndex {
    if (_isStreaming || _isLoading || _isResending || _session == null) {
      return -1;
    }
    for (var i = _messages.length - 1; i >= 0; i--) {
      final message = _messages[i];
      if (message.isUser) {
        return message.id == null ? -1 : i;
      }
    }
    return -1;
  }

  /// Vị trí tin nhắn AI cuối cùng đã hoàn tất (để gắn nút Kiểm tra nhanh 3 câu), -1 nếu chưa có.
  int get latestAiMessageIndex {
    for (var i = _messages.length - 1; i >= 0; i--) {
      final message = _messages[i];
      if (message.isAi && !message.isStreaming && message.content.isNotEmpty) {
        return i;
      }
    }
    return -1;
  }

  // ===========================================================================
  // TASK-401: khởi tạo, chọn chủ đề, quản lý phiên chat
  // ===========================================================================

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      _topics = await _repository.getAllTopicContexts();
      await _selectDefaultTopicIfNeeded();
    } catch (e) {
      debugPrint('Lỗi đọc danh sách chủ đề cho AI Tutor: $e');
    }

    if (_selectingTopicId == null) {
      _isLoading = false;
      notifyListeners();
    }
    unawaited(checkConnection());
    _connectionTimer ??= Timer.periodic(_connectionCheckInterval, (_) {
      if (!_isStreaming && !_isLoading) {
        unawaited(checkConnection());
      }
    });
  }

  /// Tải lại danh sách chủ đề (M2 có thể vừa thêm học liệu mới ở tab Thư viện).
  Future<void> refreshTopics() async {
    try {
      _topics = await _repository.getAllTopicContexts();
      final current = _topicContext;
      if (current != null) {
        final stillExists = _topics.any((t) => t.topicId == current.topicId);
        if (stillExists) {
          _sourceChunks =
              await _repository.getSourceChunksForTopic(current.topicId);
        } else {
          _topicContext = null;
          _sourceChunks = [];
          _sessions = [];
          _session = null;
          _messages = [];
        }
      }
      await _selectDefaultTopicIfNeeded();
    } catch (e) {
      debugPrint('Lỗi tải lại chủ đề: $e');
    }
    notifyListeners();
  }

  Future<void> _selectDefaultTopicIfNeeded() async {
    if (_topicContext != null || _selectingTopicId != null || _topics.isEmpty) {
      return;
    }
    final lastUsed = await _repository.getLastUsedTopicId();
    final defaultTopicId =
        (lastUsed != null && _topics.any((t) => t.topicId == lastUsed))
            ? lastUsed
            : _topics.first.topicId;

    // Kiểm tra lại vì trong lúc chờ có thể đã có chủ đề được chọn từ Home / Thư viện.
    if (_topicContext == null && _selectingTopicId == null) {
      await selectTopic(defaultTopicId);
    }
  }

  /// Chuyển sang chủ đề khác: tải phiên chat gần nhất của chủ đề đó từ SQLite.
  Future<void> selectTopic(int topicId) async {
    if (_topicContext?.topicId == topicId || _selectingTopicId == topicId) {
      return;
    }

    _selectingTopicId = topicId;
    _isLoading = true;
    await _cancelStreaming();
    notifyListeners();

    try {
      final context = await _repository.getTopicContext(topicId);
      if (context == null) {
        _selectingTopicId = null;
        _isLoading = false;
        notifyListeners();
        return;
      }

      final chunks = await _repository.getSourceChunksForTopic(topicId);
      final sessions = await _repository.getSessionsByTopic(topicId);
      final latest = sessions.isEmpty ? null : sessions.first;
      final messages = latest == null
          ? <ChatMessageModel>[]
          : await _repository.getMessages(latest.id!);

      // Nếu trong lúc tải người dùng đã chọn chủ đề khác thì bỏ kết quả này.
      if (_selectingTopicId != topicId || _disposed) {
        return;
      }

      _topicContext = context;
      _sourceChunks = chunks;
      _sessions = sessions;
      _session = latest;
      _messages = messages;
      _selectedMode = null;
      _errorMessage = null;
      _canRetry = false;
      _pendingMode = null;
      _pendingPrompt = null;
    } catch (e) {
      debugPrint('Lỗi tải chủ đề $topicId: $e');
    }

    if (_selectingTopicId == topicId) {
      _selectingTopicId = null;
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Làm mới danh sách phiên (cập nhật số tin nhắn) trước khi mở MDL-03.
  Future<void> refreshSessions() async {
    final topicId = _topicContext?.topicId;
    if (topicId == null) {
      return;
    }
    _sessions = await _repository.getSessionsByTopic(topicId);
    notifyListeners();
  }

  /// Bắt đầu cuộc trò chuyện mới. Phiên chỉ được tạo trong SQLite khi gửi tin đầu tiên
  /// để không sinh ra các phiên rỗng.
  Future<void> startNewSession() async {
    if (_topicContext == null) {
      return;
    }
    await _cancelStreaming();
    _session = null;
    _messages = [];
    _selectedMode = null;
    _errorMessage = null;
    _canRetry = false;
    _pendingMode = null;
    _pendingPrompt = null;
    notifyListeners();
  }

  Future<void> openSession(int sessionId) async {
    final index = _sessions.indexWhere((s) => s.id == sessionId);
    if (index < 0) {
      return;
    }
    await _cancelStreaming();
    final messages = await _repository.getMessages(sessionId);
    _session = _sessions[index];
    _messages = messages;
    _selectedMode = null;
    _errorMessage = null;
    _canRetry = false;
    _pendingMode = null;
    _pendingPrompt = null;
    notifyListeners();
  }

  Future<void> deleteSession(int sessionId) async {
    final topicId = _topicContext?.topicId;
    if (topicId == null) {
      return;
    }

    final isCurrent = _session?.id == sessionId;
    if (isCurrent) {
      await _cancelStreaming();
    }
    await _repository.deleteSession(sessionId);
    _sessions = await _repository.getSessionsByTopic(topicId);

    if (isCurrent) {
      if (_sessions.isEmpty) {
        _session = null;
        _messages = [];
      } else {
        final next = _sessions.first;
        _session = next;
        _messages = await _repository.getMessages(next.id!);
      }
      _errorMessage = null;
      _canRetry = false;
      _pendingMode = null;
      _pendingPrompt = null;
    }
    notifyListeners();
  }

  /// Xóa toàn bộ lịch sử chat của chủ đề đang chọn.
  Future<void> clearTopicHistory() async {
    final topicId = _topicContext?.topicId;
    if (topicId == null) {
      return;
    }
    await _cancelStreaming();
    await _repository.deleteAllSessionsOfTopic(topicId);
    _sessions = [];
    _session = null;
    _messages = [];
    _selectedMode = null;
    _errorMessage = null;
    _canRetry = false;
    _pendingMode = null;
    _pendingPrompt = null;
    notifyListeners();
  }

  // ===========================================================================
  // TASK-402: gửi câu hỏi và nhận luồng SSE
  // ===========================================================================

  Future<void> sendQuickAction(TutorActionMode mode) async {
    final context = _topicContext;
    if (context == null || _isStreaming) {
      return;
    }
    _selectedMode = mode;
    await _send(
      mode: mode,
      prompt: mode.defaultPrompt(context.topicName),
      sessionTitle: mode.label,
    );
  }

  Future<void> sendUserMessage(String text) async {
    final prompt = text.trim();
    if (prompt.isEmpty || _topicContext == null || _isStreaming) {
      return;
    }
    _selectedMode = null;
    // Câu hỏi tự do dùng chế độ giải thích cơ bản.
    await _send(
      mode: TutorActionMode.basic,
      prompt: prompt,
      sessionTitle: _titleFromPrompt(prompt),
    );
  }

  String _titleFromPrompt(String prompt) {
    return prompt.length > _maxSessionTitleLength
        ? '${prompt.substring(0, _maxSessionTitleLength)}…'
        : prompt;
  }

  /// Sửa câu hỏi mới nhất rồi hỏi lại AI.
  /// Câu hỏi cũ và câu trả lời cũ của AI (nếu có) bị xóa khỏi lịch sử,
  /// sau đó [text] được gửi đi như một câu hỏi mới.
  Future<void> editLastQuestion(String text) async {
    // Kiểm tra kết nối trước khi xóa gì, để mất mạng thì không làm mất câu hỏi cũ.
    if (!await _ensureAiAvailable()) {
      return;
    }
    final prompt = text.trim();
    final index = editableMessageIndex;
    final session = _session;
    if (prompt.isEmpty || index < 0 || session == null) {
      return;
    }

    final target = _messages[index];
    _isResending = true;
    try {
      await _repository.deleteMessagesFrom(
        sessionId: session.id!,
        messageId: target.id!,
      );

      // Câu đầu tiên của phiên đang làm tên phiên trong lịch sử, cập nhật theo câu mới.
      if (index == 0) {
        final title = _titleFromPrompt(prompt);
        await _repository.updateSessionTitle(session.id!, title);
        final renamed = session.copyWith(title: title);
        _session = renamed;
        _sessions = _sessions
            .map((s) => s.id == renamed.id ? renamed : s)
            .toList();
      }
    } catch (e) {
      debugPrint('Lỗi sửa câu hỏi: $e');
      _isResending = false;
      _errorMessage = 'Không sửa được câu hỏi. Vui lòng thử lại.';
      _canRetry = false;
      notifyListeners();
      return;
    }

    _messages = _messages.sublist(0, index);
    _selectedMode = null;
    _errorMessage = null;
    _canRetry = false;
    _pendingMode = null;
    _pendingPrompt = null;
    _isResending = false;
    notifyListeners();

    await _send(
      mode: TutorActionMode.basic,
      prompt: prompt,
      sessionTitle: _titleFromPrompt(prompt),
    );
  }

  /// Gửi lại yêu cầu vừa thất bại (mất mạng, timeout, HTTP 429...).
  /// Không lưu lại tin nhắn người dùng lần nữa vì đã lưu từ lần gửi đầu.
  Future<void> retry() async {
    final mode = _pendingMode;
    final prompt = _pendingPrompt;
    final session = _session;
    if (mode == null ||
        prompt == null ||
        session == null ||
        _isStreaming ||
        _topicContext == null) {
      return;
    }
    if (!await _ensureAiAvailable()) {
      return;
    }
    if (_isStreaming) {
      return;
    }
    _errorMessage = null;
    _canRetry = false;
    await _startStream(mode: mode, prompt: prompt, session: session);
  }

  void dismissError() {
    _errorMessage = null;
    _canRetry = false;
    notifyListeners();
  }

  Future<void> _send({
    required TutorActionMode mode,
    required String prompt,
    required String sessionTitle,
  }) async {
    final context = _topicContext;
    if (context == null || _isStreaming) {
      return;
    }

    if (!await _ensureAiAvailable()) {
      _selectedMode = null;
      notifyListeners();
      return;
    }
    // Trong lúc chờ kiểm tra kết nối có thể đã có thao tác gửi khác.
    if (_isStreaming || _topicContext == null) {
      return;
    }

    // Khóa ngay từ đầu để bấm liên tiếp không gửi trùng.
    _isStreaming = true;
    _errorMessage = null;
    _canRetry = false;
    notifyListeners();

    final token = _streamToken;
    final ChatSessionModel session;
    try {
      session = await _ensureSession(context, sessionTitle);
      final saved = await _repository.insertMessage(
        ChatMessageModel(
          sessionId: session.id!,
          role: ChatMessageModel.roleUser,
          content: prompt,
          createdAt: DateTime.now().toIso8601String(),
        ),
      );
      if (token != _streamToken || _disposed) {
        return;
      }
      _messages = [..._messages, saved];
    } catch (e) {
      debugPrint('Lỗi lưu tin nhắn người dùng: $e');
      if (token == _streamToken) {
        _isStreaming = false;
        _errorMessage =
            'Không lưu được tin nhắn vào bộ nhớ máy. Vui lòng thử lại.';
        _canRetry = false;
        notifyListeners();
      }
      return;
    }

    _pendingMode = mode;
    _pendingPrompt = prompt;
    await _startStream(mode: mode, prompt: prompt, session: session);
  }

  Future<ChatSessionModel> _ensureSession(
    TutorContext context,
    String title,
  ) async {
    final existing = _session;
    if (existing != null) {
      return existing;
    }
    final created = await _repository.createSession(
      subjectId: context.subjectId,
      topicId: context.topicId,
      title: title,
    );
    _session = created;
    _sessions = [created, ..._sessions];
    return created;
  }

  Future<void> _startStream({
    required TutorActionMode mode,
    required String prompt,
    required ChatSessionModel session,
  }) async {
    final context = _topicContext;
    if (context == null) {
      return;
    }

    final token = ++_streamToken;
    _isStreaming = true;
    _errorMessage = null;
    _canRetry = false;

    final history = _buildChatHistory(prompt);

    // Bong bóng AI rỗng để chữ chạy dần được nối vào.
    _messages = [
      ..._messages,
      ChatMessageModel(
        sessionId: session.id!,
        role: ChatMessageModel.roleAi,
        content: '',
        createdAt: DateTime.now().toIso8601String(),
        isStreaming: true,
      ),
    ];
    notifyListeners();

    final body = <String, dynamic>{
      'subjectName': context.subjectName,
      'programmingLanguage': context.programmingLanguage,
      'topicName': context.topicName,
      'actionMode': mode.apiValue,
      'userPrompt': prompt,
      'sourceChunks': _sourceChunks.map((c) => c.toRequestJson()).toList(),
      'chatHistory': history,
    };

    final buffer = StringBuffer();
    final completer = Completer<void>();
    _streamCompleter = completer;
    var doneSeen = false;

    void finish() {
      if (!completer.isCompleted) {
        completer.complete();
      }
    }

    _subscription = _sseClient.streamTutor(body, useMock: useMock).listen(
      (event) {
        if (token != _streamToken) {
          return;
        }
        if (event is TutorChunkEvent) {
          buffer.write(event.text);
          _updateStreamingMessage(buffer.toString());
        } else if (event is TutorDoneEvent) {
          doneSeen = true;
          _completeStream(
            token: token,
            session: session,
            content: buffer.toString(),
            done: event,
          ).whenComplete(finish);
        }
      },
      onError: (Object error) {
        if (token == _streamToken) {
          _failStream(error);
        }
        finish();
      },
      onDone: () {
        if (!doneSeen) {
          finish();
        }
      },
      cancelOnError: true,
    );

    await completer.future;
  }

  List<Map<String, String>> _buildChatHistory(String currentPrompt) {
    final persisted = _messages
        .where((m) => !m.isStreaming && m.content.trim().isNotEmpty)
        .toList();
    // Bỏ chính câu hỏi hiện tại vì nó đã được gửi riêng ở userPrompt.
    if (persisted.isNotEmpty &&
        persisted.last.isUser &&
        persisted.last.content == currentPrompt) {
      persisted.removeLast();
    }
    final start = persisted.length > _maxHistoryMessages
        ? persisted.length - _maxHistoryMessages
        : 0;
    return persisted
        .sublist(start)
        .map((m) => {'role': m.role, 'content': m.content})
        .toList();
  }

  void _updateStreamingMessage(String content) {
    final index = _messages.lastIndexWhere((m) => m.isStreaming);
    if (index < 0) {
      return;
    }
    final updated = List<ChatMessageModel>.of(_messages);
    updated[index] = updated[index].copyWith(content: content);
    _messages = updated;
    notifyListeners();
  }

  Future<void> _completeStream({
    required int token,
    required ChatSessionModel session,
    required String content,
    required TutorDoneEvent done,
  }) async {
    try {
      final saved = await _repository.insertMessage(
        ChatMessageModel(
          sessionId: session.id!,
          role: ChatMessageModel.roleAi,
          content: content.trim().isEmpty
              ? 'AI chưa trả về nội dung. Hãy thử lại.'
              : content,
          citations: mapCitationLabels(done.citations, _sourceChunks),
          createdAt: DateTime.now().toIso8601String(),
        ),
      );
      if (token != _streamToken || _disposed) {
        return;
      }

      final index = _messages.lastIndexWhere((m) => m.isStreaming);
      final updated = List<ChatMessageModel>.of(_messages);
      if (index >= 0) {
        updated[index] = saved;
      } else {
        updated.add(saved);
      }
      _messages = updated;

      if (done.remainingDaily != null) {
        _remainingQuota = done.remainingDaily!;
      }
      if (done.maxDaily != null) {
        _maxQuota = done.maxDaily!;
      }
      _connection = TutorConnectionStatus.online;
      _pendingMode = null;
      _pendingPrompt = null;
    } catch (e) {
      debugPrint('Lỗi lưu câu trả lời AI: $e');
      if (token == _streamToken && !_disposed) {
        _messages = _messages.where((m) => !m.isStreaming).toList();
        _errorMessage = 'Không lưu được câu trả lời vào bộ nhớ máy.';
        _canRetry = true;
      }
    } finally {
      if (token == _streamToken && !_disposed) {
        _isStreaming = false;
        notifyListeners();
      }
    }
  }

  void _failStream(Object error) {
    _messages = _messages.where((m) => !m.isStreaming).toList();
    _isStreaming = false;
    _canRetry = true;

    if (error is ApiException) {
      _errorMessage = error.message;
      if (error.code == 'DAILY_QUOTA_EXCEEDED') {
        _remainingQuota = 0;
      }
    } else {
      _errorMessage = 'Đã xảy ra lỗi khi nhận câu trả lời từ AI.';
    }
    notifyListeners();

    // Lỗi do đường truyền: kiểm tra lại để hiện đúng cảnh báo "mất mạng" / "máy chủ".
    final interrupted = error is ApiException && error.code == 'STREAM_INTERRUPTED';
    if (isConnectionFailure(error) || interrupted) {
      unawaited(checkConnection());
    }
  }

  /// Người dùng bấm Dừng: ngắt luồng SSE và GIỮ LẠI phần chữ AI đã viết.
  /// Phần giữ lại được lưu vào SQLite (không có nguồn trích dẫn vì AI chưa trả lời xong).
  /// Lượt gọi AI đã bị Backend trừ quota thì không hoàn lại được.
  Future<void> stopStreaming() async {
    if (!canStop) {
      return;
    }
    _isStopping = true;

    final session = _session;
    final streamingIndex = _messages.lastIndexWhere((m) => m.isStreaming);
    final partial =
        streamingIndex >= 0 ? _messages[streamingIndex].content : '';

    // Hủy luồng nhưng vẫn giữ _isStreaming = true cho tới khi lưu xong,
    // để người dùng không gửi câu mới chen vào giữa chừng.
    final stopToken = ++_streamToken;
    final subscription = _subscription;
    _subscription = null;
    final completer = _streamCompleter;
    _streamCompleter = null;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
    await subscription?.cancel();

    ChatMessageModel? saved;
    if (session != null && partial.trim().isNotEmpty) {
      try {
        saved = await _repository.insertMessage(
          ChatMessageModel(
            sessionId: session.id!,
            role: ChatMessageModel.roleAi,
            content: partial,
            createdAt: DateTime.now().toIso8601String(),
          ),
        );
      } catch (e) {
        debugPrint('Lỗi lưu câu trả lời bị dừng: $e');
      }
    }

    _isStopping = false;
    // Nếu trong lúc lưu có thao tác khác (đổi chủ đề, đổi phiên...) đã dọn trạng thái thì thôi.
    if (stopToken != _streamToken || _disposed) {
      return;
    }

    final updated = _messages.where((m) => !m.isStreaming).toList();
    if (saved != null) {
      updated.add(saved);
    }
    _messages = updated;
    _isStreaming = false;
    _errorMessage = null;
    _canRetry = false;
    _pendingMode = null;
    _pendingPrompt = null;
    notifyListeners();
  }

  /// Hủy luồng đang chạy (khi đổi chủ đề, đổi phiên, xóa lịch sử...).
  Future<void> _cancelStreaming() async {
    _streamToken++;
    final subscription = _subscription;
    _subscription = null;
    final completer = _streamCompleter;
    _streamCompleter = null;

    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
    await subscription?.cancel();

    _isStreaming = false;
    _messages = _messages.where((m) => !m.isStreaming).toList();
  }

  // ===========================================================================
  // Quota & TASK-403 (Mini-Quiz)
  // ===========================================================================

  /// Gọi thử Backend (GET /quota/status, không tốn lượt AI) để biết còn kết nối hay không
  /// và cập nhật hạn mức. Nếu Backend không phản hồi thì tra Internet để phân biệt
  /// "máy mất mạng" với "Backend không chạy".
  Future<void> checkConnection() async {
    if (_isCheckingConnection || _disposed) {
      return;
    }
    _isCheckingConnection = true;
    if (!_connection.isAiAvailable) {
      notifyListeners(); // để nút "Kiểm tra lại" hiện vòng quay
    }

    try {
      final res = await ApiClient.instance.get('/api/v1/quota/status');
      _applyQuota(res['quota']);
      _connection = TutorConnectionStatus.online;
    } catch (e) {
      if (isConnectionFailure(e)) {
        final hasInternet = await _internetProbe();
        _connection = hasInternet
            ? TutorConnectionStatus.serverUnreachable
            : TutorConnectionStatus.noInternet;
      } else {
        // Backend trả lỗi HTTP nghĩa là Backend vẫn đang chạy.
        _connection = TutorConnectionStatus.online;
      }
    } finally {
      _isCheckingConnection = false;
    }
    notifyListeners();
  }

  /// Giữ tên cũ cho nút bấm vào huy hiệu hạn mức.
  Future<void> refreshQuota() => checkConnection();

  /// Đang mất kết nối thì kiểm tra lại một lần trước khi cho gọi AI.
  Future<bool> _ensureAiAvailable() async {
    if (_connection.isAiAvailable) {
      return true;
    }
    await checkConnection();
    return _connection.isAiAvailable;
  }

  void _applyQuota(Object? quota) {
    if (quota is Map) {
      final remaining = (quota['remainingDaily'] as num?)?.toInt();
      final maxDaily = (quota['maxDaily'] as num?)?.toInt();
      if (remaining != null) {
        _remainingQuota = remaining;
      }
      if (maxDaily != null) {
        _maxQuota = maxDaily;
      }
    }
  }

  /// Sinh nhanh tối đa 3 câu trắc nghiệm từ nội dung câu trả lời AI vừa xong (MDL-02).
  /// Ném [ApiException] khi lỗi để popup hiển thị thông báo và nút Thử lại.
  Future<List<MiniQuizQuestion>> generateMiniQuiz(String answerContent) async {
    final context = _topicContext;
    if (context == null) {
      throw ApiException(
        code: 'NO_TOPIC',
        message: 'Chưa chọn chủ đề học.',
      );
    }

    if (!_connection.isAiAvailable) {
      throw ApiException(
        code: 'OFFLINE',
        message: '${_connection.warningTitle}. Hãy kết nối lại rồi thử lại.',
      );
    }

    // Tìm câu hỏi gần nhất của người dùng ngay trước câu trả lời này để tăng độ chính xác
    String userQuestion = '';
    final aiIndex = _messages.lastIndexWhere((m) => m.isAi && m.content == answerContent);
    if (aiIndex > 0) {
      for (var i = aiIndex - 1; i >= 0; i--) {
        if (_messages[i].isUser) {
          userQuestion = _messages[i].content;
          break;
        }
      }
    }

    final res = await ApiClient.instance.post(
      '/api/v1/quiz/generate-mini',
      body: {
        'programmingLanguage': context.programmingLanguage,
        'topicId': context.topicId,
        'topicName': context.topicName,
        'userQuestion': userQuestion,
        'tutorAnswer': answerContent,
      },
      useMock: useMock,
    );

    _applyQuota(res['quota']);
    _connection = TutorConnectionStatus.online;
    notifyListeners();

    final data = res['data'];
    final rawQuestions = data is Map ? data['questions'] : null;
    final questions = rawQuestions is List
        ? rawQuestions
            .where((e) => e is Map)
            .map((e) => MiniQuizQuestion.fromJson(Map<String, dynamic>.from(e as Map)))
            .where((q) => q.isValid)
            .take(3)
            .toList()
        : <MiniQuizQuestion>[];

    if (questions.isEmpty) {
      throw ApiException(
        code: 'EMPTY_QUIZ',
        message: 'AI chưa tạo được câu hỏi kiểm tra. Hãy thử lại.',
      );
    }
    return questions;
  }

  // ===========================================================================

  @override
  void notifyListeners() {
    if (_disposed) {
      return;
    }
    super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _connectionTimer?.cancel();
    final completer = _streamCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
