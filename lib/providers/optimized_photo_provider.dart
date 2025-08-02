import 'package:flutter/foundation.dart';
import '../models/photo_model.dart';
import '../models/album_model.dart';
import '../services/optimized_photo_service.dart';
import '../services/database_service.dart';

class OptimizedPhotoProvider with ChangeNotifier {
  // 分页照片列表
  List<PhotoModel> _photos = [];
  List<PhotoModel> _duplicatePhotos = [];
  List<PhotoModel> _largePhotos = [];
  List<AlbumModel> _albums = [];
  Map<String, int> _monthlyProgress = {};
  
  // 状态管理
  bool _isLoading = false;
  bool _hasMorePhotos = true;
  String _currentView = 'all';
  String _errorMessage = '';
  
  // 分页参数
  int _currentPage = 0;
  int _pageSize = 50;
  int _totalPhotos = 0;
  
  // 扫描进度
  double _scanProgress = 0;
  String _scanMessage = '';
  bool _isScanning = false;

  // Getters
  List<PhotoModel> get photos => _photos;
  List<PhotoModel> get duplicatePhotos => _duplicatePhotos;
  List<PhotoModel> get largePhotos => _largePhotos;
  List<AlbumModel> get albums => _albums;
  Map<String, int> get monthlyProgress => _monthlyProgress;
  bool get isLoading => _isLoading;
  bool get hasMorePhotos => _hasMorePhotos;
  String get currentView => _currentView;
  String get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  int get totalPhotos => _totalPhotos;
  double get scanProgress => _scanProgress;
  String get scanMessage => _scanMessage;
  bool get isScanning => _isScanning;

  void setCurrentView(String view) {
    _currentView = view;
    _resetPagination();
    notifyListeners();
  }

  void _resetPagination() {
    _currentPage = 0;
    _photos.clear();
    _hasMorePhotos = true;
  }

