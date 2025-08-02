import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../models/photo_model.dart';
import '../screens/video_player_screen.dart';
import '../screens/photo_detail_screen.dart';

class SwipeablePhotoCard extends StatefulWidget {
  final PhotoModel photo;
  final VoidCallback onSwipeUp;
  final VoidCallback onSwipeDown;
  final VoidCallback onSwipeLeft;
  final VoidCallback onSwipeRight;

  const SwipeablePhotoCard({
    super.key,
    required this.photo,
    required this.onSwipeUp,
    required this.onSwipeDown,
    required this.onSwipeLeft,
    required this.onSwipeRight,
  });

  @override
  State<SwipeablePhotoCard> createState() => _SwipeablePhotoCardState();
}

class _SwipeablePhotoCardState extends State<SwipeablePhotoCard>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  
  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // 点击查看照片详情
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) => PhotoDetailScreen(photo: widget.photo),
          ),
        );
      },
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.translate(
            offset: _isDragging ? _dragOffset : _slideAnimation.value,
            child: Transform.scale(
              scale: _isDragging ? 
                (1.0 - _dragOffset.distance / 1000).clamp(0.8, 1.0) : 
                _scaleAnimation.value,
              child: Transform.rotate(
                angle: _isDragging ? 
                  _dragOffset.dx / 1000 : 
                  _rotationAnimation.value,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        // 照片
                        Positioned.fill(
                          child: widget.photo.type == 'image'
                              ? Image.file(
                                  File(widget.photo.compressedPath ?? widget.photo.path),
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: CupertinoColors.systemGrey6,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            CupertinoIcons.photo,
                                            size: 64,
                                            color: CupertinoColors.systemGrey,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '无法加载图片',
                                            style: TextStyle(
                                              color: CupertinoColors.systemGrey,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
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
                                        Colors.purple.shade800,
                                        Colors.blue.shade800,
                                      ],
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.3),
                                          borderRadius: BorderRadius.circular(50),
                                        ),
                                        child: const Icon(
                                          CupertinoIcons.play_circle_fill,
                                          size: 64,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        '视频文件',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        '点击查看详情',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                        
                        // 滑动指示器
                        if (_isDragging) _buildSwipeIndicator(),
                        
                        // 照片信息
                        Positioned(
                          top: 16,
                          left: 16,
                          right: 16,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.photo.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      widget.photo.type == 'image' 
                                          ? CupertinoIcons.photo 
                                          : CupertinoIcons.videocam,
                                      color: Colors.white70,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatFileSize(widget.photo.size),
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      _formatDate(widget.photo.dateTime),
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSwipeIndicator() {
    final opacity = (_dragOffset.distance / 100).clamp(0.0, 1.0);
    
    if (_dragOffset.dy < -50) {
      // 向上滑动 - 删除
      return Positioned.fill(
        child: Container(
          color: CupertinoColors.systemRed.withOpacity(opacity * 0.8),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.delete,
                  color: Colors.white,
                  size: 48,
                ),
                SizedBox(height: 8),
                Text(
                  '删除照片',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else if (_dragOffset.dy > 50) {
      // 向下滑动 - 压缩
      return Positioned.fill(
        child: Container(
          color: CupertinoColors.systemOrange.withOpacity(opacity * 0.8),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.arrow_down_to_line,
                  color: Colors.white,
                  size: 48,
                ),
                SizedBox(height: 8),
                Text(
                  '压缩照片',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    return const SizedBox.shrink();
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    const threshold = 100.0;
    
    if (_dragOffset.dy < -threshold) {
      // 向上滑动 - 删除
      widget.onSwipeUp();
    } else if (_dragOffset.dy > threshold) {
      // 向下滑动 - 压缩
      widget.onSwipeDown();
    } else if (_dragOffset.dx < -threshold) {
      // 向左滑动
      widget.onSwipeLeft();
    } else if (_dragOffset.dx > threshold) {
      // 向右滑动
      widget.onSwipeRight();
    }
    
    // 重置状态
    setState(() {
      _isDragging = false;
      _dragOffset = Offset.zero;
    });
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.year}/${dateTime.month}/${dateTime.day}';
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}