import 'photo_model.dart';

enum SimilarGroupType {
  duplicate,  // 重复照片 (2张，相似度>95%)
  similar,    // 相似照片 (3-4张，相似度>85%)
  burst,      // 连拍照片 (5张+，时间间隔<5秒)
}

class SimilarPhotoGroup {
  final String id;
  final List<PhotoModel> photos;
  final List<double> similarities; // 每张照片与主照片的相似度
  final PhotoModel primaryPhoto; // 主照片（质量最好的）
  final SimilarGroupType groupType;
  final DateTime createdAt;
  
  // 选择状态（用于批量操作）
  Map<String, bool> selectedPhotos;
  
  SimilarPhotoGroup({
    required this.id,
    required this.photos,
    required this.similarities,
    required this.primaryPhoto,
    required this.groupType,
    DateTime? createdAt,
    Map<String, bool>? selectedPhotos,
  }) : 
    createdAt = createdAt ?? DateTime.now(),
    selectedPhotos = selectedPhotos ?? {};

  // 获取分组标题
  String get groupTitle {
    switch (groupType) {
      case SimilarGroupType.duplicate:
        return '重复照片';
      case SimilarGroupType.similar:
        return '相似照片';
      case SimilarGroupType.burst:
        return '连拍照片';
    }
  }
  
  // 获取分组描述
  String get groupDescription {
    switch (groupType) {
      case SimilarGroupType.duplicate:
        return '${photos.length}张重复照片';
      case SimilarGroupType.similar:
        return '${photos.length}张相似照片';
      case SimilarGroupType.burst:
        return '${photos.length}张连拍照片';
    }
  }
  
  // 获取分组颜色
  String get groupColor {
    switch (groupType) {
      case SimilarGroupType.duplicate:
        return 'red'; // 红色 - 完全重复，强烈建议删除
      case SimilarGroupType.similar:
        return 'orange'; // 橙色 - 相似，建议筛选
      case SimilarGroupType.burst:
        return 'blue'; // 蓝色 - 连拍，可选择保留最佳
    }
  }
  
  // 计算平均相似度
  double get averageSimilarity {
    if (similarities.isEmpty) return 0.0;
    return similarities.reduce((a, b) => a + b) / similarities.length;
  }
  
  // 计算总文件大小
  int get totalSize {
    return photos.fold(0, (sum, photo) => sum + photo.size);
  }
  
  // 获取选中的照片
  List<PhotoModel> get selectedPhotosList {
    return photos.where((photo) => selectedPhotos[photo.id] == true).toList();
  }
  
  // 获取未选中的照片（建议保留的）
  List<PhotoModel> get unselectedPhotosList {
    return photos.where((photo) => selectedPhotos[photo.id] != true).toList();
  }
  
  // 计算选中照片的总大小
  int get selectedPhotosSize {
    return selectedPhotosList.fold(0, (sum, photo) => sum + photo.size);
  }
  
  // 切换照片选择状态
  void togglePhotoSelection(String photoId) {
    selectedPhotos[photoId] = !(selectedPhotos[photoId] ?? false);
  }
  
  // 选择所有照片
  void selectAllPhotos() {
    for (final photo in photos) {
      selectedPhotos[photo.id] = true;
    }
  }
  
  // 取消选择所有照片
  void deselectAllPhotos() {
    selectedPhotos.clear();
  }
  
  // 智能选择（保留最好的，选择其他删除）
  void smartSelect() {
    deselectAllPhotos();
    
    // 按质量排序，保留最好的一张
    final sortedPhotos = List<PhotoModel>.from(photos);
    sortedPhotos.sort((a, b) {
      // 文件大小优先
      final sizeCompare = b.size.compareTo(a.size);
      if (sizeCompare != 0) return sizeCompare;
      
      // 分辨率次之
      final resolutionA = a.width * a.height;
      final resolutionB = b.width * b.height;
      final resolutionCompare = resolutionB.compareTo(resolutionA);
      if (resolutionCompare != 0) return resolutionCompare;
      
      // 日期最后
      return b.dateTime.compareTo(a.dateTime);
    });
    
    // 选择除第一张外的所有照片删除
    for (int i = 1; i < sortedPhotos.length; i++) {
      selectedPhotos[sortedPhotos[i].id] = true;
    }
  }
  
  // 检查是否有照片被选中
  bool get hasSelectedPhotos {
    return selectedPhotos.values.any((selected) => selected);
  }
  
  // 获取建议保留的照片（质量最好的）
  PhotoModel get recommendedKeepPhoto {
    if (photos.isEmpty) return primaryPhoto;
    
    return photos.reduce((a, b) {
      // 比较文件大小
      if (a.size != b.size) {
        return a.size > b.size ? a : b;
      }
      
      // 比较分辨率
      final resolutionA = a.width * a.height;
      final resolutionB = b.width * b.height;
      if (resolutionA != resolutionB) {
        return resolutionA > resolutionB ? a : b;
      }
      
      // 比较日期（新的优先）
      return a.dateTime.isAfter(b.dateTime) ? a : b;
    });
  }
  
  // 转换为Map（用于存储）
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'photos': photos.map((p) => p.toMap()).toList(),
      'similarities': similarities,
      'primaryPhotoId': primaryPhoto.id,
      'groupType': groupType.index,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'selectedPhotos': selectedPhotos,
    };
  }
  
  // 从Map创建对象
  static SimilarPhotoGroup fromMap(Map<String, dynamic> map) {
    final photoMaps = List<Map<String, dynamic>>.from(map['photos']);
    final photos = photoMaps.map((p) => PhotoModel.fromMap(p)).toList();
    final primaryPhotoId = map['primaryPhotoId'] as String;
    final primaryPhoto = photos.firstWhere((p) => p.id == primaryPhotoId);
    
    return SimilarPhotoGroup(
      id: map['id'],
      photos: photos,
      similarities: List<double>.from(map['similarities']),
      primaryPhoto: primaryPhoto,
      groupType: SimilarGroupType.values[map['groupType']],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      selectedPhotos: Map<String, bool>.from(map['selectedPhotos'] ?? {}),
    );
  }
  
  @override
  String toString() {
    return 'SimilarPhotoGroup(id: $id, type: $groupType, photos: ${photos.length}, avgSimilarity: ${averageSimilarity.toStringAsFixed(2)})';
  }
}