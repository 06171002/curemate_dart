// lib/features/cure_room/view/cure_room_settings_screen.dart

import 'package:curemate/app/theme/app_colors.dart';
import 'package:curemate/features/cure_room/model/cure_room_models.dart';
import 'package:curemate/services/cure_room_service.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:curemate/services/media_service.dart';
import 'package:curemate/features/cure_room/view/follower_list_screen.dart';

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

  String? _roomImageUrl;

  // 🔹 새로 추가: 사용자가 방금 고른 로컬 이미지(미리보기용)
  File? _selectedImage;


  List<_MemberItem> _members = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    final c = widget.cureRoom.cure;

    // 🔹 실제 값이 없으면 빈 문자열로 두고, UI에서 placeholder 처리
    _roomName = (c.cureNm ?? '').trim();
    _roomDescription = (c.cureDesc ?? '').trim();
    _isPublic = c.releaseYn == 'Y';

    // 프로필 이미지 (CurerModel에서 뽑은 URL 그대로 사용)
    _roomImageUrl = c.profileImgUrl;

    // 멤버 리스트 (임시로 custSeq / 타입 코드 표시)
    _members = widget.cureRoom.members.map((m) {
      return _MemberItem(
        name: m.custSeq.toString(),
        roleLabel: m.cureMemberTypeCmcd,
        roleColor: Colors.blue, // TODO: 코드별로 색상 분리 가능
        isMe: false,
      );
    }).toList();

    // 🟣 멤버 더미 데이터 추가
  _members = [
    _MemberItem(
      name: '서지원',  // 본인
      roleLabel: '보호자',
      roleColor: Colors.blue,
      isMe: true,
    ),
    _MemberItem(
      name: '홍길동',
      roleLabel: '간병인',
      roleColor: Colors.green,
    ),
    _MemberItem(
      name: '김철수',
      roleLabel: '가족',
      roleColor: Colors.purple,
    ),
    _MemberItem(
      name: 'Jane',
      roleLabel: '일반',
      roleColor: Colors.orange,
    ),
  ];
  }

// 문자열에서 #태그들만 뽑기
List<String> _extractTags(String text) {
  final reg = RegExp(r'#[^\s#]+'); // #으로 시작해서 공백/다른 # 나오기 전까지
  return reg.allMatches(text).map((m) => m.group(0)!).toList();
}

