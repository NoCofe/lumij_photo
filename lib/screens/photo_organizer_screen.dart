import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/photo_provider.dart';
import '../models/photo_model.dart';
import '../widgets/swipeable_photo_card.dart';
import '../widgets/album_selector.dart';
import '../services/operation_service.dart';

class PhotoOrganizerScreen extends StatefulWidget {
  final List<PhotoModel> photos;
  final String title;

  const PhotoOrganizerScreen({
    super.key,
    required this.photos,
    required this.title,
  });

  @override
  State<PhotoOrganizerScreen> createState() => _PhotoOrganizerScreenState();
}

class _PhotoOrganizerScreenState extends State<PhotoOrganizerScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  List<PhotoModel> _photos = [];

  @override
  void initState() {
    super.initState();
    _photos = List.from(widget.photos);
  }

  @override
  Widget build(BuildContext context) {
    if (_photos.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('照片整理'),
        ),
        body: const Center(
          child: Text('没有需要整理的照片'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text('${widget.title} ${_currentIndex + 1} / ${_photos.length}'),
        actions: [
          IconButton(
            onPressed: () => _showAlbumSelector(),
            icon: const Icon(CupertinoIcons.collections),
          ),
        ],
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
            itemCount: _photos.length,
            itemBuilder: (context, index) {
              return SwipeablePhotoCard(
                photo: _photos[index],
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
    if (_currentIndex < _photos.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // 整理完成
      _showCompletionDialog();
    }
  }

  void _deletePhoto(int index) async {
    // 检查删除权限
    final hasPermission = await OperationService.requestDeletePermission(context);
    if (!hasPermission) return;
    
    final provider = context.read<PhotoProvider>();
    final success = await provider.deletePhoto(_photos[index].id);
    
    if (success) {
      setState(() {
        _photos.removeAt(index);
        if (_currentIndex >= _photos.length && _photos.isNotEmpty) {
          _currentIndex = _photos.length - 1;
        }
      });
      
      if (_photos.isEmpty) {
        _showCompletionDialog();
      } else {
        OperationService.showSuccessMessage(context, '已删除照片');
        _nextPhoto();
      }
    } else {
      OperationService.showErrorMessage(context, '删除失败，请重试');
    }
  }

  void _compressPhoto(int index) async {
    // 检查压缩权限
    final hasPermission = await OperationService.requestCompressPermission(context);
    if (!hasPermission) return;
    
    final provider = context.read<PhotoProvider>();
    await provider.compressPhoto(_photos[index].id);
    
    OperationService.showSuccessMessage(context, '照片已压缩', color: CupertinoColors.systemOrange);
    _nextPhoto();
  }

  void _showAlbumSelector() {
    AlbumSelector.show(
      context: context,
      onAlbumSelected: (albumName) => _addToAlbum(albumName),
    );
  }

  void _addToAlbum(String albumName) async {
    // 检查相册操作权限
    final hasPermission = await OperationService.requestAlbumPermission(context);
    if (!hasPermission) return;
    
    final provider = context.read<PhotoProvider>();
    await provider.addToAlbum(_photos[_currentIndex].id, albumName);
    
    OperationService.showSuccessMessage(context, '已添加到$albumName');
    _nextPhoto();
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

  void _showCompletionDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('整理完成'),
        content: const Text('恭喜！您已经完成了照片整理。'),
        actions: [
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('返回'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}