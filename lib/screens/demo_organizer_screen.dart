import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class DemoOrganizerScreen extends StatefulWidget {
  const DemoOrganizerScreen({super.key});

  @override
  State<DemoOrganizerScreen> createState() => _DemoOrganizerScreenState();
}

class _DemoOrganizerScreenState extends State<DemoOrganizerScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  
  final List<DemoPhoto> _demoPhotos = [
    DemoPhoto(
      name: 'IMG_001.jpg',
      size: '2.5 MB',
      date: '2024-12-15',
      type: 'image',
      isDuplicate: true,
    ),
    DemoPhoto(
      name: 'VID_002.mp4',
      size: '15.2 MB',
      date: '2024-12-14',
      type: 'video',
      isLarge: true,
    ),
    DemoPhoto(
      name: 'IMG_003.jpg',
      size: '3.1 MB',
      date: '2024-12-13',
      type: 'image',
      isDuplicate: true,
    ),
    DemoPhoto(
      name: 'IMG_004.jpg',
      size: '1.8 MB',
      date: '2024-12-12',
      type: 'image',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (_demoPhotos.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          title: const Text('演示完成'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.checkmark_circle_fill,
                size: 64,
                color: CupertinoColors.systemGreen,
              ),
              SizedBox(height: 16),
              Text(
                '恭喜！演示完成',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '您已体验了照片整理的核心功能',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text('演示模式 ${_currentIndex + 1} / ${_demoPhotos.length}'),
      ),
      body: Stack(
        children: [
          // 照片轮播
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: _demoPhotos.length,
            itemBuilder: (context, index) {
              return DemoPhotoCard(
                photo: _demoPhotos[index],
                onSwipeUp: () => _deletePhoto(index),
                onSwipeDown: () => _compressPhoto(index),
                onSwipeLeft: () => _previousPhoto(),
                onSwipeRight: () => _nextPhoto(),
              );
            },
          ),
          
          // 操作提示
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  _buildActionHint(
                    icon: CupertinoIcons.arrow_up,
                    text: '向上滑动删除',
                    color: CupertinoColors.systemRed,
                  ),
                  const SizedBox(height: 8),
                  _buildActionHint(
                    icon: CupertinoIcons.arrow_down,
                    text: '向下滑动压缩',
                    color: CupertinoColors.systemOrange,
                  ),
                  const SizedBox(height: 8),
                  _buildActionHint(
                    icon: CupertinoIcons.arrow_left_right,
                    text: '左右滑动切换',
                    color: CupertinoColors.systemBlue,
                  ),
                ],
              ),
            ),
          ),
          
          // 底部操作栏
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      icon: CupertinoIcons.delete,
                      label: '删除',
                      color: CupertinoColors.systemRed,
                      onPressed: () => _deletePhoto(_currentIndex),
                    ),
                    _buildActionButton(
                      icon: CupertinoIcons.arrow_down_to_line,
                      label: '压缩',
                      color: CupertinoColors.systemOrange,
                      onPressed: () => _compressPhoto(_currentIndex),
                    ),
                    _buildActionButton(
                      icon: CupertinoIcons.collections,
                      label: '添加到相册',
                      color: CupertinoColors.systemBlue,
                      onPressed: _showAlbumSelector,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionHint({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: color, width: 2),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _previousPhoto() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextPhoto() {
    if (_currentIndex < _demoPhotos.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // 演示完成
      setState(() {
        _demoPhotos.clear();
      });
    }
  }

  void _deletePhoto(int index) {
    setState(() {
      _demoPhotos.removeAt(index);
      if (_currentIndex >= _demoPhotos.length && _demoPhotos.isNotEmpty) {
        _currentIndex = _demoPhotos.length - 1;
      }
    });
    
    _showActionFeedback('已删除照片', CupertinoColors.systemRed);
    
    if (_demoPhotos.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _nextPhoto();
      });
    }
  }

  void _compressPhoto(int index) {
    _showActionFeedback('照片已压缩', CupertinoColors.systemOrange);
    Future.delayed(const Duration(milliseconds: 500), () {
      _nextPhoto();
    });
  }

  void _showAlbumSelector() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('选择相册'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _addToAlbum('收藏');
            },
            child: const Text('收藏'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _addToAlbum('家庭');
            },
            child: const Text('家庭'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _addToAlbum('旅行');
            },
            child: const Text('旅行'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
      ),
    );
  }

  void _addToAlbum(String albumName) {
    _showActionFeedback('已添加到$albumName', CupertinoColors.systemGreen);
    Future.delayed(const Duration(milliseconds: 500), () {
      _nextPhoto();
    });
  }

  void _showActionFeedback(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class DemoPhoto {
  final String name;
  final String size;
  final String date;
  final String type;
  final bool isDuplicate;
  final bool isLarge;

  DemoPhoto({
    required this.name,
    required this.size,
    required this.date,
    required this.type,
    this.isDuplicate = false,
    this.isLarge = false,
  });
}

class DemoPhotoCard extends StatefulWidget {
  final DemoPhoto photo;
  final VoidCallback onSwipeUp;
  final VoidCallback onSwipeDown;
  final VoidCallback onSwipeLeft;
  final VoidCallback onSwipeRight;

  const DemoPhotoCard({
    super.key,
    required this.photo,
    required this.onSwipeUp,
    required this.onSwipeDown,
    required this.onSwipeLeft,
    required this.onSwipeRight,
  });

  @override
  State<DemoPhotoCard> createState() => _DemoPhotoCardState();
}

class _DemoPhotoCardState extends State<DemoPhotoCard> {
  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Transform.translate(
        offset: _dragOffset,
        child: Transform.scale(
          scale: _isDragging ? 
            (1.0 - _dragOffset.distance / 1000).clamp(0.8, 1.0) : 
            1.0,
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
                  // 模拟照片背景
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: widget.photo.type == 'image'
                              ? [Colors.blue.shade300, Colors.purple.shade300]
                              : [Colors.red.shade300, Colors.orange.shade300],
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          widget.photo.type == 'image' 
                              ? CupertinoIcons.photo 
                              : CupertinoIcons.videocam,
                          size: 64,
                          color: Colors.white.withOpacity(0.8),
                        ),
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
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.photo.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (widget.photo.isDuplicate)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: CupertinoColors.systemOrange,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    '重复',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              if (widget.photo.isLarge)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: CupertinoColors.systemRed,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    '大文件',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
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
                                widget.photo.size,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                widget.photo.date,
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
}