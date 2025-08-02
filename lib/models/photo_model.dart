class PhotoModel {
  final String id;
  final String path;
  final String name;
  final DateTime dateTime;
  final int size;
  final String type; // 'image' or 'video'
  final int width;
  final int height;
  final String? albumName;
  final bool isDeleted;
  final bool isCompressed;
  final String? compressedPath;
  final String? hash; // 用于重复检测
  
  PhotoModel({
    required this.id,
    required this.path,
    required this.name,
    required this.dateTime,
    required this.size,
    required this.type,
    required this.width,
    required this.height,
    this.albumName,
    this.isDeleted = false,
    this.isCompressed = false,
    this.compressedPath,
    this.hash,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'path': path,
      'name': name,
      'dateTime': dateTime.millisecondsSinceEpoch,
      'size': size,
      'type': type,
      'width': width,
      'height': height,
      'albumName': albumName,
      'isDeleted': isDeleted ? 1 : 0,
      'isCompressed': isCompressed ? 1 : 0,
      'compressedPath': compressedPath,
      'hash': hash,
    };
  }
  
  factory PhotoModel.fromMap(Map<String, dynamic> map) {
    return PhotoModel(
      id: map['id'],
      path: map['path'],
      name: map['name'],
      dateTime: DateTime.fromMillisecondsSinceEpoch(map['dateTime']),
      size: map['size'],
      type: map['type'],
      width: map['width'],
      height: map['height'],
      albumName: map['albumName'],
      isDeleted: map['isDeleted'] == 1,
      isCompressed: map['isCompressed'] == 1,
      compressedPath: map['compressedPath'],
      hash: map['hash'],
    );
  }
  
  PhotoModel copyWith({
    String? albumName,
    bool? isDeleted,
    bool? isCompressed,
    String? compressedPath,
  }) {
    return PhotoModel(
      id: id,
      path: path,
      name: name,
      dateTime: dateTime,
      size: size,
      type: type,
      width: width,
      height: height,
      albumName: albumName ?? this.albumName,
      isDeleted: isDeleted ?? this.isDeleted,
      isCompressed: isCompressed ?? this.isCompressed,
      compressedPath: compressedPath ?? this.compressedPath,
      hash: hash,
    );
  }
}