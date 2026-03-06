import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import '../models/diary_model.dart';

class DriveService {
  static final DriveService _instance = DriveService._internal();
  factory DriveService() => _instance;
  DriveService._internal();

  GoogleSignIn? _googleSignIn;
  drive.DriveApi? _driveApi;
  bool _isSignedIn = false;
  String? _folderId;

  bool get isSignedIn => _isSignedIn;
  drive.DriveApi? get driveApi => _driveApi;

  GoogleSignIn get googleSignIn {
    _googleSignIn ??= GoogleSignIn(
      clientId: '388011496987-83ootka4r6tfcoc9450l9tmhn0s0pdpq.apps.googleusercontent.com',
      scopes: [
        'https://www.googleapis.com/auth/drive.file',
        'https://www.googleapis.com/auth/drive.appdata',
      ],
    );
    return _googleSignIn!;
  }

  /// Initialize Google Sign-In and listen for auth changes
  Future<void> init() async {
    // Listen for account changes
    googleSignIn.onCurrentUserChanged.listen((account) async {
      if (account != null) {
        _isSignedIn = true;
        await _initializeDriveApi();
        await _createOrGetAppFolder();
      } else {
        _isSignedIn = false;
        _driveApi = null;
        _folderId = null;
      }
    });

    // Check if already signed in
    final account = await googleSignIn.isSignedIn();
    if (account) {
      final currentUser = googleSignIn.currentUser;
      if (currentUser != null) {
        _isSignedIn = true;
        await _initializeDriveApi();
        await _createOrGetAppFolder();
      }
    }
  }

  Future<bool> signIn() async {
    try {
      print('Starting Google Sign-In...');
      final account = await googleSignIn.signIn();
      
      if (account != null) {
        print('Sign-in successful: ${account.email}');
        _isSignedIn = true;
        
        // Wait a bit for auth to propagate
        await Future.delayed(const Duration(milliseconds: 500));
        
        final success = await _initializeDriveApi();
        if (success) {
          await _createOrGetAppFolder();
          return true;
        }
      }
      print('Sign-in cancelled or failed');
      return false;
    } catch (e) {
      print('Sign in error: $e');
      _isSignedIn = false;
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await googleSignIn.signOut();
      _isSignedIn = false;
      _driveApi = null;
      _folderId = null;
    } catch (e) {
      print('Sign out error: $e');
    }
  }

  /// Initialize Drive API with current user authentication
  /// Returns true if successful
  Future<bool> _initializeDriveApi() async {
    try {
      final currentUser = googleSignIn.currentUser;
      if (currentUser == null) {
        print('No current user available');
        return false;
      }

      final authHeaders = await currentUser.authHeaders;
      if (authHeaders == null) {
        print('No auth headers available');
        return false;
      }

      final client = http.Client();
      final authenticatedClient = _AuthenticatedClient(client, authHeaders);
      _driveApi = drive.DriveApi(authenticatedClient);
      print('Drive API initialized successfully');
      return true;
    } catch (e) {
      print('Failed to initialize Drive API: $e');
      return false;
    }
  }

  /// Ensure Drive API is ready before operations
  Future<bool> _ensureDriveApiReady() async {
    if (_driveApi != null && _isSignedIn) {
      return true;
    }
    
    // Try to reinitialize
    if (_isSignedIn) {
      return await _initializeDriveApi();
    }
    
    return false;
  }

  Future<void> _createOrGetAppFolder() async {
    if (_driveApi == null) return;

    try {
      // Search for existing app folder
      final query = "name='DailyDiaryBackup' and mimeType='application/vnd.google-apps.folder' and trashed=false";
      final result = await _driveApi!.files.list(
        q: query,
        $fields: 'files(id, name)',
      );

      if (result.files!.isNotEmpty) {
        _folderId = result.files!.first.id;
      } else {
        // Create new folder
        final folder = drive.File()
          ..name = 'DailyDiaryBackup'
          ..mimeType = 'application/vnd.google-apps.folder';
        
        final createdFolder = await _driveApi!.files.create(folder);
        _folderId = createdFolder.id;
      }
    } catch (e) {
      print('Folder error: $e');
    }
  }

