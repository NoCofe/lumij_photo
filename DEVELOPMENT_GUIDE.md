# Lumij Photo 开发指南

## 项目概述

Lumij Photo 是一款智能离线相册整理应用，采用Flutter框架开发，具有以下核心功能：

### 已实现功能
1. **基础架构**
   - Flutter项目结构搭建
   - 数据模型设计（PhotoModel, AlbumModel）
   - 数据库服务（SQLite）
   - 状态管理（Provider）

2. **UI界面**
   - iOS风格的主界面设计
   - 统计卡片组件
   - 照片网格展示
   - 设置页面
   - 照片整理界面（滑动操作）

3. **核心服务**
   - 照片扫描和管理服务
   - 图片压缩服务
   - 重复照片检测算法
   - 本地通知服务

### 功能特性

#### 1. 智能识别
- **重复照片检测**: 基于文件哈希值识别重复照片
- **大文件识别**: 按文件大小排序，快速找出占用空间最多的文件
- **智能分类**: 按日期和相册自动分类
- **进度追踪**: 月度整理进度统计

#### 2. 手势操作
- **左右滑动**: 切换照片
- **向上滑动**: 删除照片
- **向下滑动**: 压缩照片
- **点击操作**: 添加到相册

#### 3. 贴心功能
- **每周提醒**: 自定义通知提醒整理照片
- **离线运行**: 完全本地处理，保护隐私
- **iOS风格**: 原生设计风格，用户体验优秀

## 技术架构

### 目录结构
```
lib/
├── main.dart                     # 应用入口
├── models/                       # 数据模型
│   ├── photo_model.dart         # 照片数据模型
│   └── album_model.dart         # 相册数据模型
├── services/                     # 服务层
│   ├── database_service.dart    # 数据库操作
│   ├── photo_service.dart       # 照片处理
│   └── notification_service.dart # 通知服务
├── providers/                    # 状态管理
│   └── photo_provider.dart      # 照片状态管理
├── screens/                      # 页面
│   ├── home_screen.dart         # 主页面
│   ├── simple_home_screen.dart  # 简化主页面
│   ├── photo_organizer_screen.dart # 照片整理页面
│   └── settings_screen.dart     # 设置页面
└── widgets/                      # 组件
    ├── photo_grid.dart          # 照片网格
    ├── photo_item.dart          # 照片项
    ├── album_item.dart          # 相册项
    ├── stats_card.dart          # 统计卡片
    └── swipeable_photo_card.dart # 可滑动照片卡片
```

### 核心依赖
- `photo_manager`: 相册访问
- `flutter_image_compress`: 图片压缩
- `sqflite`: 本地数据库
- `provider`: 状态管理
- `permission_handler`: 权限管理
- `flutter_local_notifications`: 本地通知

## 开发状态

### ✅ 已完成
- [x] 项目架构设计
- [x] 数据模型定义
- [x] 数据库服务实现
- [x] UI界面设计
- [x] 基础组件开发
- [x] 权限配置
- [x] 简化版本演示

### 🚧 开发中
- [ ] 相册扫描功能完善
- [ ] 重复照片检测算法优化
- [ ] 图片压缩功能测试
- [ ] 手势操作完善
- [ ] 通知功能测试

### 📋 待开发
- [ ] 相册创建和管理
- [ ] 批量操作功能
- [ ] 数据导出功能
- [ ] 性能优化
- [ ] 单元测试
- [ ] 集成测试

## 运行指南

### 环境要求
- Flutter 3.8.1+
- Dart 3.0+
- iOS开发需要Xcode 14+
- Android开发需要Android Studio

### 安装步骤

1. **克隆项目**
```bash
git clone <repository-url>
cd lumij_photo
```

2. **安装依赖**
```bash
flutter pub get
```

3. **运行应用**
```bash
# Web版本（推荐用于开发测试）
flutter run -d chrome

# iOS版本
flutter run -d ios

# Android版本
flutter run -d android
```

### 当前版本说明

当前版本使用 `SimpleHomeScreen` 作为主界面，展示了：
- 应用的整体设计风格
- 功能介绍和说明
- 权限请求流程
- 基础UI组件

完整功能版本在 `HomeScreen` 中实现，包含：
- 照片扫描和展示
- 统计信息显示
- 照片整理功能
- 设置管理

## 开发注意事项

### 权限配置
- **Android**: 已在 `android/app/src/main/AndroidManifest.xml` 中配置相册访问权限
- **iOS**: 已在 `ios/Runner/Info.plist` 中配置相册访问权限

### 数据库设计
- 使用SQLite存储照片元数据
- 支持照片、相册、统计信息的存储
- 建立了适当的索引优化查询性能

### 状态管理
- 使用Provider进行状态管理
- 分离了UI和业务逻辑
- 支持响应式UI更新

### 性能考虑
- 图片缩略图缓存
- 分页加载大量照片
- 异步处理耗时操作
- 内存管理优化

## 部署指南

### 构建发布版本

**Android APK**
```bash
flutter build apk --release
```

**iOS IPA**
```bash
flutter build ios --release
```

### 发布准备
1. 更新版本号（pubspec.yaml）
2. 生成应用图标
3. 配置应用签名
4. 测试发布版本
5. 准备应用商店资料

## 贡献指南

1. Fork 项目
2. 创建功能分支
3. 提交更改
4. 推送到分支
5. 创建 Pull Request

## 许可证

MIT License - 详见 LICENSE 文件

---

**开发团队**: Lumij Photo Team  
**最后更新**: 2025年2月  
**版本**: v1.0.0-dev