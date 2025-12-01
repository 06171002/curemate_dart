// lib/features/widgets/common/custom_profile_avatar.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:curemate/app/theme/app_colors.dart';

class CustomProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final File? imageFile;
  final double radius;
  final IconData fallbackIcon;
  final Color? backgroundColor;
  final Color? iconColor;

  const CustomProfileAvatar({
    super.key,
    this.imageUrl,
    this.imageFile,
    this.radius = 24,
    this.fallbackIcon = Icons.person,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    // 파일이 있거나 URL이 있는지 확인
    final bool hasFile = imageFile != null;
    final bool hasUrl = imageUrl != null && imageUrl!.isNotEmpty;

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor ?? AppColors.lightGrey,
        border: Border.all(color: AppColors.inputBorder, width: 1), // 테두리 추가 (수정 화면 등에서 깔끔하게 보임)
      ),
      child: ClipOval(
        child: _buildImageContent(hasFile, hasUrl),
      ),
    );
  }

  Widget _buildImageContent(bool hasFile, bool hasUrl) {
    // 1. 파일이 있으면 최우선 (새로 선택한 이미지)
    if (hasFile) {
      return Image.file(
        imageFile!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildFallbackIcon(),
      );
    }

    // 2. 파일은 없지만 URL이 있으면 네트워크 이미지 (기존 이미지)
    if (hasUrl) {
      return Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildFallbackIcon(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildFallbackIcon();
        },
      );
    }

    // 3. 둘 다 없으면 기본 아이콘
    return _buildFallbackIcon();
  }

  Widget _buildFallbackIcon() {
    return Center(
      child: Icon(
        fallbackIcon,
        size: radius * 1.2,
        color: iconColor ?? AppColors.grey,
      ),
    );
  }
}