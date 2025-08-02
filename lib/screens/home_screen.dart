import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/photo_provider.dart';
import '../widgets/photo_grid.dart';
import '../widgets/stats_card.dart';
import '../widgets/ios_delete_optimizer.dart';
import '../models/photo_model.dart';
import 'photo_organizer_screen.dart';
import 'settings_screen.dart';
import 'permission_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // 加载真实相册
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PhotoProvider>().loadAlbums();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      body: SafeArea(
        child: Consumer<PhotoProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CupertinoActivityIndicator(radius: 20),
                    SizedBox(height: 16),
                    Text(
                      '正在扫描相册...',
                      style: TextStyle(
                        fontSize: 16,
                        color: CupertinoColors.secondaryLabel,
                      ),
                    ),
                  ],
                ),
              );
            }

            if (provider.errorMessage.isNotEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      CupertinoIcons.exclamationmark_triangle,
                      size: 64,
                      color: CupertinoColors.systemRed,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      provider.errorMessage,
                      style: const TextStyle(
                        fontSize: 16,
                        color: CupertinoColors.secondaryLabel,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    CupertinoButton.filled(
                      onPressed: () => provider.scanPhotos(),
                      child: const Text('重试'),
                    ),
                  ],
                ),
              );
            }

            if (provider.allPhotos.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      CupertinoIcons.photo_on_rectangle,
                      size: 64,
                      color: CupertinoColors.systemGrey,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '开始扫描您的相册',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '点击下方按钮开始整理照片',
                      style: TextStyle(
                        fontSize: 16,
                        color: CupertinoColors.secondaryLabel,
                      ),
                    ),
                    const SizedBox(height: 24),
                    CupertinoButton.filled(
                      onPressed: () => _requestPermissionAndScan(context),
                      child: const Text('开始扫描'),
                    ),
                  ],
                ),
              );
            }

            return CustomScrollView(
              slivers: [
                // 标题栏
                SliverAppBar(
                  title: const Text(
                    'Lumij Photo',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: Colors.transparent,
                  floating: true,
                  actions: [
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (context) => const SettingsScreen(),
                          ),
                        );
                      },
                      icon: const Icon(CupertinoIcons.settings),
                    ),
                  ],
                ),
                
                // 统计卡片
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: StatsCard(
                                title: '总照片',
                                count: provider.allPhotos.length,
                                icon: CupertinoIcons.photo,
                                color: CupertinoColors.systemBlue,
                                onTap: () => provider.setCurrentView('all'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: StatsCard(
                                title: '重复照片',
                                count: provider.duplicatePhotos.length,
                                icon: CupertinoIcons.doc_on_doc,
                                color: CupertinoColors.systemOrange,
                                onTap: () => provider.setCurrentView('duplicates'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: StatsCard(
                                title: '大文件',
                                count: provider.largePhotos.length,
                                icon: CupertinoIcons.folder_fill,
                                color: CupertinoColors.systemRed,
                                onTap: () => provider.setCurrentView('large'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: StatsCard(
                                title: '相册',
                                count: provider.albums.length,
                                icon: CupertinoIcons.collections,
                                color: CupertinoColors.systemGreen,
                                onTap: () => provider.setCurrentView('albums'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                // 操作按钮组
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        // 快速整理按钮
                        CupertinoButton.filled(
                          onPressed: () {
                            final currentPhotos = _getCurrentPhotos(provider);
                            if (currentPhotos.isEmpty) {
                              _showNoPhotosDialog(context);
                              return;
                            }
                            
                            Navigator.push(
                              context,
                              CupertinoPageRoute(
                                builder: (context) => PhotoOrganizerScreen(
                                  photos: currentPhotos.whereType<PhotoModel>().toList(),
                                  title: _getCurrentTitle(provider),
                                ),
                              ),
                            );
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(CupertinoIcons.hand_draw),
                              const SizedBox(width: 8),
                              Text('整理${_getCurrentTitle(provider)}'),
                            ],
                          ),
                        ),
                        
                        // iOS优化删除按钮（仅在iOS上显示）
                        if (Platform.isIOS) ...[
                          const SizedBox(height: 12),
                          CupertinoButton(
                            onPressed: () => _showIOSDeleteOptions(context, provider),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: CupertinoColors.systemRed),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(CupertinoIcons.delete, color: CupertinoColors.systemRed),
                                  SizedBox(width: 8),
                                  Text('智能批量删除', style: TextStyle(color: CupertinoColors.systemRed)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
                
                // 照片网格
                PhotoGrid(
                  photos: _getCurrentPhotos(provider),
                  title: _getCurrentTitle(provider),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<dynamic> _getCurrentPhotos(PhotoProvider provider) {
    switch (provider.currentView) {
      case 'duplicates':
        return provider.duplicatePhotos;
      case 'large':
        return provider.largePhotos;
      case 'albums':
        return provider.albums;
      default:
        return provider.allPhotos.take(50).toList(); // 只显示前50张
    }
  }

  String _getCurrentTitle(PhotoProvider provider) {
    switch (provider.currentView) {
      case 'duplicates':
        return '重复照片';
      case 'large':
        return '大文件';
      case 'albums':
        return '相册';
      default:
        return '最近照片';
    }
  }

  void _showIOSDeleteOptions(BuildContext context, PhotoProvider provider) {
    // 检查是否有可删除的照片
    final duplicates = provider.duplicatePhotos.whereType<PhotoModel>().toList();
    final largePhotos = provider.largePhotos.whereType<PhotoModel>().toList();
    
    if (duplicates.isEmpty && largePhotos.isEmpty) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('暂无建议'),
          content: const Text('当前没有重复照片或大文件需要删除。'),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context),
              child: const Text('确定'),
            ),
          ],
        ),
      );
      return;
    }
    
    IOSDeleteOptimizer.showSmartDeleteSuggestions(
      context: context,
      duplicates: duplicates,
      largePhotos: largePhotos,
    );
  }

  void _requestPermissionAndScan(BuildContext context) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => PermissionScreen(
          onPermissionGranted: () {
            Navigator.pop(context);
            context.read<PhotoProvider>().scanPhotos();
          },
        ),
      ),
    );
  }

  void _showNoPhotosDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('没有照片可整理'),
        content: const Text('当前分类中没有找到需要整理的照片。'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}