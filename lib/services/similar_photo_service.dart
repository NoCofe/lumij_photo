import 'dart:io';
import 'dart:typed_data';
import 'dart:math';
import 'package:image/image.dart' as img;
import 'package:photo_manager/photo_manager.dart';
import '../models/photo_model.dart';
import '../models/similar_photo_group.dart';

class SimilarPhotoService {
  // 相似度阈值
  static const double defaultSimilarityThreshold = 0.85;
  
  // 进度回调
  static Function(double progress, String message)? _progressCallback;
  
  static void setProgressCallback(Function(double progress, String message)? callback) {
    _progressCallback = callback;
  }
  
  static void _reportProgress(double progress, String message) {
    if (_progressCallback != null) {
      _progressCallback!(progress, message);
    }
    print('📊 [SimilarPhotos] $progress% - $message');
  }

  // 计算图像感知哈希 (pHash)
  static Future<String> calculatePerceptualHash(AssetEntity asset) async {
    try {
      // 获取缩略图数据
      final thumbnailData = await asset.thumbnailDataWithSize(
        const ThumbnailSize(64, 64),
        quality: 70,
      );
      
      if (thumbnailData == null) return '';
      
      // 解码图像
      final image = img.decodeImage(thumbnailData);
      if (image == null) return '';
      
      // 转换为灰度并调整大小到8x8
      final grayscale = img.grayscale(image);
      final resized = img.copyResize(grayscale, width: 8, height: 8);
      
      // 计算平均值
      int sum = 0;
      for (int y = 0; y < 8; y++) {
        for (int x = 0; x < 8; x++) {
          final pixel = resized.getPixel(x, y);
          sum += img.getLuminance(pixel).toInt();
        }
      }
      final average = sum / 64;
      
      // 生成哈希值
      String hash = '';
      for (int y = 0; y < 8; y++) {
        for (int x = 0; x < 8; x++) {
          final pixel = resized.getPixel(x, y);
          final luminance = img.getLuminance(pixel);
          hash += luminance > average ? '1' : '0';
        }
      }
      
      return hash;
    } catch (e) {
      print('❌ Error calculating perceptual hash: $e');
      return '';
    }
  }

  // 计算两个哈希值的汉明距离（相似度）
  static double calculateSimilarity(String hash1, String hash2) {
    if (hash1.isEmpty || hash2.isEmpty || hash1.length != hash2.length) {
      return 0.0;
    }
    
    int differences = 0;
    for (int i = 0; i < hash1.length; i++) {
      if (hash1[i] != hash2[i]) {
        differences++;
      }
    }
    
    // 转换为相似度百分比
    return 1.0 - (differences / hash1.length);
  }

  // 扫描并分析相似照片
  static Future<List<SimilarPhotoGroup>> analyzeSimilarPhotos(
    List<PhotoModel> photos, {
    double similarityThreshold = defaultSimilarityThreshold,
    Function(double progress, String message)? onProgress,
  }) async {
    _progressCallback = onProgress;
    _reportProgress(0, '开始分析相似照片...');
    
    try {
      // 第一步：计算所有照片的感知哈希
      Map<String, String> photoHashes = {};
      for (int i = 0; i < photos.length; i++) {
        final photo = photos[i];
        _reportProgress(
          (i / photos.length) * 50,
          '计算照片特征 ${i + 1}/${photos.length}'
        );
        
        try {
          final asset = await AssetEntity.fromId(photo.id);
          if (asset != null) {
            final hash = await calculatePerceptualHash(asset);
            if (hash.isNotEmpty) {
              photoHashes[photo.id] = hash;
            }
          }
        } catch (e) {
          print('❌ Error processing photo ${photo.id}: $e');
        }
      }
      
      _reportProgress(50, '开始分组相似照片...');
      
      // 第二步：根据相似度分组
      List<SimilarPhotoGroup> groups = [];
      Set<String> processedPhotos = {};
      
      int comparisonCount = 0;
      final totalComparisons = photoHashes.length * (photoHashes.length - 1) / 2;
      
      for (final entry1 in photoHashes.entries) {
        if (processedPhotos.contains(entry1.key)) continue;
        
        List<PhotoModel> similarPhotos = [];
        List<double> similarities = [];
        
        // 添加当前照片作为组的第一个
        final currentPhoto = photos.firstWhere((p) => p.id == entry1.key);
        similarPhotos.add(currentPhoto);
        similarities.add(1.0); // 自己与自己相似度为100%
        
        // 查找相似的照片
        for (final entry2 in photoHashes.entries) {
          if (entry1.key == entry2.key || processedPhotos.contains(entry2.key)) {
            continue;
          }
          
          final similarity = calculateSimilarity(entry1.value, entry2.value);
          comparisonCount++;
          
          if (comparisonCount % 100 == 0) {
            _reportProgress(
              50 + (comparisonCount / totalComparisons) * 45,
              '分析相似度 ${comparisonCount.toInt()}/${totalComparisons.toInt()}'
            );
          }
          
          if (similarity >= similarityThreshold) {
            final similarPhoto = photos.firstWhere((p) => p.id == entry2.key);
            similarPhotos.add(similarPhoto);
            similarities.add(similarity);
            processedPhotos.add(entry2.key);
          }
        }
        
        // 如果找到了相似照片（除了自己），创建分组
        if (similarPhotos.length > 1) {
          // 按文件大小排序（大的在前，便于删除小的）
          final indexedPhotos = List.generate(
            similarPhotos.length,
            (index) => {'photo': similarPhotos[index], 'similarity': similarities[index]},
          );
          
          indexedPhotos.sort((a, b) => b['photo'].size.compareTo(a['photo'].size));
          
          final group = SimilarPhotoGroup(
            id: 'group_${DateTime.now().millisecondsSinceEpoch}_${groups.length}',
            photos: indexedPhotos.map((item) => item['photo'] as PhotoModel).toList(),
            similarities: indexedPhotos.map((item) => item['similarity'] as double).toList(),
            primaryPhoto: indexedPhotos.first['photo'] as PhotoModel, // 最大的照片作为主照片
            groupType: _determineGroupType(similarPhotos),
          );
          
          groups.add(group);
        }
        
        processedPhotos.add(entry1.key);
      }
      
      // 第三步：按相似照片数量排序（问题最严重的在前）
      groups.sort((a, b) => b.photos.length.compareTo(a.photos.length));
      
      _reportProgress(100, '完成！找到 ${groups.length} 组相似照片');
      return groups;
      
    } catch (e) {
      _reportProgress(0, '分析失败: $e');
      print('❌ Error analyzing similar photos: $e');
      return [];
    }
  }

