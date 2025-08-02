class AlbumModel {
  final String name;
  final int photoCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? coverPhotoPath;
  
  AlbumModel({
    required this.name,
    required this.photoCount,
    required this.createdAt,
    required this.updatedAt,
    this.coverPhotoPath,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'photoCount': photoCount,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'coverPhotoPath': coverPhotoPath,
    };
  }
  
  factory AlbumModel.fromMap(Map<String, dynamic> map) {
    return AlbumModel(
      name: map['name'],
      photoCount: map['photoCount'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
      coverPhotoPath: map['coverPhotoPath'],
    );
  }
}