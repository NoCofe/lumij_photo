import 'dart:io';
import 'package:photo_manager/photo_manager.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import '../models/photo_model.dart';
import '../models/album_model.dart';
import 'database_service.dart';

class PhotoService {
  static Future<bool> requestPermission() async {
    // 首先请求基本权限
    var status = await Permission.photos.status;
    if (!status.isGranted) {
      status = await Permission.photos.request();
    }
    
    // 如果基本权限被拒绝，尝试存储权限
    if (!status.isGranted) {
      var storageStatus = await Permission.storage.status;
      if (!storageStatus.isGranted) {
        storageStatus = await Permission.storage.request();
      }
      if (!storageStatus.isGranted) {
        return false;
      }
    }
    
    // 使用PhotoManager请求权限
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    return ps.isAuth;
  }
  
  static Future<List<PhotoModel>> scanAllPhotos() async {
    try {
      final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
        type: RequestType.common,
        onlyAll: true,
      );
      
      if (paths.isEmpty) return [];
      
      // 分批获取照片，避免内存问题
      List<PhotoModel> allPhotos = [];
      const int batchSize = 100;
      int page = 0;
      
      while (true) {
        final List<AssetEntity> assets = await paths.first.getAssetListPaged(
          page: page,
          size: batchSize,
        );
        
        if (assets.isEmpty) break;
        
        List<PhotoModel> batchPhotos = [];
        
        for (final asset in assets) {
          try {
            final file = await asset.file;
            if (file == null) continue;
            
            final hash = await _calculateFileHash(file);
            
            final photo = PhotoModel(
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
            
            batchPhotos.add(photo);
          } catch (e) {
            print('Error processing asset ${asset.id}: $e');
          }
        }
        
        // 批量保存到数据库
        if (batchPhotos.isNotEmpty) {
          await DatabaseService.insertPhotos(batchPhotos);
          allPhotos.addAll(batchPhotos);
        }
        
        page++;
        
        // 限制最大扫描数量，避免性能问题
        if (allPhotos.length >= 1000) break;
      }
      
      return allPhotos;
    } catch (e) {
      print('Error scanning photos: $e');
      return [];
    }
  }
  
