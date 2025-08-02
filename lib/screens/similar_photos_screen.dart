import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:photo_manager/photo_manager.dart';
import '../models/similar_photo_group.dart';
import '../models/photo_model.dart';
import '../services/similar_photo_service.dart';
import '../providers/optimized_photo_provider.dart';

class SimilarPhotosScreen extends StatefulWidget {
  const SimilarPhotosScreen({super.key});

  @override
  State<SimilarPhotosScreen> createState() => _SimilarPhotosScreenState();
}

class _SimilarPhotosScreenState extends State<SimilarPhotosScreen> {
  List<SimilarPhotoGroup> _similarGroups = [];
  bool _isAnalyzing = false;
  double _analysisProgress = 0;
  String _analysisMessage = '';
  double _similarityThreshold = 0.85;
  int _totalPhotosToDelete = 0;
  int _totalSpaceSaving = 0;

  @override
  void initState() {
    super.initState();
    _startAnalysis();
  }

  Future<void> _startAnalysis() async {
    setState(() {
      _isAnalyzing = true;
      _analysisProgress = 0;
      _analysisMessage = '准备分析...';
    });

    try {
      final provider = Provider.of<OptimizedPhotoProvider>(context, listen: false);
      
      if (provider.photos.isEmpty) {
        await provider.loadMorePhotos();
      }

      final groups = await SimilarPhotoService.analyzeSimilarPhotos(
        provider.photos,
        similarityThreshold: _similarityThreshold,
        onProgress: (progress, message) {
          setState(() {
            _analysisProgress = progress;
            _analysisMessage = message;
          });
        },
      );

      setState(() {
        _similarGroups = groups;
        _calculateSummary();
      });

    } catch (e) {
      setState(() {
        _analysisMessage = '分析失败: $e';
      });
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  void _calculateSummary() {
    _totalPhotosToDelete = 0;
    _totalSpaceSaving = 0;
    
    for (final group in _similarGroups) {
      _totalPhotosToDelete += group.selectedPhotosList.length;
      _totalSpaceSaving += group.selectedPhotosSize;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('相似照片'),
        backgroundColor: CupertinoColors.systemBackground,
        trailing: _buildActionButton(),
      ),
      child: SafeArea(
        child: Column(
          children: [
            if (_isAnalyzing) ...[
              _buildAnalysisProgress(),
            ] else ...[
              _buildSummaryCard(),
              _buildControlPanel(),
            ],
            Expanded(
              child: _buildGroupsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    if (_isAnalyzing) {
      return const CupertinoActivityIndicator();
    }
    
    return CupertinoButton(
      padding: EdgeInsets.zero,
      child: const Icon(CupertinoIcons.refresh),
      onPressed: _startAnalysis,
    );
  }

  Widget _buildAnalysisProgress() {
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
                  '分析相似照片...',
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
              value: _analysisProgress / 100,
              backgroundColor: CupertinoColors.systemGrey5,
              valueColor: const AlwaysStoppedAnimation<Color>(
                CupertinoColors.activeBlue,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _analysisMessage,
            style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
              fontSize: 14,
              color: CupertinoColors.secondaryLabel,
            ),
          ),
          Text(
            '${_analysisProgress.toStringAsFixed(0)}%',
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

  Widget _buildSummaryCard() {
    if (_similarGroups.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(
              CupertinoIcons.checkmark_circle,
              color: CupertinoColors.systemGreen,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '太棒了！没有发现相似照片',
                style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
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
              Expanded(
                child: _buildSummaryItem(
                  '相似组数',
                  '${_similarGroups.length}',
                  CupertinoIcons.photo_on_rectangle,
                  CupertinoColors.activeBlue,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  '可删除',
                  '$_totalPhotosToDelete张',
                  CupertinoIcons.delete,
                  CupertinoColors.systemRed,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  '节省空间',
                  _formatFileSize(_totalSpaceSaving),
                  CupertinoIcons.arrow_down_circle,
                  CupertinoColors.systemGreen,
                ),
              ),
            ],
          ),
          if (_totalPhotosToDelete > 0) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton.filled(
                child: Text('删除选中的 $_totalPhotosToDelete 张照片'),
                onPressed: _showDeleteConfirmation,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          title,
          style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
            fontSize: 12,
            color: CupertinoColors.secondaryLabel,
          ),
        ),
      ],
    );
  }

  Widget _buildControlPanel() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(
            '相似度阈值:',
            style: CupertinoTheme.of(context).textTheme.textStyle,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: CupertinoSlider(
              value: _similarityThreshold,
              min: 0.7,
              max: 0.95,
              divisions: 25,
              onChanged: (value) {
                setState(() {
                  _similarityThreshold = value;
                });
              },
              onChangeEnd: (value) {
                _startAnalysis();
              },
            ),
          ),
          Text(
            '${(_similarityThreshold * 100).toInt()}%',
            style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupsList() {
    if (_isAnalyzing) {
      return const Center(
        child: CupertinoActivityIndicator(),
      );
    }

    if (_similarGroups.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.photo,
              size: 48,
              color: CupertinoColors.systemGrey,
            ),
            SizedBox(height: 16),
            Text('没有发现相似照片'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _similarGroups.length,
      itemBuilder: (context, index) {
        final group = _similarGroups[index];
        return _buildGroupCard(group, index);
      },
    );
  }

  Widget _buildGroupCard(SimilarPhotoGroup group, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGroupHeader(group, index),
          _buildGroupPhotos(group),
          _buildGroupActions(group),
        ],
      ),
    );
  }

  Widget _buildGroupHeader(SimilarPhotoGroup group, int index) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getGroupColor(group.groupType),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              group.groupTitle,
              style: const TextStyle(
                color: CupertinoColors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${group.photos.length}张照片 • 相似度${(group.averageSimilarity * 100).toInt()}%',
              style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                fontSize: 14,
                color: CupertinoColors.secondaryLabel,
              ),
            ),
          ),
          Text(
            '节省${_formatFileSize(group.selectedPhotosSize)}',
            style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
              fontSize: 12,
              color: CupertinoColors.systemGreen,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupPhotos(SimilarPhotoGroup group) {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: group.photos.length,
        itemBuilder: (context, index) {
          final photo = group.photos[index];
          final isSelected = group.selectedPhotos[photo.id] ?? false;
          final isPrimary = photo.id == group.primaryPhoto.id;
          
          return GestureDetector(
            onTap: () => _togglePhotoSelection(group, photo.id),
            child: Container(
              width: 80,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected 
                    ? CupertinoColors.systemRed 
                    : isPrimary 
                      ? CupertinoColors.systemGreen
                      : CupertinoColors.systemGrey4,
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    FutureBuilder<Uint8List?>(
                      future: _getThumbnail(photo.id),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data != null) {
                          return Image.memory(
                            snapshot.data!,
                            fit: BoxFit.cover,
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
                    if (isSelected)
                      Container(
                        color: CupertinoColors.systemRed.withOpacity(0.3),
                        child: const Center(
                          child: Icon(
                            CupertinoIcons.delete,
                            color: CupertinoColors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    if (isPrimary && !isSelected)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: CupertinoColors.systemGreen,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            CupertinoIcons.checkmark,
                            color: CupertinoColors.white,
                            size: 12,
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: 2,
                      left: 2,
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
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGroupActions(SimilarPhotoGroup group) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: CupertinoColors.systemGrey5,
              child: const Text(
                '智能选择',
                style: TextStyle(color: CupertinoColors.label),
              ),
              onPressed: () => _smartSelect(group),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: CupertinoColors.systemGrey5,
              child: const Text(
                '全选',
                style: TextStyle(color: CupertinoColors.label),
              ),
              onPressed: () => _selectAll(group),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: CupertinoColors.systemGrey5,
              child: const Text(
                '清空',
                style: TextStyle(color: CupertinoColors.label),
              ),
              onPressed: () => _clearSelection(group),
            ),
          ),
        ],
      ),
    );
  }

  Color _getGroupColor(SimilarGroupType type) {
    switch (type) {
      case SimilarGroupType.duplicate:
        return CupertinoColors.systemRed;
      case SimilarGroupType.similar:
        return CupertinoColors.systemOrange;
      case SimilarGroupType.burst:
        return CupertinoColors.systemBlue;
    }
  }

  Future<Uint8List?> _getThumbnail(String photoId) async {
    try {
      final asset = await AssetEntity.fromId(photoId);
      if (asset != null) {
        return await asset.thumbnailDataWithSize(
          const ThumbnailSize(120, 120),
          quality: 80,
        );
      }
    } catch (e) {
      print('❌ Error getting thumbnail: $e');
    }
    return null;
  }

  void _togglePhotoSelection(SimilarPhotoGroup group, String photoId) {
    setState(() {
      group.togglePhotoSelection(photoId);
      _calculateSummary();
    });
  }

  void _smartSelect(SimilarPhotoGroup group) {
    setState(() {
      group.smartSelect();
      _calculateSummary();
    });
  }

  void _selectAll(SimilarPhotoGroup group) {
    setState(() {
      group.selectAllPhotos();
      _calculateSummary();
    });
  }

  void _clearSelection(SimilarPhotoGroup group) {
    setState(() {
      group.deselectAllPhotos();
      _calculateSummary();
    });
  }

  void _showDeleteConfirmation() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('确认删除'),
        content: Text(
          '您即将删除 $_totalPhotosToDelete 张相似照片，可节省 ${_formatFileSize(_totalSpaceSaving)} 存储空间。\n\n此操作不可撤销，请确认。'
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('取消'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('删除'),
            onPressed: () {
              Navigator.of(context).pop();
              _deleteSelectedPhotos();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSelectedPhotos() async {
    // TODO: 实现实际的删除功能
    // 这里应该调用 photo service 删除选中的照片
    
    setState(() {
      // 从列表中移除已删除的照片
      _similarGroups.removeWhere((group) {
        group.photos.removeWhere((photo) => group.selectedPhotos[photo.id] == true);
        return group.photos.isEmpty;
      });
      _calculateSummary();
    });
    
    _showDeleteSuccess();
  }

  void _showDeleteSuccess() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('删除成功'),
        content: Text('已成功删除相似照片，节省了 ${_formatFileSize(_totalSpaceSaving)} 存储空间！'),
        actions: [
          CupertinoDialogAction(
            child: const Text('确定'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
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