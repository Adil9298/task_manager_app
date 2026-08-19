import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

class SessionService {
  static const String _boxName = 'session_box';

  static const String _uidKey = 'uid';
  static const String _isGuestKey = 'isGuest';

  static const Uuid _uuid = Uuid();

  Box<dynamic>? _box;

  // ===========================================================================
  // INITIALIZE
  // ===========================================================================

  Future<void> init() async {
    if (_box != null && _box!.isOpen) {
      return;
    }

    if (Hive.isBoxOpen(_boxName)) {
      _box = Hive.box(_boxName);
    } else {
      _box = await Hive.openBox(_boxName);
    }
  }

  // ===========================================================================
  // GET OR CREATE GUEST ID
  // ===========================================================================

  Future<String> getOrCreateGuestId() async {
    await _ensureInitialized();

    final existingUid =
    _box!.get(_uidKey);

    final existingIsGuest =
    _box!.get(
      _isGuestKey,
      defaultValue: false,
    );

    // ---------------------------------------------------------------
    // Existing guest session
    // ---------------------------------------------------------------

    if (existingIsGuest == true &&
        existingUid is String &&
        existingUid.isNotEmpty) {
      return existingUid;
    }

    // ---------------------------------------------------------------
    // Create new guest ID
    // ---------------------------------------------------------------

    final guestId =
        'guest_${_uuid.v4()}';

    await saveSession(
      uid: guestId,
      isGuest: true,
    );

    return guestId;
  }

  // ===========================================================================
  // SAVE SESSION
  // ===========================================================================

  Future<void> saveSession({
    required String uid,
    required bool isGuest,
  }) async {
    await _ensureInitialized();

    await _box!.put(
      _uidKey,
      uid,
    );

    await _box!.put(
      _isGuestKey,
      isGuest,
    );
  }

  // ===========================================================================
  // GET CURRENT UID
  // ===========================================================================

  Future<String?> getUid() async {
    await _ensureInitialized();

    final value =
    _box!.get(_uidKey);

    if (value is String &&
        value.isNotEmpty) {
      return value;
    }

    return null;
  }

  // ===========================================================================
  // GET GUEST STATUS
  // ===========================================================================

  Future<bool> getIsGuest() async {
    await _ensureInitialized();

    return _box!.get(
      _isGuestKey,
      defaultValue: false,
    ) ==
        true;
  }

  // ===========================================================================
  // SESSION EXISTS
  // ===========================================================================

  Future<bool> hasSession() async {
    final currentUid =
    await getUid();

    return currentUid != null &&
        currentUid.isNotEmpty;
  }

  // ===========================================================================
  // CLEAR SESSION
  // ===========================================================================

  Future<void> clearSession() async {
    await _ensureInitialized();

    await _box!.delete(
      _uidKey,
    );

    await _box!.delete(
      _isGuestKey,
    );
  }

  // ===========================================================================
  // CLEAR ONLY GUEST SESSION
  // ===========================================================================

  Future<void> clearGuestSession() async {
    await _ensureInitialized();

    final guest =
    await getIsGuest();

    if (!guest) {
      return;
    }

    await clearSession();
  }

  // ===========================================================================
  // CLOSE
  // ===========================================================================

  Future<void> close() async {
    if (_box != null &&
        _box!.isOpen) {
      await _box!.close();
    }

    _box = null;
  }

  // ===========================================================================
  // ENSURE INITIALIZED
  // ===========================================================================

  Future<void> _ensureInitialized() async {
    if (_box == null ||
        !_box!.isOpen) {
      await init();
    }
  }
}