  Future<String?> uploadDiary(DiaryEntry entry) async {
    if (_driveApi == null || _folderId == null) {
      await _initializeDriveApi();
      await _createOrGetAppFolder();
    }

    try {
      // Create JSON content from diary entry
      final content = jsonEncode(entry.toMap());
      final fileName = 'diary_${DateTime.now().millisecondsSinceEpoch}.json';
      
      final media = drive.Media(
        Stream.value(utf8.encode(content)),
        content.length,
      );

      final file = drive.File()
        ..name = fileName
        ..parents = [_folderId!]
        ..description = 'Diary entry from ${entry.date}';

      final uploadedFile = await _driveApi!.files.create(
        file,
        uploadMedia: media,
      );

      return uploadedFile.id;
    } catch (e) {
      print('Upload error: $e');
      return null;
    }
  }

  Future<List<DiaryEntry>> downloadDiaries() async {
    if (_driveApi == null) {
      await _initializeDriveApi();
    }

    if (_driveApi == null || _folderId == null) return [];

    try {
      final query = "'$_folderId' in parents and trashed=false and mimeType='application/json'";
      final result = await _driveApi!.files.list(
        q: query,
        $fields: 'files(id, name, modifiedTime)',
      );

      final entries = <DiaryEntry>[];
      
      for (final file in result.files!) {
        try {
      final content = await _driveApi!.files.get(file.id!);
          if (content is drive.Media) {
            final bytes = await content.stream.toList();
            final jsonString = utf8.decode(bytes.expand((x) => x).toList());
            final map = jsonDecode(jsonString) as Map<String, dynamic>;
            entries.add(DiaryEntry.fromMap(map));
          }
        } catch (e) {
          print('Download error for ${file.name}: $e');
        }
      }

      return entries;
    } catch (e) {
      print('List files error: $e');
      return [];
    }
  }

  Future<bool> deleteFile(String? fileId) async {
    if (_driveApi == null || fileId == null) return false;

    try {
      await _driveApi!.files.delete(fileId);
      return true;
    } catch (e) {
      print('Delete error: $e');
      return false;
    }
  }

  Future<String?> backupAllDiaries(List<DiaryEntry> entries) async {
    if (_driveApi == null || _folderId == null) {
      await _initializeDriveApi();
      await _createOrGetAppFolder();
    }

    try {
      // Create backup file with all entries
      final backupData = {
        'backupDate': DateTime.now().toIso8601String(),
        'entries': entries.map((e) => e.toMap()).toList(),
      };
      
      final content = jsonEncode(backupData);
      final fileName = 'backup_${DateTime.now().millisecondsSinceEpoch}.json';
      
      final media = drive.Media(
        Stream.value(utf8.encode(content)),
        content.length,
      );

      final file = drive.File()
        ..name = fileName
        ..parents = [_folderId!]
        ..description = 'Full backup of diary entries';

      final uploadedFile = await _driveApi!.files.create(
        file,
        uploadMedia: media,
      );

      return uploadedFile.id;
    } catch (e) {
      print('Backup error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getLastBackupInfo() async {
    if (_driveApi == null || _folderId == null) return null;

    try {
      final query = "'$_folderId' in parents and name contains 'backup_' and trashed=false";
      final result = await _driveApi!.files.list(
        q: query,
        $fields: 'files(id, name, modifiedTime)',
        orderBy: 'modifiedTime desc',
      );

      if (result.files!.isNotEmpty) {
        final file = result.files!.first;
        return {
          'id': file.id,
          'name': file.name,
          'modifiedTime': file.modifiedTime?.toIso8601String(),
        };
      }
      return null;
    } catch (e) {
      print('Get backup info error: $e');
      return null;
    }
  }
}

class _AuthenticatedClient extends http.BaseClient {
  final http.Client _inner;
  final Map<String, String> _authHeaders;

  _AuthenticatedClient(this._inner, this._authHeaders);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_authHeaders);
    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
  }
}

