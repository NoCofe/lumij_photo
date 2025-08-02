import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/optimized_photo_provider.dart';
import '../widgets/photo_grid.dart';
import '../widgets/stats_card.dart';
import '../models/photo_model.dart';
import 'similar_photos_screen.dart';

class OptimizedHomeScreen extends StatefulWidget {
  const OptimizedHomeScreen({super.key});

  @override
  State<OptimizedHomeScreen> createState() => _OptimizedHomeScreenState();
}

class _OptimizedHomeScreenState extends State<OptimizedHomeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showQuickScanOption = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    
    // 自动开始后台扫描
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startInitialScan();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      // 接近底部时加载更多
      Provider.of<OptimizedPhotoProvider>(context, listen: false).loadMorePhotos();
    }
  }

  Future<void> _startInitialScan() async {
    final provider = Provider.of<OptimizedPhotoProvider>(context, listen: false);
    
    // 先尝试快速扫描
    await provider.scanPhotosOptimized(
      maxPhotos: 1000, // 限制初始扫描数量
      quickScan: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Lumij Photo'),
        backgroundColor: CupertinoColors.systemBackground,
      ),
      child: SafeArea(
        child: Consumer<OptimizedPhotoProvider>(
          builder: (context, provider, child) {
            return CustomScrollView(
              controller: _scrollController,
              slivers: [
                // 扫描进度显示
                if (provider.isScanning) ...[
                  SliverToBoxAdapter(
                    child: _buildScanProgress(provider),
                  ),
                ],
                
                // 统计卡片
                if (!provider.isScanning) ...[
                  SliverToBoxAdapter(
                    child: _buildStatsCards(provider),
                  ),
                ],
                
                // 快速扫描选项
                if (_showQuickScanOption && !provider.isScanning) ...[
                  SliverToBoxAdapter(
                    child: _buildScanOptions(provider),
                  ),
                ],
                
                // 视图切换器
                if (!provider.isScanning) ...[
                  SliverToBoxAdapter(
                    child: _buildViewSelector(provider),
                  ),
                ],
                
                // 照片列表
                _buildPhotoList(provider),
                
                // 加载更多指示器
                if (provider.isLoading) ...[
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: CupertinoActivityIndicator(),
                      ),
                    ),
                  ),
                ],
                
                // 底部提示
                if (!provider.hasMorePhotos && provider.photos.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: Text(
                          '已显示全部 ${provider.photos.length} 张照片',
                          style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                            color: CupertinoColors.secondaryLabel,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildScanProgress(OptimizedPhotoProvider provider) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CupertinoActivityIndicator(),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '正在扫描相册...',
                  style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: provider.scanProgress / 100,
              backgroundColor: CupertinoColors.systemGrey5,
              valueColor: const AlwaysStoppedAnimation<Color>(
                CupertinoColors.activeBlue,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            provider.scanMessage,
            style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
              fontSize: 14,
              color: CupertinoColors.secondaryLabel,
            ),
          ),
          Text(
            '${provider.scanProgress.toStringAsFixed(0)}%',
            style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: CupertinoColors.activeBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(OptimizedPhotoProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: StatsCard(
              title: '总照片',
              count: provider.totalPhotos,
              icon: CupertinoIcons.photo,
              color: CupertinoColors.activeBlue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => _navigateToSimilarPhotos(),
              child: StatsCard(
                title: '相似照片',
                count: provider.duplicatePhotos.length,
                icon: CupertinoIcons.rectangle_stack,
                color: CupertinoColors.systemOrange,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatsCard(
              title: '大文件',
              count: provider.largePhotos.length,
              icon: CupertinoIcons.arrow_up_doc,
              color: CupertinoColors.systemRed,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanOptions(OptimizedPhotoProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.info_circle,
                color: CupertinoColors.activeBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '提示：当前为快速扫描模式',
                  style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: CupertinoButton.filled(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: const Text(
                    '完整扫描',
                    style: TextStyle(fontSize: 14),
                  ),
                  onPressed: () => _showFullScanDialog(provider),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: const Text(
                    '隐藏提示',
                    style: TextStyle(fontSize: 14),
                  ),
                  onPressed: () {
                    setState(() {
                      _showQuickScanOption = false;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildViewSelector(OptimizedPhotoProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: CupertinoSlidingSegmentedControl<String>(
        groupValue: provider.currentView,
        children: const {
          'all': Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text('全部'),
          ),
          'large': Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text('大文件'),
          ),
        },
        onValueChanged: (value) {
          if (value != null) {
            provider.setCurrentView(value);
          }
        },
      ),
    );
  }

  Widget _buildPhotoList(OptimizedPhotoProvider provider) {
    if (provider.errorMessage.isNotEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.exclamationmark_triangle,
                size: 48,
                color: CupertinoColors.systemRed,
              ),
              const SizedBox(height: 16),
              Text(
                provider.errorMessage,
                textAlign: TextAlign.center,
                style: CupertinoTheme.of(context).textTheme.textStyle,
              ),
              const SizedBox(height: 16),
              CupertinoButton.filled(
                child: const Text('重试'),
                onPressed: () => _startInitialScan(),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.photos.isEmpty && !provider.isLoading && !provider.isScanning) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.photo,
                size: 48,
                color: CupertinoColors.systemGrey,
              ),
              const SizedBox(height: 16),
              Text(
                '暂无照片',
                style: CupertinoTheme.of(context).textTheme.textStyle,
              ),
              const SizedBox(height: 16),
              CupertinoButton.filled(
                child: const Text('开始扫描'),
                onPressed: () => _startInitialScan(),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final photo = provider.photos[index];
            return _buildPhotoItem(photo, provider);
          },
          childCount: provider.photos.length,
        ),
      ),
    );
  }

  Widget _buildPhotoItem(PhotoModel photo, OptimizedPhotoProvider provider) {
    return GestureDetector(
      onTap: () => _showPhotoDetail(photo, provider),
      child: Container(
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey5,
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 照片缩略图
              FutureBuilder<PhotoModel?>(
                future: provider.getFullPhotoInfo(photo.id),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data!.path.isNotEmpty) {
                    return Image.file(
                      File(snapshot.data!.path),
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
                    );
                  }
                  return Container(
                    color: CupertinoColors.systemGrey5,
                    child: const Center(
                      child: CupertinoActivityIndicator(radius: 8),
                    ),
                  );
                },
              ),
              
              // 视频标识
              if (photo.type == 'video')
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: CupertinoColors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      CupertinoIcons.play_fill,
                      color: CupertinoColors.white,
                      size: 12,
                    ),
                  ),
                ),
              
              // 文件大小标识（大文件模式）
              if (provider.currentView == 'large')
                Positioned(
                  bottom: 4,
                  left: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: CupertinoColors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _formatFileSize(photo.size),
                      style: const TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
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

  void _showPhotoDetail(PhotoModel photo, OptimizedPhotoProvider provider) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => PhotoDetailScreen(photo: photo),
      ),
    );
  }

  void _showFullScanDialog(OptimizedPhotoProvider provider) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('完整扫描'),
        content: const Text(
          '完整扫描会处理所有照片并计算文件哈希值，用于精确的重复检测。\n\n这可能需要较长时间，建议在充电时进行。',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('取消'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('开始'),
            onPressed: () {
              Navigator.of(context).pop();
              provider.scanPhotosOptimized(quickScan: false);
              setState(() {
                _showQuickScanOption = false;
              });
            },
          ),
        ],
      ),
    );
  }

  void _navigateToSimilarPhotos() {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => const SimilarPhotosScreen(),
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

// 简单的照片详情页面
class PhotoDetailScreen extends StatelessWidget {
  final PhotoModel photo;

  const PhotoDetailScreen({super.key, required this.photo});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(photo.name),
        backgroundColor: CupertinoColors.systemBackground,
      ),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '照片详情',
                style: CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle,
              ),
              const SizedBox(height: 20),
              Text('文件名: ${photo.name}'),
              Text('大小: ${(photo.size / (1024 * 1024)).toStringAsFixed(2)}MB'),
              Text('尺寸: ${photo.width} x ${photo.height}'),
              Text('类型: ${photo.type}'),
              Text('日期: ${photo.dateTime.toString().split('.')[0]}'),
            ],
          ),
        ),
      ),
    );
  }
}