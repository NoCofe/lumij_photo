import 'package:flutter/foundation.dart';
import '../models/photo_model.dart';
import '../models/album_model.dart';
import '../services/photo_service.dart';
import '../services/database_service.dart';

class PhotoProvider with ChangeNotifier {
  List<PhotoModel> _allPhotos = [];
  List<PhotoModel> _duplicatePhotos = [];
  List<PhotoModel> _largePhotos = [];
  List<AlbumModel> _albums = [];
  Map<String, int> _monthlyProgress = {};
  bool _isLoading = false;
  String _currentView = 'all'; // 'all', 'duplicates', 'large', 'albums'
  
  // Getters
  List<PhotoModel> get allPhotos => _allPhotos;
  List<PhotoModel> get duplicatePhotos => _duplicatePhotos;
  List<PhotoModel> get largePhotos => _largePhotos;
  List<AlbumModel> get albums => _albums;
  Map<String, int> get monthlyProgress => _monthlyProgress;
  bool get isLoading => _isLoading;
  String get currentView => _currentView;
  
  void setCurrentView(String view) {
    _currentView = view;
    notifyListeners();
  }
  
  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  Future<void> scanPhotos() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    
    try {
      // 请求权限
      final hasPermission = await PhotoService.requestPermission();
      if (!hasPermission) {
        _errorMessage = '需要相册访问权限才能使用此功能';
        return;
      }
      
      // 扫描所有照片
      _allPhotos = await PhotoService.scanAllPhotos();
      
      if (_allPhotos.isEmpty) {
        _errorMessage = '未找到任何照片';
        return;
      }
      
      // 查找重复照片
      await _findDuplicates();
      
      // 查找大文件
      await _findLargeFiles();
      
      // 获取月度进度
      await _getMonthlyProgress();
      
    } catch (e) {
      _errorMessage = '扫描照片时出错: $e';
      print('Error scanning photos: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> _findDuplicates() async {
    _duplicatePhotos = await DatabaseService.getDuplicatePhotos();
  }
  
  Future<void> _findLargeFiles() async {
    _largePhotos = await DatabaseService.getPhotosBySize(limit: 100);
  }
  
  Future<void> _getMonthlyProgress() async {
    _monthlyProgress = await PhotoService.getMonthlyProgress();
  }
  
  Future<bool> deletePhoto(String photoId) async {
    try {
      print('🗑️ [PhotoProvider] 开始删除照片: $photoId');
      
      // 找到要删除的照片
      final photo = _allPhotos.firstWhere(
        (p) => p.id == photoId,
        orElse: () => throw Exception('Photo not found'),
      );
      
      // 真实删除照片文件
      final success = await PhotoService.deletePhotoFile(photoId, photo.path);
      
      if (success) {
        // 从数据库中删除记录
        await DatabaseService.deletePhoto(photoId);
        
        // 从本地列表中移除
        _allPhotos.removeWhere((photo) => photo.id == photoId);
        _duplicatePhotos.removeWhere((photo) => photo.id == photoId);
        _largePhotos.removeWhere((photo) => photo.id == photoId);
        
        print('✅ [PhotoProvider] 照片删除成功');
        notifyListeners();
        return true;
      } else {
        throw Exception('Failed to delete photo file');
      }
    } catch (e) {
      print('❌ [PhotoProvider] 删除照片时出错: $e');
      return false;
    }
  }
  
  // 批量删除照片（iOS优化）
  Future<int> deleteMultiplePhotos(List<String> photoIds) async {
    try {
      print('🗑️ [PhotoProvider] 开始批量删除 ${photoIds.length} 张照片');
      
      // 使用批量删除API
      final deletedIds = await PhotoService.deleteMultiplePhotos(photoIds);
      
      if (deletedIds.isNotEmpty) {
        // 批量从数据库删除
        for (final photoId in deletedIds) {
          await DatabaseService.deletePhoto(photoId);
        }
        
        // 从本地列表中批量移除
        _allPhotos.removeWhere((photo) => deletedIds.contains(photo.id));
        _duplicatePhotos.removeWhere((photo) => deletedIds.contains(photo.id));
        _largePhotos.removeWhere((photo) => deletedIds.contains(photo.id));
        
        print('✅ [PhotoProvider] 批量删除完成，成功删除 ${deletedIds.length} 张照片');
        notifyListeners();
      }
      
      return deletedIds.length;
    } catch (e) {
      print('❌ [PhotoProvider] 批量删除时出错: $e');
      return 0;
    }
  }
  
  Future<void> compressPhoto(String photoId) async {
    try {
      final photoIndex = _allPhotos.indexWhere((photo) => photo.id == photoId);
      if (photoIndex == -1) return;
      
      final photo = _allPhotos[photoIndex];
      if (photo.type != 'image') return; // 只压缩图片
      
      final compressedPath = await PhotoService.compressImage(photo.path);
      if (compressedPath != null) {
        final updatedPhoto = photo.copyWith(
          isCompressed: true,
          compressedPath: compressedPath,
        );
        
        await DatabaseService.updatePhoto(updatedPhoto);
        _allPhotos[photoIndex] = updatedPhoto;
        
        // 更新其他列表中的照片
        final duplicateIndex = _duplicatePhotos.indexWhere((p) => p.id == photoId);
        if (duplicateIndex != -1) {
          _duplicatePhotos[duplicateIndex] = updatedPhoto;
        }
        
        final largeIndex = _largePhotos.indexWhere((p) => p.id == photoId);
        if (largeIndex != -1) {
          _largePhotos[largeIndex] = updatedPhoto;
        }
        
        notifyListeners();
      }
    } catch (e) {
      print('Error compressing photo: $e');
    }
  }
  
  Future<void> addToAlbum(String photoId, String albumName) async {
    try {
      final photoIndex = _allPhotos.indexWhere((photo) => photo.id == photoId);
      if (photoIndex == -1) return;
      
      final photo = _allPhotos[photoIndex];
      final updatedPhoto = photo.copyWith(albumName: albumName);
      
      await DatabaseService.updatePhoto(updatedPhoto);
      _allPhotos[photoIndex] = updatedPhoto;
      
      // 更新相册信息
      await _updateAlbumInfo(albumName);
      
      notifyListeners();
    } catch (e) {
      print('Error adding photo to album: $e');
    }
  }
  
  Future<void> _updateAlbumInfo(String albumName) async {
    final albumPhotos = await DatabaseService.getPhotosByAlbum(albumName);
    final album = AlbumModel(
      name: albumName,
      photoCount: albumPhotos.length,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      coverPhotoPath: albumPhotos.isNotEmpty ? albumPhotos.first.path : null,
    );
    
    await DatabaseService.insertAlbum(album);
    await loadAlbums();
  }
  
  Future<void> loadAlbums() async {
    try {
      print('🔄 [PhotoProvider] 开始加载相册...');
      // 加载所有相册（系统相册 + 应用内相册）
      _albums = await PhotoService.getAllAlbums();
      print('✅ [PhotoProvider] 相册加载完成，共 ${_albums.length} 个');
      notifyListeners();
    } catch (e) {
      print('❌ [PhotoProvider] 加载相册时出错: $e');
    }
  }
  
  Future<List<PhotoModel>> getAlbumPhotos(String albumName) async {
    try {
      // 首先尝试从真实相册获取
      final realAlbumPhotos = await PhotoService.getPhotosFromRealAlbum(albumName);
      if (realAlbumPhotos.isNotEmpty) {
        return realAlbumPhotos;
      }
      
      // 如果真实相册没有，则从数据库获取应用内相册
      return await DatabaseService.getPhotosByAlbum(albumName);
    } catch (e) {
      print('Error getting album photos: $e');
      return [];
    }
  }
}