  // 确定分组类型
  static SimilarGroupType _determineGroupType(List<PhotoModel> photos) {
    if (photos.length >= 5) {
      return SimilarGroupType.burst; // 连拍
    } else if (photos.length >= 3) {
      return SimilarGroupType.similar; // 相似
    } else {
      return SimilarGroupType.duplicate; // 重复
    }
  }

  // 智能推荐要删除的照片
  static List<PhotoModel> recommendPhotosToDelete(SimilarPhotoGroup group) {
    List<PhotoModel> toDelete = [];
    
    // 保留最大最清晰的照片，删除其他
    if (group.photos.isNotEmpty) {
      // 按质量排序：文件大小 > 分辨率 > 日期
      final sortedPhotos = List<PhotoModel>.from(group.photos);
      sortedPhotos.sort((a, b) {
        // 优先按文件大小
        final sizeCompare = b.size.compareTo(a.size);
        if (sizeCompare != 0) return sizeCompare;
        
        // 然后按分辨率
        final resolutionA = a.width * a.height;
        final resolutionB = b.width * b.height;
        final resolutionCompare = resolutionB.compareTo(resolutionA);
        if (resolutionCompare != 0) return resolutionCompare;
        
        // 最后按日期（新的在前）
        return b.dateTime.compareTo(a.dateTime);
      });
      
      // 保留第一张（最好的），其他建议删除
      for (int i = 1; i < sortedPhotos.length; i++) {
        toDelete.add(sortedPhotos[i]);
      }
    }
    
    return toDelete;
  }

  // 计算可节省的空间
  static int calculateSpaceSaving(List<PhotoModel> photosToDelete) {
    return photosToDelete.fold(0, (sum, photo) => sum + photo.size);
  }

  // 快速检测是否为连拍照片
  static bool isBurstPhotos(List<PhotoModel> photos) {
    if (photos.length < 3) return false;
    
    // 检查时间间隔（连拍通常在几秒内）
    photos.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    for (int i = 1; i < photos.length; i++) {
      final timeDiff = photos[i].dateTime.difference(photos[i - 1].dateTime);
      if (timeDiff.inSeconds > 5) {
        return false; // 超过5秒间隔不太可能是连拍
      }
    }
    
    return true;
  }

  // 分析照片质量得分
  static double calculateQualityScore(PhotoModel photo) {
    // 基于文件大小、分辨率等因素的质量评分
    final resolution = photo.width * photo.height;
    final sizeScore = (photo.size / (1024 * 1024)).clamp(0, 10); // MB转换为0-10分
    final resolutionScore = (resolution / 1000000).clamp(0, 10); // 百万像素转换为0-10分
    
    return (sizeScore + resolutionScore) / 2;
  }

  // 创建预览缩略图对比
  static Future<List<Uint8List?>> createComparisonThumbnails(
    List<PhotoModel> photos
  ) async {
    List<Uint8List?> thumbnails = [];
    
    for (final photo in photos) {
      try {
        final asset = await AssetEntity.fromId(photo.id);
        if (asset != null) {
          final thumbnail = await asset.thumbnailDataWithSize(
            const ThumbnailSize(200, 200),
            quality: 80,
          );
          thumbnails.add(thumbnail);
        } else {
          thumbnails.add(null);
        }
      } catch (e) {
        print('❌ Error creating thumbnail for ${photo.id}: $e');
        thumbnails.add(null);
      }
    }
    
    return thumbnails;
  }
}