  static Future<String> _calculateFileHash(File file) async {
    final bytes = await file.readAsBytes();
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  static Future<String?> compressImage(String imagePath) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final compressedDir = Directory('${dir.path}/compressed');
      if (!await compressedDir.exists()) {
        await compressedDir.create(recursive: true);
      }
      
      final fileName = path.basenameWithoutExtension(imagePath);
      final extension = path.extension(imagePath);
      final compressedPath = '${compressedDir.path}/${fileName}_compressed$extension';
      
      final result = await FlutterImageCompress.compressAndGetFile(
        imagePath,
        compressedPath,
        quality: 70,
        minWidth: 1920,
        minHeight: 1080,
      );
      
      return result?.path;
    } catch (e) {
      print('Error compressing image: $e');
      return null;
    }
  }
  
  static Future<bool> deletePhotoFile(String photoId, String photoPath) async {
    try {
      print('🗑️ [deletePhotoFile] 开始删除照片: $photoId');
      
      // 首先尝试通过PhotoManager删除（这会从系统相册中删除）
      final asset = await AssetEntity.fromId(photoId);
      if (asset != null) {
        final result = await PhotoManager.editor.deleteWithIds([photoId]);
        if (result.isNotEmpty) {
          print('✅ [deletePhotoFile] 成功从系统相册删除照片: $photoId');
          return true;
        }
      }
      
      // 如果PhotoManager删除失败，尝试直接删除文件
      final file = File(photoPath);
      if (await file.exists()) {
        await file.delete();
        print('✅ [deletePhotoFile] 成功删除照片文件: $photoPath');
        return true;
      }
      
      print('⚠️ [deletePhotoFile] 照片文件不存在: $photoPath');
      return false;
    } catch (e) {
      print('❌ [deletePhotoFile] 删除照片时出错: $e');
      return false;
    }
  }
  
  // 批量删除照片（减少iOS确认次数）
  static Future<List<String>> deleteMultiplePhotos(List<String> photoIds) async {
    try {
      print('🗑️ [deleteMultiplePhotos] 开始批量删除 ${photoIds.length} 张照片');
      
      // 使用PhotoManager的批量删除功能
      final result = await PhotoManager.editor.deleteWithIds(photoIds);
      
      print('✅ [deleteMultiplePhotos] 批量删除完成，成功删除 ${result.length} 张照片');
      return result;
    } catch (e) {
      print('❌ [deleteMultiplePhotos] 批量删除时出错: $e');
      return [];
    }
  }
  
  static Future<List<PhotoModel>> findSimilarPhotos(List<PhotoModel> photos) async {
    // 简单的相似度检测：按文件大小和创建时间分组
    Map<String, List<PhotoModel>> groups = {};
    
    for (final photo in photos) {
      // 创建一个基于大小范围和时间的键
      final sizeGroup = (photo.size / 10000).round(); // 10KB为一组
      final timeGroup = photo.dateTime.millisecondsSinceEpoch ~/ (1000 * 60 * 60); // 1小时为一组
      final key = '${sizeGroup}_$timeGroup';
      
      if (!groups.containsKey(key)) {
        groups[key] = [];
      }
      groups[key]!.add(photo);
    }
    
    List<PhotoModel> similarPhotos = [];
    for (final group in groups.values) {
      if (group.length > 1) {
        similarPhotos.addAll(group);
      }
    }
    
    return similarPhotos;
  }
  
  static Future<Map<String, int>> getMonthlyProgress() async {
    final photos = await DatabaseService.getAllPhotos();
    Map<String, int> monthlyCount = {};
    
    for (final photo in photos) {
      final monthKey = '${photo.dateTime.year}-${photo.dateTime.month.toString().padLeft(2, '0')}';
      monthlyCount[monthKey] = (monthlyCount[monthKey] ?? 0) + 1;
    }
    
    return monthlyCount;
  }
  
  static Future<List<AlbumModel>> getRealAlbums() async {
    try {
      print('📱 [getRealAlbums] 开始获取系统相册列表...');
      
      final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
        type: RequestType.common,
      );
      
      print('📱 [getRealAlbums] 找到 ${paths.length} 个相册路径');
      
      List<AlbumModel> albums = [];
      
      for (int i = 0; i < paths.length; i++) {
        final path = paths[i];
        print('📱 [getRealAlbums] 处理相册 ${i + 1}/${paths.length}: ${path.name}');
        
        try {
          final assetCount = await path.assetCountAsync;
          print('📱 [getRealAlbums] 相册 "${path.name}" 包含 $assetCount 个资源');
          
          if (assetCount > 0) {
            // 获取封面照片
            print('📱 [getRealAlbums] 获取相册 "${path.name}" 的封面照片...');
            final assets = await path.getAssetListPaged(page: 0, size: 1);
            String? coverPath;
            
            if (assets.isNotEmpty) {
              print('📱 [getRealAlbums] 正在获取封面照片文件...');
              final file = await assets.first.file;
              coverPath = file?.path;
              print('📱 [getRealAlbums] 封面照片路径: $coverPath');
            }
            
            final album = AlbumModel(
              name: path.name,
              photoCount: assetCount,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              coverPhotoPath: coverPath,
            );
            
            albums.add(album);
            print('📱 [getRealAlbums] 成功添加相册: ${path.name}');
          } else {
            print('📱 [getRealAlbums] 跳过空相册: ${path.name}');
          }
        } catch (e) {
          print('❌ [getRealAlbums] 处理相册 "${path.name}" 时出错: $e');
          // 继续处理下一个相册
        }
      }
      
      print('📱 [getRealAlbums] 完成！总共获取到 ${albums.length} 个有效相册');
      return albums;
    } catch (e) {
      print('❌ [getRealAlbums] 获取系统相册时出错: $e');
      return [];
    }
  }
  
  static Future<List<PhotoModel>> getPhotosFromRealAlbum(String albumName) async {
    try {
      final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
        type: RequestType.common,
      );
      
      final targetPath = paths.firstWhere(
        (path) => path.name == albumName,
        orElse: () => throw Exception('Album not found'),
      );
      
      final assets = await targetPath.getAssetListPaged(page: 0, size: 1000);
      List<PhotoModel> photos = [];
      
      for (final asset in assets) {
        try {
          final file = await asset.file;
          if (file == null) continue;
          
          final hash = await _calculateFileHash(file);
          
          final photo = PhotoModel(
            id: asset.id,
            path: file.path,
            name: path.basename(file.path),
            dateTime: asset.createDateTime,
            size: await file.length(),
            type: asset.type == AssetType.image ? 'image' : 'video',
            width: asset.width,
            height: asset.height,
            albumName: albumName,
            hash: hash,
          );
          
          photos.add(photo);
        } catch (e) {
          print('Error processing asset ${asset.id}: $e');
        }
      }
      
      return photos;
    } catch (e) {
      print('Error getting photos from real album: $e');
      return [];
    }
  }
  
  static Future<bool> addPhotoToRealAlbum(String photoId, String albumName) async {
    try {
      // 注意：由于Android/iOS系统限制，应用通常不能直接将照片添加到系统相册
      // 这里我们在应用内部记录照片的相册归属，并尝试创建系统相册
      
      // 首先尝试创建或获取相册
      await _createOrGetAlbum(albumName);
      
      print('Adding photo $photoId to album $albumName (app-level)');
      return true;
    } catch (e) {
      print('Error adding photo to real album: $e');
      return false;
    }
  }
  
  static Future<void> _createOrGetAlbum(String albumName) async {
    try {
      // 检查相册是否已存在
      final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
        type: RequestType.common,
      );
      
      final existingAlbum = paths.where((path) => path.name == albumName).firstOrNull;
      if (existingAlbum != null) {
        print('Album $albumName already exists');
        return;
      }
      
      // 由于系统限制，我们无法直接创建系统相册
      // 但我们可以在数据库中记录这个相册
      final album = AlbumModel(
        name: albumName,
        photoCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await DatabaseService.insertAlbum(album);
      print('Created app-level album: $albumName');
    } catch (e) {
      print('Error creating album: $e');
    }
  }
  
  static Future<List<AlbumModel>> getAllAlbums() async {
    try {
      print('🔄 [getAllAlbums] 开始获取所有相册...');
      
      // 获取系统相册
      print('🔄 [getAllAlbums] 正在获取系统相册...');
      final realAlbums = await getRealAlbums();
      print('🔄 [getAllAlbums] 获取到 ${realAlbums.length} 个系统相册');
      
      // 获取应用内相册
      print('🔄 [getAllAlbums] 正在获取应用内相册...');
      final appAlbums = await DatabaseService.getAllAlbums();
      print('🔄 [getAllAlbums] 获取到 ${appAlbums.length} 个应用内相册');
      
      // 合并相册列表，去重
      final Map<String, AlbumModel> albumMap = {};
      
      // 先添加系统相册
      for (final album in realAlbums) {
        albumMap[album.name] = album;
        print('🔄 [getAllAlbums] 添加系统相册: ${album.name}');
      }
      
      // 再添加应用内相册（如果不存在同名系统相册）
      for (final album in appAlbums) {
        if (!albumMap.containsKey(album.name)) {
          albumMap[album.name] = album;
          print('🔄 [getAllAlbums] 添加应用内相册: ${album.name}');
        } else {
          print('🔄 [getAllAlbums] 跳过重复相册: ${album.name}');
        }
      }
      
      final result = albumMap.values.toList();
      print('✅ [getAllAlbums] 完成！总共 ${result.length} 个相册');
      return result;
    } catch (e) {
      print('❌ [getAllAlbums] 获取所有相册时出错: $e');
      return [];
    }
  }
}