  // 优化的照片扫描
  Future<void> scanPhotosOptimized({
    int? maxPhotos,
    bool quickScan = true,
  }) async {
    _isScanning = true;
    _scanProgress = 0;
    _scanMessage = '准备扫描...';
    _errorMessage = '';
    notifyListeners();
    
    try {
      // 请求权限
      final hasPermission = await OptimizedPhotoService.requestPermission();
      if (!hasPermission) {
        _errorMessage = '需要相册访问权限才能使用此功能';
        return;
      }

      // 设置进度回调
      OptimizedPhotoService.setProgressCallback((progress, message) {
        _scanProgress = progress;
        _scanMessage = message;
        notifyListeners();
      });

      // 执行优化扫描
      await OptimizedPhotoService.scanAllPhotosOptimized(
        maxPhotos: maxPhotos,
        calculateHash: !quickScan, // 快速扫描时不计算哈希
        onProgress: (progress, message) {
          _scanProgress = progress;
          _scanMessage = message;
          notifyListeners();
        },
      );

      // 获取总数
      _totalPhotos = await OptimizedPhotoService.getTotalPhotosCount();
      
      // 快速获取相册列表
      await loadAlbumsQuick();
      
      // 加载第一页照片
      await loadMorePhotos();
      
      // 查找重复照片和大文件（在后台进行）
      if (!quickScan) {
        _findDuplicatesAsync();
        _findLargeFilesAsync();
      }
      
      _scanMessage = '扫描完成！';
      
    } catch (e) {
      _errorMessage = '扫描照片时出错: $e';
      _scanMessage = '扫描失败';
      print('❌ Error scanning photos: $e');
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  // 加载更多照片（分页）
  Future<void> loadMorePhotos() async {
    if (_isLoading || !_hasMorePhotos) return;

    _isLoading = true;
    notifyListeners();

    try {
      List<PhotoModel> newPhotos;
      
      switch (_currentView) {
        case 'large':
          newPhotos = await DatabaseService.getPhotosBySize(
            page: _currentPage,
            pageSize: _pageSize,
          );
          break;
        case 'duplicates':
          if (_currentPage == 0) {
            newPhotos = await DatabaseService.getDuplicatePhotos();
            _hasMorePhotos = false; // 重复照片一次性加载完
          } else {
            newPhotos = [];
          }
          break;
        default:
          newPhotos = await OptimizedPhotoService.getPhotosWithPagination(
            page: _currentPage,
            pageSize: _pageSize,
            sortBy: 'date',
            ascending: false,
          );
          break;
      }

      if (newPhotos.isEmpty) {
        _hasMorePhotos = false;
      } else {
        _photos.addAll(newPhotos);
        _currentPage++;
      }

    } catch (e) {
      _errorMessage = '加载照片时出错: $e';
      print('❌ Error loading photos: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 快速加载相册列表
  Future<void> loadAlbumsQuick() async {
    try {
      _albums = await OptimizedPhotoService.getAlbumsQuick();
      notifyListeners();
    } catch (e) {
      print('❌ Error loading albums: $e');
    }
  }

  // 异步查找重复照片
  Future<void> _findDuplicatesAsync() async {
    try {
      _duplicatePhotos = await DatabaseService.getDuplicatePhotos();
      notifyListeners();
    } catch (e) {
      print('❌ Error finding duplicates: $e');
    }
  }

  // 异步查找大文件
  Future<void> _findLargeFilesAsync() async {
    try {
      _largePhotos = await DatabaseService.getPhotosBySize(
        page: 0,
        pageSize: 100,
      );
      notifyListeners();
    } catch (e) {
      print('❌ Error finding large files: $e');
    }
  }

  // 获取相册中的照片（分页）
  Future<List<PhotoModel>> getAlbumPhotos(
    String albumName, {
    int page = 0,
    int pageSize = 50,
  }) async {
    try {
      return await OptimizedPhotoService.getPhotosFromAlbumPaged(
        albumName,
        page: page,
        pageSize: pageSize,
      );
    } catch (e) {
      print('❌ Error getting album photos: $e');
      return [];
    }
  }

  // 删除照片
  Future<void> deletePhoto(String photoId) async {
    try {
      // 从列表中移除
      _photos.removeWhere((photo) => photo.id == photoId);
      _duplicatePhotos.removeWhere((photo) => photo.id == photoId);
      _largePhotos.removeWhere((photo) => photo.id == photoId);
      
      // 从数据库标记删除
      await DatabaseService.deletePhoto(photoId);
      
      // 更新总数
      _totalPhotos = await OptimizedPhotoService.getTotalPhotosCount();
      
      notifyListeners();
    } catch (e) {
      _errorMessage = '删除照片时出错: $e';
      print('❌ Error deleting photo: $e');
    }
  }

  // 刷新数据
  Future<void> refresh() async {
    _resetPagination();
    await loadMorePhotos();
  }

  // 后台扫描（不阻塞UI）
  Future<void> backgroundScan() async {
    try {
      await OptimizedPhotoService.backgroundScan(
        onProgress: (progress, message) {
          // 静默更新，不通知UI
          _scanProgress = progress;
          _scanMessage = message;
        },
      );
      
      // 完成后更新总数
      _totalPhotos = await OptimizedPhotoService.getTotalPhotosCount();
      notifyListeners();
    } catch (e) {
      print('❌ Background scan error: $e');
    }
  }

  // 获取照片的完整信息（延迟加载）
  Future<PhotoModel?> getFullPhotoInfo(String photoId) async {
    try {
      return await OptimizedPhotoService.loadFullPhotoInfo(photoId);
    } catch (e) {
      print('❌ Error getting full photo info: $e');
      return null;
    }
  }

  // 清空所有数据
  void clearAll() {
    _photos.clear();
    _duplicatePhotos.clear();
    _largePhotos.clear();
    _albums.clear();
    _monthlyProgress.clear();
    _resetPagination();
    _totalPhotos = 0;
    _errorMessage = '';
    _scanProgress = 0;
    _scanMessage = '';
    notifyListeners();
  }
}