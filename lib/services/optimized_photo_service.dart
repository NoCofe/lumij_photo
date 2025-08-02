import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;
import 'package:photo_manager/photo_manager.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import '../models/photo_model.dart';
import '../models/album_model.dart';
import 'database_service.dart';

class OptimizedPhotoService {
  // 扫描进度回调
  static Function(double progress, String message)? _progressCallback;
  
  // 设置进度回调
  static void setProgressCallback(Function(double progress, String message)? callback) {
    _progressCallback = callback;
  }
  
  // 报告进度
  static void _reportProgress(double progress, String message) {
    if (_progressCallback != null) {
      _progressCallback!(progress, message);
    }
    print('📊 [Progress] $progress% - $message');
  }

  // 请求权限
  static Future<bool> requestPermission() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    return ps.isAuth;
  }

  // 优化的相册扫描 - 支持大量照片和后台处理
  static Future<List<PhotoModel>> scanAllPhotosOptimized({
    int? maxPhotos,
    bool calculateHash = false,
    Function(double progress, String message)? onProgress,
  }) async {
    try {
      _progressCallback = onProgress;
      _reportProgress(0, '开始扫描相册...');
      
      final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
        type: RequestType.common,
        onlyAll: true,
      );
      
      if (paths.isEmpty) {
        _reportProgress(100, '未找到相册');
        return [];
      }

      final mainPath = paths.first;
      final totalCount = await mainPath.assetCountAsync;
      _reportProgress(10, '发现 $totalCount 张照片');
      
      List<PhotoModel> allPhotos = [];
      const int batchSize = 50; // 减小批次大小提高响应性
      int processedCount = 0;
      int page = 0;
      
      // 限制最大扫描数量
      final scanLimit = maxPhotos ?? totalCount;
      _reportProgress(15, '准备处理 ${scanLimit > totalCount ? totalCount : scanLimit} 张照片');

      while (processedCount < scanLimit) {
        final remainingCount = scanLimit - processedCount;
        final currentBatchSize = remainingCount < batchSize ? remainingCount : batchSize;
        
        final List<AssetEntity> assets = await mainPath.getAssetListPaged(
          page: page,
          size: currentBatchSize,
        );
        
        if (assets.isEmpty) break;

        _reportProgress(
          20 + (processedCount / scanLimit) * 70,
          '处理第 ${processedCount + 1} - ${processedCount + assets.length} 张照片'
        );

        // 处理当前批次
        final batchPhotos = await _processBatch(
          assets, 
          calculateHash: calculateHash,
          batchNumber: page + 1,
        );
        
        // 批量保存到数据库
        if (batchPhotos.isNotEmpty) {
          await DatabaseService.insertPhotos(batchPhotos);
          allPhotos.addAll(batchPhotos);
        }
        
        processedCount += assets.length;
        page++;
        
        // 短暂延迟，避免UI阻塞
        await Future.delayed(const Duration(milliseconds: 10));
      }
      
      _reportProgress(95, '扫描完成，正在整理数据...');
      
      // 按日期排序
      allPhotos.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      
      _reportProgress(100, '完成！共处理 ${allPhotos.length} 张照片');
      return allPhotos;
      
    } catch (e) {
      _reportProgress(0, '扫描出错: $e');
      print('❌ Error scanning photos: $e');
      return [];
    }
  }

  // 批量处理照片
  static Future<List<PhotoModel>> _processBatch(
    List<AssetEntity> assets, {
    required bool calculateHash,
    required int batchNumber,
  }) async {
    List<PhotoModel> batchPhotos = [];
    
    for (int i = 0; i < assets.length; i++) {
      final asset = assets[i];
      try {
        // 获取基本信息（不需要文件访问）
        final photo = PhotoModel(
          id: asset.id,
          path: '', // 暂时为空，避免文件访问
          name: '${asset.title ?? 'Unknown'}.${_getFileExtension(asset)}',
          dateTime: asset.createDateTime,
          size: asset.size,
          type: asset.type == AssetType.image ? 'image' : 'video',
          width: asset.width,
          height: asset.height,
          hash: calculateHash ? await _calculateAssetHashOptimized(asset) : '',
        );
        
        batchPhotos.add(photo);
      } catch (e) {
        print('❌ Error processing asset ${asset.id}: $e');
      }
    }
    
    return batchPhotos;
  }

  // 优化的哈希计算 - 仅在需要时计算
  static Future<String> _calculateAssetHashOptimized(AssetEntity asset) async {
    try {
      // 对于大文件，只计算部分内容的哈希
      if (asset.size > 50 * 1024 * 1024) { // 50MB以上
        return _calculateThumbnailHash(asset);
      }
      
      final file = await asset.file;
      if (file == null) return '';
      
      // 小文件计算完整哈希
      final bytes = await file.readAsBytes();
      final digest = sha256.convert(bytes);
      return digest.toString();
    } catch (e) {
      print('❌ Error calculating hash for ${asset.id}: $e');
      return '';
    }
  }

  // 计算缩略图哈希（用于大文件）
  static Future<String> _calculateThumbnailHash(AssetEntity asset) async {
    try {
      final thumbnail = await asset.thumbnailDataWithSize(
        const ThumbnailSize(200, 200),
        quality: 80,
      );
      
      if (thumbnail != null) {
        final digest = sha256.convert(thumbnail);
        return 'thumb_${digest.toString()}';
      }
      
      return 'thumb_${asset.id}';
    } catch (e) {
      print('❌ Error calculating thumbnail hash: $e');
      return 'thumb_${asset.id}';
    }
  }

  // 获取文件扩展名
  static String _getFileExtension(AssetEntity asset) {
    switch (asset.type) {
      case AssetType.image:
        return 'jpg';
      case AssetType.video:
        return 'mp4';
      default:
        return 'unknown';
    }
  }

  // 分页获取照片（解决50张限制问题）
  static Future<List<PhotoModel>> getPhotosWithPagination({
    int page = 0,
    int pageSize = 100,
    String sortBy = 'date', // 'date', 'size', 'name'
    bool ascending = false,
  }) async {
    try {
      final db = await DatabaseService.database;
      
      String orderBy;
      switch (sortBy) {
        case 'size':
          orderBy = 'size ${ascending ? 'ASC' : 'DESC'}';
          break;
        case 'name':
          orderBy = 'name ${ascending ? 'ASC' : 'DESC'}';
          break;
        case 'date':
        default:
          orderBy = 'dateTime ${ascending ? 'ASC' : 'DESC'}';
          break;
      }
      
      final List<Map<String, dynamic>> maps = await db.query(
        'photos',
        where: 'isDeleted = 0',
        orderBy: orderBy,
        limit: pageSize,
        offset: page * pageSize,
      );
      
      return List.generate(maps.length, (i) => PhotoModel.fromMap(maps[i]));
    } catch (e) {
      print('❌ Error getting photos with pagination: $e');
      return [];
    }
  }

  // 获取照片总数
  static Future<int> getTotalPhotosCount() async {
    try {
      final db = await DatabaseService.database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM photos WHERE isDeleted = 0'
      );
      return result.first['count'] as int;
    } catch (e) {
      print('❌ Error getting total photos count: $e');
      return 0;
    }
  }

  // 快速获取相册列表（不加载封面）
  static Future<List<AlbumModel>> getAlbumsQuick() async {
    try {
      _reportProgress(0, '快速扫描相册...');
      
      final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
        type: RequestType.common,
      );
      
      List<AlbumModel> albums = [];
      
      for (int i = 0; i < paths.length; i++) {
        final path = paths[i];
        try {
          final assetCount = await path.assetCountAsync;
          
          if (assetCount > 0) {
            final album = AlbumModel(
              name: path.name,
              photoCount: assetCount,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              coverPhotoPath: null, // 暂不加载封面，提高速度
            );
            
            albums.add(album);
          }
          
          _reportProgress((i + 1) / paths.length * 100, '扫描相册: ${path.name}');
        } catch (e) {
          print('❌ Error processing album ${path.name}: $e');
        }
      }
      
      _reportProgress(100, '完成！找到 ${albums.length} 个相册');
      return albums;
    } catch (e) {
      print('❌ Error getting albums quickly: $e');
      return [];
    }
  }

  // 获取相册中的照片（支持分页）
  static Future<List<PhotoModel>> getPhotosFromAlbumPaged(
    String albumName, {
    int page = 0,
    int pageSize = 50,
  }) async {
    try {
      final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
        type: RequestType.common,
      );
      
      final targetPath = paths.firstWhere(
        (path) => path.name == albumName,
        orElse: () => throw Exception('Album not found'),
      );
      
      final assets = await targetPath.getAssetListPaged(
        page: page,
        size: pageSize,
      );
      
      List<PhotoModel> photos = [];
      
      for (final asset in assets) {
        try {
          final photo = PhotoModel(
            id: asset.id,
            path: '', // 延迟加载文件路径
            name: '${asset.title ?? 'Unknown'}.${_getFileExtension(asset)}',
            dateTime: asset.createDateTime,
            size: asset.size,
            type: asset.type == AssetType.image ? 'image' : 'video',
            width: asset.width,
            height: asset.height,
            albumName: albumName,
            hash: '', // 延迟计算哈希
          );
          
          photos.add(photo);
        } catch (e) {
          print('❌ Error processing asset ${asset.id}: $e');
        }
      }
      
      return photos;
    } catch (e) {
      print('❌ Error getting photos from album: $e');
      return [];
    }
  }

  // 后台扫描服务
  static Future<void> backgroundScan({
    Function(double progress, String message)? onProgress,
  }) async {
    try {
      await scanAllPhotosOptimized(
        calculateHash: false, // 后台扫描时不计算哈希
        onProgress: onProgress,
      );
    } catch (e) {
      print('❌ Background scan error: $e');
    }
  }

  // 延迟加载照片的完整信息
  static Future<PhotoModel?> loadFullPhotoInfo(String photoId) async {
    try {
      final asset = await AssetEntity.fromId(photoId);
      if (asset == null) return null;
      
      final file = await asset.file;
      if (file == null) return null;
      
      final hash = await _calculateAssetHashOptimized(asset);
      
      return PhotoModel(
        id: asset.id,
        path: file.path,
        name: path.basename(file.path),
        dateTime: asset.createDateTime,
        size: await file.length(),
        type: asset.type == AssetType.image ? 'image' : 'video',
        width: asset.width,
        height: asset.height,
        hash: hash,
      );
    } catch (e) {
      print('❌ Error loading full photo info: $e');
      return null;
    }
  }
}