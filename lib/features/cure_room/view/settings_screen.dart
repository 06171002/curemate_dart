// lib/features/cure_room/view/cure_room_settings_screen.dart

import 'dart:io';

import 'package:curemate/app/theme/app_colors.dart';
import 'package:curemate/features/cure_room/model/cure_room_models.dart';
import 'package:curemate/services/cure_room_service.dart';
import 'package:curemate/services/media_service.dart';
import 'package:curemate/features/cure_room/view/follower_list_screen.dart';
import 'package:curemate/routes/route_paths.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:curemate/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:curemate/features/widgets/common/bottom_nav_provider.dart';

class CureRoomSettingsScreen extends StatefulWidget {
  /// 🔹 /rest/cure/cureRoom 응답을 모델로 파싱한 값
  final CureRoomDetailModel cureRoom;

  const CureRoomSettingsScreen({
    super.key,
    required this.cureRoom,
  });

  @override
  State<CureRoomSettingsScreen> createState() =>
      _CureRoomSettingsScreenState();
}

class _CureRoomSettingsScreenState extends State<CureRoomSettingsScreen> {
  final _cureRoomService = CureRoomService();
  final MediaService _mediaService = MediaService();
  final ImagePicker _picker = ImagePicker();

  String _roomName = '큐어룸';
  String _roomDescription = '소개글을 설정해주세요.';
  bool _isPublic = false;

  String? _roomImageUrl; // 큐어룸 대표 이미지
  File? _selectedImage; // 사용자가 새로 고른 로컬 이미지(미리보기용)

  List<_MemberItem> _members = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    // 🔹 큐어룸 기본 정보 세팅
    final c = widget.cureRoom.cure;

    final cureNm = (c.cureNm).trim();
    final cureDesc = (c.cureDesc ?? '').trim();

    _roomName = cureNm.isEmpty ? '큐어룸' : cureNm;
    _roomDescription =
        cureDesc.isEmpty ? '소개글을 설정해주세요.' : cureDesc;
    _isPublic = c.releaseYn == 'Y';

    _roomImageUrl = c.profileImgUrl;

    // 🔹 현재 로그인한 사용자 custSeq
    final int? myCustSeq = context.read<AuthViewModel>().custSeq;

    // 🔹 백엔드에서 온 멤버들(CureMemberModel → _MemberItem)
    final apiMembers = widget.cureRoom.members
        .where((m) => m.exileYn != 'Y') // ⬅⬅ 여기!
        .map((m) {
      final bool isMe = myCustSeq != null && m.custSeq == myCustSeq;
      final bool isOwner = m.cureMemberGradeCmcd == 'owner';
      final bool isManager = m.cureMemberGradeCmcd == 'manager';

      return _MemberItem(
        name: m.displayName,
        roleLabel: m.cureMemberTypeCmnm.isNotEmpty
            ? m.cureMemberTypeCmnm
            : m.cureMemberTypeCmcd,
        roleColor: _roleColorFromType(m.cureMemberTypeCmcd),
        isMe: isMe,
        isOwner: isOwner,
        isManager: isManager,
        imageUrl: m.profileImgUrl,
      );
    }).toList();

    // 🔥 정렬 로직: 나 → 방장 → 부방장 → 그 외
    apiMembers.sort((a, b) {
      // 1. 나 우선
      if (a.isMe && !b.isMe) return -1;
      if (!a.isMe && b.isMe) return 1;

      // 2. 방장 우선
      if (a.isOwner && !b.isOwner) return -1;
      if (!a.isOwner && b.isOwner) return 1;

      // 3. 부방장 우선
      if (a.isManager && !b.isManager) return -1;
      if (!a.isManager && b.isManager) return 1;

      // 4. 그 외는 그대로
      return 0;
    });

