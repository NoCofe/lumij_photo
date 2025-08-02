import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../models/photo_model.dart';
import '../screens/photo_detail_screen.dart';

class PhotoItem extends StatelessWidget {
  final PhotoModel photo;

  const PhotoItem({
    super.key,
    required this.photo,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) => PhotoDetailScreen(photo: photo),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              // 照片缩略图
              AspectRatio(
                aspectRatio: 1,
                child: photo.type == 'image'
                    ? Image.file(
                        File(photo.compressedPath ?? photo.path),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: CupertinoColors.systemGrey5,
                            child: const Icon(
                              CupertinoIcons.photo,
                              color: CupertinoColors.systemGrey,
                            ),
                          );
                        },
                      )
                    : Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.purple.shade300,
                              Colors.blue.shade300,
                            ],
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            CupertinoIcons.play_circle_fill,
                            size: 32,
                            color: Colors.white,
                          ),
                        ),
                      ),
              ),
              
              // 视频标识
              if (photo.type == 'video')
                const Positioned(
                  top: 8,
                  right: 8,
                  child: Icon(
                    CupertinoIcons.play_circle_fill,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              
              // 压缩标识
              if (photo.isCompressed)
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Icon(
                    CupertinoIcons.arrow_down_to_line,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              
              // 文件大小
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _formatFileSize(photo.size),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }
}