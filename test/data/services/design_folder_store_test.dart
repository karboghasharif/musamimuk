import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:musamimuk/data/services/design_folder_store.dart';
import 'package:musamimuk/data/services/local_design_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DesignFolderStore.validateName', () {
    test('accepts 2–30 safe names', () {
      expect(DesignFolderStore.validateName('AB'), isNull);
      expect(DesignFolderStore.validateName('Work drafts'), isNull);
      expect(DesignFolderStore.validateName("Client's art"), isNull);
      expect(DesignFolderStore.validateName('طباعة 1'), isNull);
    });

    test('rejects length and charset', () {
      expect(DesignFolderStore.validateName('A'), 'length');
      expect(DesignFolderStore.validateName('   '), 'length');
      expect(DesignFolderStore.validateName('x' * 31), 'length');
      expect(DesignFolderStore.validateName('bad/name'), 'charset');
      expect(DesignFolderStore.validateName('a@b'), 'charset');
    });
  });

  group('LocalDesignDraft folderId migration', () {
    test('missing folderId becomes Unfiled (null)', () {
      final draft = LocalDesignDraft.fromJson({
        'id': 'local_1',
        'name': 'Old',
        'historyJson': '{}',
        'width': 1080,
        'height': 1080,
        'updatedAt': '2026-01-01T00:00:00.000',
      });
      expect(draft.folderId, isNull);
      expect(draft.toJson().containsKey('folderId'), isFalse);
    });

    test('empty folderId becomes Unfiled', () {
      final draft = LocalDesignDraft.fromJson({
        'id': 'local_2',
        'name': 'Blank',
        'historyJson': '{}',
        'width': 1,
        'height': 1,
        'updatedAt': '2026-01-01T00:00:00.000',
        'folderId': '  ',
      });
      expect(draft.folderId, isNull);
    });

    test('persists folderId when set', () {
      final draft = LocalDesignDraft(
        id: 'local_3',
        name: 'Filed',
        historyJson: '{}',
        width: 1,
        height: 1,
        updatedAt: DateTime.utc(2026, 1, 1),
        folderId: 'fld_1',
      );
      expect(draft.toJson()['folderId'], 'fld_1');
      expect(LocalDesignDraft.fromJson(draft.toJson()).folderId, 'fld_1');
    });
  });

  group('LocalDesignStore move + folder delete', () {
    late Directory temp;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      temp = await Directory.systemTemp.createTemp('musami_folder_test_');
      LocalDesignStore.instance.debugRootOverride = temp;
      LocalDesignStore.instance.debugResetRootCache();
      DesignFolderStore.instance.debugRootOverride = temp;
      DesignFolderStore.instance.debugResetRootCache();
    });

    tearDown(() async {
      LocalDesignStore.instance.debugRootOverride = null;
      LocalDesignStore.instance.debugResetRootCache();
      DesignFolderStore.instance.debugRootOverride = null;
      DesignFolderStore.instance.debugResetRootCache();
      if (await temp.exists()) {
        await temp.delete(recursive: true);
      }
    });

    test('moveDraft sets and clears folderId; survives rewrite', () async {
      final created = await LocalDesignStore.instance.saveDraft(
        name: 'Draft A',
        historyJson: '{"history":[]}',
        width: 100,
        height: 100,
      );
      expect(created.folderId, isNull);

      final moved = await LocalDesignStore.instance.moveDraft(
        id: created.id,
        folderId: 'fld_work',
      );
      expect(moved?.folderId, 'fld_work');

      final listed = await LocalDesignStore.instance.listDrafts();
      expect(listed.single.folderId, 'fld_work');

      // Autosave without folderId arg preserves membership.
      final savedAgain = await LocalDesignStore.instance.saveDraft(
        existingId: created.id,
        name: 'Draft A2',
        historyJson: '{"history":[1]}',
        width: 100,
        height: 100,
      );
      expect(savedAgain.folderId, 'fld_work');

      final unfiled = await LocalDesignStore.instance.moveDraft(
        id: created.id,
        folderId: null,
      );
      expect(unfiled?.folderId, isNull);
    });

    test('create/rename/delete folder and unfile drafts', () async {
      final folder = await DesignFolderStore.instance.createFolder('Work');
      expect(folder.name, 'Work');

      final draft = await LocalDesignStore.instance.saveDraft(
        name: 'In Work',
        historyJson: '{}',
        width: 10,
        height: 10,
        folderId: folder.id,
      );
      expect(draft.folderId, folder.id);

      await DesignFolderStore.instance.renameFolder(folder.id, 'Clients');
      final renamed = await DesignFolderStore.instance.listFolders();
      expect(renamed.single.name, 'Clients');

      await DesignFolderStore.instance.deleteFolder(folder.id);
      expect(await DesignFolderStore.instance.listFolders(), isEmpty);
      final after = await LocalDesignStore.instance.listDrafts();
      expect(after.single.folderId, isNull);
    });

    test('enforces max folders and duplicate names', () async {
      await DesignFolderStore.instance.createFolder('Folder 0');
      expect(
        () => DesignFolderStore.instance.createFolder('Folder 0'),
        throwsA(
          isA<FolderStoreException>()
              .having((e) => e.code, 'code', 'duplicate'),
        ),
      );
      for (var i = 1; i < DesignFolderStore.maxFolders; i++) {
        await DesignFolderStore.instance.createFolder('Folder $i');
      }
      expect(
        () => DesignFolderStore.instance.createFolder('Extra'),
        throwsA(
          isA<FolderStoreException>().having((e) => e.code, 'code', 'max'),
        ),
      );
    });

    test('cloud membership tags persist in prefs', () async {
      await DesignFolderStore.instance.setCloudFolder(
        designId: '99',
        folderId: 'fld_cloud',
      );
      expect(await DesignFolderStore.instance.cloudFolderId('99'), 'fld_cloud');
      await DesignFolderStore.instance.clearCloudMembershipForFolder('fld_cloud');
      expect(await DesignFolderStore.instance.cloudFolderId('99'), isNull);
    });
  });
}