// 문자열에서 #태그들을 제거한 "순수 소개글"만 남기기
String _stripTags(String text) {
  final reg = RegExp(r'#[^\s#]+');
  final withoutTags = text.replaceAll(reg, '').trim();
  // 중간에 공백 여러 개 생길 수 있으니 정리
  return withoutTags.replaceAll(RegExp(r'\s+'), ' ').trim();
}

  // ===================================================================
  // 🔹 큐어룸 저장 (mergeCureRoom)
  // ===================================================================
  Future<void> _saveCureRoom({
  String? successMessage,
  int? newMediaGroupSeq,   // 🔹 추가
}) async {
  setState(() {
    _isSaving = true;
  });

  try {
    final c = widget.cureRoom.cure;

    final payload = <String, dynamic>{
      'cureSeq': c.cureSeq, // 수정 대상 큐어룸 PK
      'cureNm': _roomName,
      'cureDesc': _roomDescription,
      'releaseYn': _isPublic ? 'Y' : 'N',
      'useYn': 'Y',
    };

    // 🔹 새 mediaGroupSeq가 넘어오면 그걸 우선 사용
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
      // 안드로이드 시스템 뒤로가기 눌렀을 때
      Navigator.of(context).pop(_isPublic);
      return false; // 우리가 직접 pop 했으니 기본 pop 막기
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
        // 🔹 앱바 왼쪽 뒤로가기 버튼도 현재 공개여부를 리턴하게 변경
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () {
            Navigator.of(context).pop(_isPublic);
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
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
      ),
    ),
  );
}

  // ===================================================================
  // 🔹 큐어룸 소개 카드 (사진 + 이름 + 소개글)
  // ===================================================================
  Future<void> _changeRoomImage() async {
  try {
    // 1. 이미지 선택
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (pickedFile == null) return;

    final file = File(pickedFile.path);

    // 🔹 화면 미리보기용으로 먼저 세팅
    setState(() {
      _selectedImage = file;
    });

    // 2. 업로드 (cureSeq 기준으로 서브 디렉토리 분리)
    final c = widget.cureRoom.cure;

    final uploadResult = await _mediaService.uploadFiles(
      files: [file],
      mediaType: "cureRoom",
      subDirectory: c.cureSeq.toString(), // 방별 디렉토리
    );

    final mediaGroupSeq = uploadResult['mediaGroupSeq'];
    if (mediaGroupSeq == null) {
      throw Exception('업로드 결과에 mediaGroupSeq가 없습니다.');
    }

    // 3. 업로드된 mediaGroupSeq로 큐어룸 저장
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
    final hasNetworkImage = _roomImageUrl != null && _roomImageUrl!.isNotEmpty;
    final hasLocalImage = _selectedImage != null;
    final hasAnyImage = hasNetworkImage || hasLocalImage;

    // 🔹 placeholder 텍스트
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
            // 왼쪽: 큐어룸 대표 사진
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
                            ? NetworkImage(_roomImageUrl!) as ImageProvider
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

              // 오른쪽: 이름 + 소개글 + 편집 버튼들
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 큐어룸명 + 편집
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

                    // 소개글 + 편집
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1) 태그 뺀 순수 소개글
                              if (plainDesc.isNotEmpty)
                                Text(
                                  plainDesc,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.blueTextSecondary,
                                  ),
                                ),

                              // 2) 태그 칩들
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

  // 작은 "편집" 버튼
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

  // 이름 편집 다이얼로그
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

  // 소개글 편집 다이얼로그
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
        _roomName = result;
      });

      await _saveCureRoom(
        successMessage: '큐어룸명이 설정되었습니다.',
      );
  }
  }
  // ===================================================================
  // 🔹 팔로워 카드
  // ===================================================================
  Widget _buildFollowerCard() {
  final c = widget.cureRoom.cure;
  final roomName =
      _roomName.isEmpty ? (c.cureNm ?? '큐어룸') : _roomName;

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
            // 이전 값 저장 (실패 시 롤백용)
            final prevValue = _isPublic;
            final c = widget.cureRoom.cure;

            // UI 먼저 바꿔주고
            setState(() {
              _isPublic = value;
            });

            try {
              // 🔹 공개 여부 전용 API 호출
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

              // 실패 시 UI 롤백
              setState(() {
                _isPublic = prevValue;
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('공개 여부 변경 중 오류가 발생했습니다: $e'),
                ),
              );
            }
          },
          activeColor: Color(0xFFA0C4FF),
        ),
      ],
    ),
  );
}

  // ===================================================================
  // 🔹 멤버 카드
  // ===================================================================
  Widget _buildMemberCard() {
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
                onPressed: () {
                  // TODO: 멤버 권한 설정 화면 등
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
              _RoleLegendDot(label: '일반', color: Colors.yellow),
            ],
          ),
          const SizedBox(height: 8),

          // 초대하기
          InkWell(
            onTap: () {
              // TODO: 초대 화면 / 초대 다이얼로그
            },
            borderRadius: BorderRadius.circular(16),
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

          // 멤버 리스트
          ..._members.map(_buildMemberRow).toList(),
        ],
      ),
    );
  }

  Widget _buildMemberRow(_MemberItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.lightGrey,
            child: Text(
              item.name.isNotEmpty ? item.name.substring(0, 1) : '?',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // 이름 + "나" 뱃지
          Expanded(
            child: Row(
              children: [
                if (item.isMe) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: AppColors.grey,
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
                  child: Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.blueTextSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
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

    if (confirmed == true) {
      // TODO: 서버에 큐어룸 나가기 API 호출
      Navigator.of(context).pop();
    }
  }
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

// 멤버 표시용 모델
class _MemberItem {
  final String name;
  final String roleLabel;
  final Color roleColor;
  final bool isMe;

  _MemberItem({
    required this.name,
    required this.roleLabel,
    required this.roleColor,
    this.isMe = false,
  });
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
          fontSize: 12,                // 일반 소개글보다 살짝 작게
          fontWeight: FontWeight.w600, // 조금 볼드하게
          color: AppColors.skyBlue,    // 색상 강조
        ),
      ),
    );
  }
}
