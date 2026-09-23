import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../engine/game_record.dart';
import '../viewmodels/game_view_model.dart'
    show gameStatisticsPrefsKey, gameSessionHistoryPrefsKey, rankPointsPrefsKey;

class CloudSyncState {
  final bool isSignedIn;
  final String? displayName;
  final String? email;
  final bool isSyncing;
  final DateTime? lastSyncedAt;
  final String? error;

  const CloudSyncState({
    this.isSignedIn = false,
    this.displayName,
    this.email,
    this.isSyncing = false,
    this.lastSyncedAt,
    this.error,
  });

  CloudSyncState copyWith({
    bool? isSignedIn,
    Object? displayName = _unset,
    Object? email = _unset,
    bool? isSyncing,
    Object? lastSyncedAt = _unset,
    Object? error = _unset,
  }) {
    return CloudSyncState(
      isSignedIn: isSignedIn ?? this.isSignedIn,
      displayName:
          identical(displayName, _unset) ? this.displayName : displayName as String?,
      email: identical(email, _unset) ? this.email : email as String?,
      isSyncing: isSyncing ?? this.isSyncing,
      lastSyncedAt:
          identical(lastSyncedAt, _unset) ? this.lastSyncedAt : lastSyncedAt as DateTime?,
      error: identical(error, _unset) ? this.error : error as String?,
    );
  }
}

const Object _unset = Object();

/// Backs up/restores core single-player progress (rank points, statistics,
/// session history, game records) to Firestore under the signed-in Google
/// account's uid, so it survives a reinstall or carries over to a new
/// device. Anonymous auth (used for online multiplayer) can't do this: its
/// uid isn't recoverable on a different install, so this needs a real
/// identity provider.
///
/// Deliberately one-way per action, not an automatic bidirectional merge:
/// signing in on a device that already has a cloud backup *restores* it
/// (overwriting local data); a device with no existing backup uploads its
/// current local data as the initial one. A later manual sync just
/// re-uploads local data. Reconciling two devices that both played offline
/// since the last sync is a genuinely hard problem and out of scope here.
class CloudSyncNotifier extends StateNotifier<CloudSyncState> {
  static const String _collection = 'userProgress';

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  CloudSyncNotifier({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(),
        super(const CloudSyncState()) {
    final user = _auth.currentUser;
    if (user != null) {
      state = state.copyWith(
        isSignedIn: true,
        displayName: user.displayName,
        email: user.email,
      );
    }
  }

  /// Signs in with Google, then restores from an existing cloud backup if
  /// one exists for this account, or uploads this device's local data as
  /// the initial backup otherwise. Returns true if a backup was restored
  /// (the caller should reload any providers that cache prefs-backed state,
  /// e.g. via GameViewModel.reloadFromPrefs()), false if there was nothing
  /// to restore or sign-in was cancelled/failed.
  Future<bool> signInWithGoogle(SharedPreferences prefs) async {
    state = state.copyWith(isSyncing: true, error: null);
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled the picker.
        state = state.copyWith(isSyncing: false);
        return false;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user!;

      state = state.copyWith(
        isSignedIn: true,
        displayName: user.displayName,
        email: user.email,
      );

      return restoreOrUploadFor(user.uid, prefs);
    } catch (_) {
      state = state.copyWith(isSyncing: false, error: 'サインインに失敗しました');
      return false;
    }
  }

  /// Given an already-authenticated [uid], restores from an existing cloud
  /// backup or uploads local data as the initial one. Split out from
  /// [signInWithGoogle] so the actual sync logic is testable without
  /// exercising the real Google Sign-In flow.
  Future<bool> restoreOrUploadFor(String uid, SharedPreferences prefs) async {
    state = state.copyWith(isSyncing: true, error: null);
    try {
      final doc = await _firestore.collection(_collection).doc(uid).get();
      bool restored = false;
      if (doc.exists) {
        await _restoreToPrefs(doc.data()!, prefs);
        restored = true;
      } else {
        await _uploadFromPrefs(uid, prefs);
      }
      state = state.copyWith(isSyncing: false, lastSyncedAt: DateTime.now());
      return restored;
    } catch (_) {
      state = state.copyWith(isSyncing: false, error: '同期に失敗しました');
      return false;
    }
  }

  /// Re-uploads this device's current local data, overwriting the cloud
  /// backup. Call after playing more games while signed in.
  Future<void> syncNow(SharedPreferences prefs) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    state = state.copyWith(isSyncing: true, error: null);
    try {
      await _uploadFromPrefs(uid, prefs);
      state = state.copyWith(isSyncing: false, lastSyncedAt: DateTime.now());
    } catch (_) {
      state = state.copyWith(isSyncing: false, error: '同期に失敗しました');
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    state = const CloudSyncState();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  Future<void> _uploadFromPrefs(String uid, SharedPreferences prefs) async {
    await _firestore.collection(_collection).doc(uid).set({
      'rankPoints': prefs.getInt(rankPointsPrefsKey) ?? 0,
      'statistics': prefs.getString(gameStatisticsPrefsKey),
      'sessionHistory': prefs.getString(gameSessionHistoryPrefsKey),
      'gameHistory': prefs.getString(GameHistoryManager.prefsKey),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> _restoreToPrefs(
    Map<String, dynamic> data,
    SharedPreferences prefs,
  ) async {
    final rankPoints = data['rankPoints'] as int?;
    if (rankPoints != null) {
      await prefs.setInt(rankPointsPrefsKey, rankPoints);
    }

    final statisticsJson = data['statistics'] as String?;
    if (statisticsJson != null) {
      await prefs.setString(gameStatisticsPrefsKey, statisticsJson);
    }

    final sessionHistoryJson = data['sessionHistory'] as String?;
    if (sessionHistoryJson != null) {
      await prefs.setString(gameSessionHistoryPrefsKey, sessionHistoryJson);
    }

    final gameHistoryJson = data['gameHistory'] as String?;
    if (gameHistoryJson != null) {
      await prefs.setString(GameHistoryManager.prefsKey, gameHistoryJson);
    }
  }
}

final cloudSyncProvider = StateNotifierProvider<CloudSyncNotifier, CloudSyncState>(
  (ref) => CloudSyncNotifier(),
);
