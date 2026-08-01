import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../data/models/user_profile.dart';
import '../data/services/storage_service.dart';

class ProfileController extends ChangeNotifier {
  ProfileController(this._storage) : _profile = _storage.readProfile();

  final StorageService _storage;
  final ImagePicker _picker = ImagePicker();

  UserProfile _profile;

  UserProfile get value => _profile;

  File? get avatarFile {
    final String? path = _profile.avatarPath;
    if (path == null) return null;
    final File file = File(path);
    return file.existsSync() ? file : null;
  }

  Future<void> _save(UserProfile next) async {
    _profile = next;
    notifyListeners();
    await _storage.writeProfile(next);
  }

  Future<void> setName(String name) =>
      _save(_profile.copyWith(name: name.trim().isEmpty ? 'Traveller' : name.trim()));

  Future<void> setMotto(String motto) =>
      _save(_profile.copyWith(motto: motto.trim()));

  /// Copies the picked image into app storage so it survives cache cleanup,
  /// then points the profile at the copy. Returns false when the user backs out.
  Future<bool> pickAvatar(ImageSource source) async {
    final XFile? picked = await _picker.pickImage(
      source: source,
      maxWidth: 900,
      maxHeight: 900,
      imageQuality: 88,
      preferredCameraDevice: CameraDevice.front,
    );
    if (picked == null) return false;

    final Directory dir = await getApplicationDocumentsDirectory();
    final String target =
        '${dir.path}${Platform.pathSeparator}avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(picked.path).copy(target);

    final String? previous = _profile.avatarPath;
    await _save(_profile.copyWith(avatarPath: target));

    if (previous != null && previous != target) {
      final File old = File(previous);
      if (old.existsSync()) {
        try {
          await old.delete();
        } catch (_) {
          // A stale avatar file is harmless.
        }
      }
    }
    return true;
  }

  Future<void> removeAvatar() async {
    final String? path = _profile.avatarPath;
    await _save(_profile.copyWith(clearAvatar: true));
    if (path != null) {
      final File file = File(path);
      if (file.existsSync()) {
        try {
          await file.delete();
        } catch (_) {
          // Ignore: the reference is already gone.
        }
      }
    }
  }
}
