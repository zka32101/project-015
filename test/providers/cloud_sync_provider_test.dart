import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:reversia/providers/cloud_sync_provider.dart';

/// GoogleSignIn's real signIn()/signOut() go through a platform channel
/// that isn't available in a plain `test()` (no Flutter binding, no native
/// plugin), so tests never exercise it directly -- this stub keeps
/// CloudSyncNotifier's constructor from touching it at all.
class _StubGoogleSignIn extends GoogleSignIn {
  @override
  Future<GoogleSignInAccount?> signOut() async => null;
}

CloudSyncNotifier _buildNotifier(FakeFirebaseFirestore firestore, String uid) {
  final auth = MockFirebaseAuth(mockUser: MockUser(uid: uid), signedIn: true);
  return CloudSyncNotifier(
    firestore: firestore,
    auth: auth,
    googleSignIn: _StubGoogleSignIn(),
  );
}

void main() {
  group('CloudSyncNotifier', () {
    late FakeFirebaseFirestore firestore;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      SharedPreferences.setMockInitialValues({});
    });

    test('restoreOrUploadFor uploads local data as the initial backup when none exists',
        () async {
      SharedPreferences.setMockInitialValues({
        'rank_points': 42,
        'game_statistics': '{"totalGames":3}',
        'game_session_history': '[]',
        'game_history': '[]',
      });
      final prefs = await SharedPreferences.getInstance();
      final notifier = _buildNotifier(firestore, 'me');

      final restored = await notifier.restoreOrUploadFor('me', prefs);

      expect(restored, isFalse);
      expect(notifier.state.isSyncing, isFalse);
      expect(notifier.state.error, isNull);

      final doc = await firestore.collection('userProgress').doc('me').get();
      expect(doc.exists, isTrue);
      expect(doc.data()!['rankPoints'], 42);
      expect(doc.data()!['statistics'], '{"totalGames":3}');
    });

    test('restoreOrUploadFor restores an existing cloud backup into prefs, overwriting local',
        () async {
      await firestore.collection('userProgress').doc('me').set({
        'rankPoints': 100,
        'statistics': '{"totalGames":50}',
        'sessionHistory': '[{"foo":"bar"}]',
        'gameHistory': '[{"id":"old"}]',
      });

      SharedPreferences.setMockInitialValues({
        'rank_points': 0,
        'game_statistics': '{"totalGames":0}',
      });
      final prefs = await SharedPreferences.getInstance();
      final notifier = _buildNotifier(firestore, 'me');

      final restored = await notifier.restoreOrUploadFor('me', prefs);

      expect(restored, isTrue);
      expect(prefs.getInt('rank_points'), 100);
      expect(prefs.getString('game_statistics'), '{"totalGames":50}');
      expect(prefs.getString('game_session_history'), '[{"foo":"bar"}]');
      expect(prefs.getString('game_history'), '[{"id":"old"}]');
    });

    test('syncNow re-uploads the current local data, overwriting the cloud backup', () async {
      await firestore.collection('userProgress').doc('me').set({
        'rankPoints': 5,
        'statistics': null,
        'sessionHistory': null,
        'gameHistory': null,
      });

      SharedPreferences.setMockInitialValues({'rank_points': 200});
      final prefs = await SharedPreferences.getInstance();
      final notifier = _buildNotifier(firestore, 'me');

      await notifier.syncNow(prefs);

      final doc = await firestore.collection('userProgress').doc('me').get();
      expect(doc.data()!['rankPoints'], 200);
      expect(notifier.state.lastSyncedAt, isNotNull);
    });

    test('syncNow is a no-op when signed out', () async {
      final auth = MockFirebaseAuth(signedIn: false);
      final notifier = CloudSyncNotifier(
        firestore: firestore,
        auth: auth,
        googleSignIn: _StubGoogleSignIn(),
      );
      final prefs = await SharedPreferences.getInstance();

      await notifier.syncNow(prefs);

      final docs = await firestore.collection('userProgress').get();
      expect(docs.docs, isEmpty);
    });

    test('signOut clears the signed-in state', () async {
      final notifier = _buildNotifier(firestore, 'me');
      expect(notifier.state.isSignedIn, isTrue);

      await notifier.signOut();

      expect(notifier.state.isSignedIn, isFalse);
      expect(notifier.state.displayName, isNull);
    });

    test('clearError resets a previously set error', () async {
      final notifier = _buildNotifier(firestore, 'me');
      notifier.clearError();
      expect(notifier.state.error, isNull);
    });
  });
}