    if (apiMembers.isNotEmpty) {
      _members = apiMembers;
    } else {
      // 🔸 API에 멤버가 한 명도 없을 때만 더미 사용 (테스트용)
      _members = [
        _MemberItem(
          name: '서지원',
          roleLabel: '보호자',
          roleColor: Colors.blue,
          isMe: true,
          isOwner: true,
        ),
        _MemberItem(
          name: '홍길동',
          roleLabel: '간병인',
          roleColor: Colors.green,
          isMe: false,
          isOwner: false,
          isManager: true, // 예시로 부방장 하나 넣고 싶으면 이렇게
        ),
        _MemberItem(
          name: '김철수',
          roleLabel: '가족',
          roleColor: Colors.purple,
          isMe: false,
          isOwner: false,
        ),
        _MemberItem(
          name: 'Jane',
          roleLabel: '일반',
          roleColor: Colors.orange,
          isMe: false,
          isOwner: false,
        ),
      ];
    }
  }

  /// 🔄 멤버 목록만 새로고침
  Future<void> _reloadCureRoomMembers() async {
    try {
      final detail = await _cureRoomService.getCureRoom(
        widget.cureRoom.cure.cureSeq,
      );

      // 다시 로그인 유저 가져오기
      final int? myCustSeq = context.read<AuthViewModel>().custSeq;

      // 🔹 API에서 내려온 멤버들을 _MemberItem으로 다시 매핑
      final refreshed = detail.members
          .where((m) => m.exileYn != 'Y') // ⬅⬅ 여기!
          .map((m) {
        final bool isMe = myCustSeq != null && m.custSeq == myCustSeq;
        final bool isOwner = m.cureMemberGradeCmcd == 'owner';
        final bool isManager = m.cureMemberGradeCmcd == 'manager';

        return _MemberItem(
          name: m.displayName,
          roleLabel: m.cureMemberTypeCmnm.isNotEmpty
              ? m.cureMemberTypeCmnm
              : m.cureMemberTypeCmcd,
          roleColor: _roleColorFromType(m.cureMemberTypeCmcd),
          isMe: isMe,
          isOwner: isOwner,
          isManager: isManager,
          imageUrl: m.profileImgUrl,
        );
      }).toList();

      // 🔥 정렬(나 → 방장 → 부방장 → 그 외) 다시 적용
      refreshed.sort((a, b) {
        if (a.isMe && !b.isMe) return -1;
        if (!a.isMe && b.isMe) return 1;

        if (a.isOwner && !b.isOwner) return -1;
        if (!a.isOwner && b.isOwner) return 1;

        if (a.isManager && !b.isManager) return -1;
        if (!a.isManager && b.isManager) return 1;

        return 0;
      });

      setState(() {
        _members = refreshed;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('멤버 목록 새로고침 중 오류가 발생했습니다: $e'),
        ),
      );
    }
  }

  // 타입 코드별 색상
  Color _roleColorFromType(String typeCode) {
    switch (typeCode) {
      case 'guardian':
        return Colors.blue;
      case 'caregiver':
        return Colors.green;
      case 'family':
        return Colors.purple;
      case 'user':
      default:
        return Colors.orange;
    }
  }

  // 문자열에서 #태그들만 뽑기
  List<String> _extractTags(String text) {
    final reg = RegExp(r'#[^\s#]+');
    return reg.allMatches(text).map((m) => m.group(0)!).toList();
  }

  // 문자열에서 #태그들을 제거한 "순수 소개글"만 남기기
  String _stripTags(String text) {
    final reg = RegExp(r'#[^\s#]+');
    final withoutTags = text.replaceAll(reg, '').trim();
    return withoutTags.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  // ===================================================================
  // 🔹 큐어룸 저장 (mergeCureRoom)
  // ===================================================================
  Future<void> _saveCureRoom({
    String? successMessage,
    int? newMediaGroupSeq,
  }) async {
    setState(() {
      _isSaving = true;
    });

    try {
      final c = widget.cureRoom.cure;

      final payload = <String, dynamic>{
        'cureSeq': c.cureSeq,
        'cureNm': _roomName,
        'cureDesc': _roomDescription,
        'releaseYn': _isPublic ? 'Y' : 'N',
        'useYn': 'Y',
      };

      if (newMediaGroupSeq != null) {
        payload['cureMediaGroupSeq'] = newMediaGroupSeq;
      } else if (c.cureMediaGroupSeq != null) {
        payload['cureMediaGroupSeq'] = c.cureMediaGroupSeq;
      }

      await _cureRoomService.saveCureRoom(payload);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            successMessage ?? '큐어룸 설정이 저장되었습니다.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 중 오류가 발생했습니다: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // ===================================================================
  // 🔹 build
  // ===================================================================
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(_isPublic);
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColors.lightBackground,
        appBar: AppBar(
          backgroundColor: AppColors.lightBackground,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.black),
          title: const Text(
            '큐어룸 설정',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
            onPressed: () {
              Navigator.of(context).pop(_isPublic);
            },
          ),
        ),
        body: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    _buildRoomIntroCard(),
                    _buildFollowerCard(),
                    _buildPublicToggleCard(),
                    _buildMemberCard(),
                    const SizedBox(height: 12),
                    _buildLeaveRoomButton(),
                  ],
                ),
              ),
              if (_isSaving)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.05),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ===================================================================
  // 🔹 큐어룸 소개 카드
  // ===================================================================
  Future<void> _changeRoomImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      final file = File(pickedFile.path);

      setState(() {
        _selectedImage = file;
      });

      final c = widget.cureRoom.cure;

      final uploadResult = await _mediaService.uploadFiles(
        files: [file],
        mediaType: "cureRoom",
        subDirectory: c.cureSeq.toString(),
      );

      final mediaGroupSeq = uploadResult['mediaGroupSeq'];
      if (mediaGroupSeq == null) {
        throw Exception('업로드 결과에 mediaGroupSeq가 없습니다.');
      }

      await _saveCureRoom(
        newMediaGroupSeq: int.parse(mediaGroupSeq.toString()),
        successMessage: '큐어룸 사진이 변경되었습니다.',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('사진 변경 중 오류가 발생했습니다: $e'),
        ),
      );
    }
  }

  Widget _buildRoomIntroCard() {
    final hasNetworkImage =
        _roomImageUrl != null && _roomImageUrl!.isNotEmpty;
    final hasLocalImage = _selectedImage != null;
    final hasAnyImage = hasNetworkImage || hasLocalImage;

    final displayRoomName =
        _roomName.isEmpty ? '큐어룸명을 설정해주세요' : _roomName;
    final displayRoomDesc =
        _roomDescription.isEmpty ? '큐어룸 소개글을 설정해주세요' : _roomDescription;

    final rawDesc = displayRoomDesc;
    final tags = _extractTags(rawDesc);
    final plainDesc = _stripTags(rawDesc);

    return _SettingsCard(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '큐어룸 소개',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.blueTextSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _changeRoomImage,
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.lightGrey,
                      backgroundImage: hasLocalImage
                          ? FileImage(_selectedImage!)
                          : (hasNetworkImage
                              ? NetworkImage(_roomImageUrl!)
                                  as ImageProvider
                              : null),
                      child: !hasAnyImage
                          ? const Icon(
                              Icons.home_filled,
                              color: AppColors.grey,
                              size: 28,
                            )
                          : null,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '사진 변경',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.skyBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            displayRoomName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.black,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _buildSmallEditButton(onTap: _editRoomName),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (plainDesc.isNotEmpty)
                                Text(
                                  plainDesc,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.blueTextSecondary,
                                  ),
                                ),
                              if (tags.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: tags
                                      .map((tag) => _TagChip(label: tag))
                                      .toList(),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildSmallEditButton(onTap: _editRoomDescription),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallEditButton({required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.lightBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.lightGrey),
        ),
        child: const Text(
          '편집',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.blueTextSecondary,
          ),
        ),
      ),
    );
  }

  Future<void> _editRoomName() async {
    final controller = TextEditingController(
      text: _roomName.isEmpty ? '' : _roomName,
    );
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('큐어룸 이름 수정'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: '큐어룸 이름을 입력하세요',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(controller.text.trim());
              },
              child: const Text('저장'),
            ),
          ],
        );
      },
    );

    if (result == null) return;

    if (result.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('큐어룸명을 입력해주세요.')),
      );
      return;
    }

    setState(() {
      _roomName = result;
    });

    await _saveCureRoom(
      successMessage: '큐어룸명이 설정되었습니다.',
    );
  }

  Future<void> _editRoomDescription() async {
    final controller = TextEditingController(
      text: _roomDescription.isEmpty ? '' : _roomDescription,
    );
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('소개글 수정'),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: '소개글을 입력하세요',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(controller.text.trim());
              },
              child: const Text('저장'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      if (result.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('큐어룸명을 입력해주세요.')),
        );
        return;
      }

      setState(() {
        _roomDescription = result;
      });

      await _saveCureRoom(
        successMessage: '소개글이 설정되었습니다.',
      );
    }
  }

  // ===================================================================
  // 🔹 팔로워 카드
  // ===================================================================
  Widget _buildFollowerCard() {
    final c = widget.cureRoom.cure;
    final roomName = _roomName.isEmpty ? (c.cureNm) : _roomName;

    return _SettingsCard(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CureRoomFollowerListScreen(
                cureSeq: c.cureSeq,
                roomName: roomName,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              '팔로워 목록',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.blueTextSecondary,
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.grey),
          ],
        ),
      ),
    );
  }

  // ===================================================================
  // 🔹 공개 여부 설정 카드
  // ===================================================================
  Widget _buildPublicToggleCard() {
    return _SettingsCard(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '공개여부 설정',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.blueTextSecondary,
            ),
          ),
          Switch(
            value: _isPublic,
            onChanged: (value) async {
              final prevValue = _isPublic;
              final c = widget.cureRoom.cure;

              setState(() {
                _isPublic = value;
              });

              try {
                await _cureRoomService.updateCureRoomRelease(
                  cureSeq: c.cureSeq,
                  isPublic: value,
                );

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      value
                          ? '큐어룸이 공개로 전환되었습니다.'
                          : '큐어룸이 비공개로 전환되었습니다.',
                    ),
                  ),
                );
              } catch (e) {
                if (!mounted) return;

                setState(() {
                  _isPublic = prevValue;
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text('공개 여부 변경 중 오류가 발생했습니다: $e'),
                  ),
                );
              }
            },
            activeColor: const Color(0xFFA0C4FF),
          ),
        ],
      ),
    );
  }

  // ===================================================================
  // 🔹 멤버 카드
  // ===================================================================
  Widget _buildMemberCard() {
    final c = widget.cureRoom.cure;
    final roomName = _roomName.isEmpty ? (c.cureNm) : _roomName;

    return _SettingsCard(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단: "멤버 N" + 설정 아이콘
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '멤버 ${_members.length}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.blueTextSecondary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.settings, size: 20),
                onPressed: () async {
                  final name =
                      _roomName.isEmpty ? (c.cureNm) : _roomName;

                  // 🔹 멤버관리 화면으로 이동
                  await GoRouter.of(context).push(
                    '${RoutePaths.memberManage}'
                    '?cureSeq=${c.cureSeq}'
                    '&roomName=${Uri.encodeComponent(name)}',
                    extra: widget.cureRoom.members, // ← 기존 그대로
                  );

                  // 🔥 돌아오면 무조건 서버에서 다시 멤버 가져와서 새로고침
                  await _reloadCureRoomMembers();
                },
              ),
            ],
          ),
          const SizedBox(height: 4),

          // 역할 색상 범례
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: const [
              _RoleLegendDot(label: '보호자', color: Colors.blue),
              SizedBox(width: 8),
              _RoleLegendDot(label: '간병인', color: Colors.green),
              SizedBox(width: 8),
              _RoleLegendDot(label: '가족', color: Colors.purple),
              SizedBox(width: 8),
              _RoleLegendDot(label: '일반', color: Colors.orange),
            ],
          ),
          const SizedBox(height: 8),

          // 초대하기
          InkWell(
            onTap: () {
              // TODO: 초대 기능
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: const [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.lightBackground,
                    child: Icon(Icons.add, color: AppColors.skyBlue),
                  ),
                  SizedBox(width: 8),
                  Text(
                    '초대하기',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.skyBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          ..._members.map(_buildMemberRow).toList(),
        ],
      ),
    );
  }

  Widget _buildMemberRow(_MemberItem item) {
    final hasImage =
        item.imageUrl != null && item.imageUrl!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.lightGrey,
            backgroundImage:
                hasImage ? NetworkImage(item.imageUrl!) : null,
            child: !hasImage
                ? Text(
                    item.name.isNotEmpty
                        ? item.name.substring(0, 1)
                        : '?',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),

          // 이름 + "나" 뱃지 + 방장/부방장 아이콘
          Expanded(
            child: Row(
              children: [
                if (item.isMe) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: AppColors.skyBlue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      '나',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                Flexible(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.blueTextSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (item.isOwner) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.stars,
                          color: Colors.amber,
                          size: 18,
                        ),
                      ] else if (item.isManager) ...[
                        const SizedBox(width: 6),
                        Icon(
                          Icons.workspace_premium,
                          color: Colors.blue.shade400,
                          size: 18,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 역할 색 점
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: item.roleColor,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  // ===================================================================
  // 🔹 큐어룸 나가기
  // ===================================================================
  Widget _buildLeaveRoomButton() {
    return _SettingsCard(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: InkWell(
        onTap: _confirmLeaveRoom,
        child: const Text(
          '큐어룸 나가기',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.red,
          ),
        ),
      ),
    );
  }

  /// 🔹 실제로 서버에 "큐어룸 나가기" 요청 보내는 함수
  Future<void> _leaveCureRoomOnServer() async {
    // 1) 현재 로그인한 사용자 custSeq
    final int? myCustSeq = context.read<AuthViewModel>().custSeq;

    if (myCustSeq == null) {
      throw Exception('로그인 정보를 찾을 수 없습니다.(custSeq 없음)');
    }

    // 2) cureRoom.members 중에서 내 멤버 레코드 찾기
    dynamic myMember;
    try {
      myMember = widget.cureRoom.members.firstWhere(
        (m) => m.custSeq == myCustSeq,
      );
    } catch (_) {
      myMember = null;
    }

    if (myMember == null) {
      throw Exception('이 큐어룸에서 본인 멤버 정보를 찾을 수 없습니다.');
    }

    final int cureMemberSeq = myMember.cureMemberSeq as int;

    // 3) 서비스 호출
    await _cureRoomService.deleteCureMember(cureMemberSeq);
  }

  Future<void> _confirmLeaveRoom() async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('큐어룸 나가기'),
      content: const Text('정말 이 큐어룸에서 나가시겠어요?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('나가기'),
        ),
      ],
    ),
  );

  if (confirmed != true) return;

  try {
    // 1) 서버에서 내 멤버 삭제
    await _leaveCureRoomOnServer();

    if (!mounted) return;

    // 2) 큐어모드 해제 + 홈 탭으로 이동
    final nav = context.read<BottomNavProvider>();
    nav.clearCurer();       // 👈 큐어룸 선택 해제 (isMainMode로 돌아가게)
    nav.changeIndex(0);     // 👈 BottomNav 홈 탭으로 맞추기

    // 3) 메인 레이아웃으로 이동
    context.go(RoutePaths.main);
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('큐어룸 나가기 중 오류가 발생했습니다: $e'),
      ),
    );
  }
}
}

// ------------------------------------------------------
// 🔹 멤버 표시용 모델
// ------------------------------------------------------
class _MemberItem {
  final String name;
  final String roleLabel;
  final Color roleColor;
  final bool isMe;
  final bool isOwner;
  final bool isManager;
  final String? imageUrl;

  _MemberItem({
    required this.name,
    required this.roleLabel,
    required this.roleColor,
    this.isMe = false,
    this.isOwner = false,
    this.isManager = false,
    this.imageUrl,
  });
}

// ------------------------------------------------------
// 🔹 공용 카드 위젯 (둥근 흰색 카드)
// ------------------------------------------------------
class _SettingsCard extends StatelessWidget {
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  final Widget child;

  const _SettingsCard({
    super.key,
    required this.child,
    this.margin = const EdgeInsets.all(12),
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

// 역할 범례용 작은 점
class _RoleLegendDot extends StatelessWidget {
  final String label;
  final Color color;

  const _RoleLegendDot({
    super.key,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.blueTextSecondary,
          ),
        ),
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;

  const _TagChip({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.lightBackground,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.skyBlue.withOpacity(0.7),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.skyBlue,
        ),
      ),
    );
  }
}
