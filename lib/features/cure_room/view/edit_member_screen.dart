import 'package:curemate/app/theme/app_colors.dart';
import 'package:curemate/features/cure_room/model/cure_room_models.dart';
import 'package:curemate/services/cure_room_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:curemate/features/auth/viewmodel/auth_viewmodel.dart';

class CureRoomMemberManageScreen extends StatefulWidget {
  final int cureSeq;
  final String roomName;
  final List<CureMemberModel> members; // 설정 화면에서 전달 (API 결과)

  const CureRoomMemberManageScreen({
    super.key,
    required this.cureSeq,
    required this.roomName,
    required this.members,
  });

  @override
  State<CureRoomMemberManageScreen> createState() =>
      _CureRoomMemberManageScreenState();
}

class _CureRoomMemberManageScreenState
    extends State<CureRoomMemberManageScreen> {
  final _service = CureRoomService();

  late List<CureMemberModel> _members;
  bool _isSaving = false;
  bool _isLoading = false; // ✅ 서버에서 목록 새로고침 로딩 플래그

  int? _myCustSeq; // ✅ 내 custSeq 저장

  // 권한/타입 코드-라벨 매핑
  final List<Map<String, String>> _gradeOptions = const [
    {'code': 'owner', 'label': '방장'},
    {'code': 'manager', 'label': '부방장'},
    {'code': 'user', 'label': '일반사용자'},
    {'code': 'restricted', 'label': '제한된사용자'},
  ];

  final List<Map<String, String>> _typeOptions = const [
    {'code': 'guardian', 'label': '보호자'},
    {'code': 'caregiver', 'label': '간병인'},
    {'code': 'family', 'label': '가족'},
    {'code': 'general', 'label': '일반'},
  ];

  /// ✅ 등급 코드별 우선순위 (숫자가 작을수록 위로)
  int _gradePriority(String code) {
    switch (code) {
      case 'owner': // 방장
        return 0;
      case 'manager': // 부방장
        return 1;
      case 'user': // 일반사용자
        return 2;
      case 'restricted': // 제한된사용자
        return 3;
      default:
        return 4;
    }
  }

  /// ✅ 멤버 정렬: 나 → 방장/마스터 → 부방장 → 그 외
  void _sortMembers() {
    if (_members.isEmpty) return;
    final my = _myCustSeq;

    _members.sort((a, b) {
      final aIsMe = my != null && a.custSeq == my;
      final bIsMe = my != null && b.custSeq == my;

      // 1. 나 우선
      if (aIsMe && !bIsMe) return -1;
      if (!aIsMe && bIsMe) return 1;

      // 2. 등급 우선순위
      final aGradeP = _gradePriority(a.cureMemberGradeCmcd);
      final bGradeP = _gradePriority(b.cureMemberGradeCmcd);
      if (aGradeP != bGradeP) {
        return aGradeP.compareTo(bGradeP);
      }

      // 3. 그 외는 그대로
      return 0;
    });
  }

  /// ✅ 더미 멤버 리스트 (서버/부모 둘 다 비었을 때만 사용)
  List<CureMemberModel> _buildDummyMembers() {
    return [
      CureMemberModel(
        cureMemberSeq: 0, // 더미 표시용
        cureSeq: widget.cureSeq,
        custSeq: 0,
        cureMemberGradeCmcd: 'owner',
        cureMemberGradeCmnm: '방장',
        cureMemberTypeCmcd: 'guardian',
        cureMemberTypeCmnm: '보호자',
        exileYn: 'N',
        memberProfile: const {},
        custNm: '예시 보호자',
        custNickname: '예시 보호자',
        custMediaGroupSeq: 0,
        withdrawYn: 'N',
        withdrawDttm: null,
      ),
      CureMemberModel(
        cureMemberSeq: 0,
        cureSeq: widget.cureSeq,
        custSeq: 0,
        cureMemberGradeCmcd: 'user',
        cureMemberGradeCmnm: '일반사용자',
        cureMemberTypeCmcd: 'family',
        cureMemberTypeCmnm: '가족',
        exileYn: 'N',
        memberProfile: const {},
        custNm: '예시 가족',
        custNickname: '예시 가족',
        custMediaGroupSeq: 0,
        withdrawYn: 'N',
        withdrawDttm: null,
      ),
    ];
  }

  /// ✅ 서버에서 멤버 목록 다시 가져오기 (화면 진입 시 + 필요할 때 호출)
  Future<void> _reloadMembersFromServer({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final detail = await _service.getCureRoom(widget.cureSeq);

      // exileYn == 'Y' 는 제외
      final serverMembers = detail.members
          .where((m) => m.exileYn != 'Y')
          .toList();

      setState(() {
        if (serverMembers.isEmpty) {
          _members = _buildDummyMembers();
        } else {
          _members = serverMembers;
        }
        _sortMembers();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('멤버 목록 새로고침 중 오류가 발생했어요.\n$e'),
        ),
      );
    } finally {
      if (!mounted) return;
      if (showLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();

    // ✅ 현재 로그인한 사용자 custSeq
    _myCustSeq = context.read<AuthViewModel>().custSeq;

    // 1차: 부모에서 받은 데이터로 먼저 그려주기 (추방된 멤버는 제외)
    if (widget.members.isEmpty) {
      _members = _buildDummyMembers();
    } else {
      _members = widget.members
          .where((m) => m.exileYn != 'Y')
          .toList();
    }
    _sortMembers();

    // 2차: 화면에 진입할 때마다 항상 서버에서 최신 데이터로 한 번 더 새로고침
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reloadMembersFromServer();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.lightBackground,
          appBar: AppBar(
            backgroundColor: AppColors.lightBackground,
            elevation: 0,
            centerTitle: true,
            iconTheme: const IconThemeData(color: Colors.black),
            title: const Text(
              '멤버 관리',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.roomName,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '멤버 ${_members.length}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.blueTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                 Align(
                    alignment: Alignment.centerRight,
                    child: const Text(
                      '방장 / 부방장 / 일반사용자:  읽기·쓰기 가능 \n'
                      '제한된사용자: 읽기만 가능',
                      textAlign: TextAlign.right,  // 🔹 텍스트 오른쪽 정렬
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.grey,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Container(
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
                      child: _members.isEmpty
                          ? const Center(
                              child: Text(
                                '아직 멤버가 없습니다.',
                                style: TextStyle(
                                  color: AppColors.blueTextSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            )
                          : ListView.separated(
                              itemCount: _members.length,
                              separatorBuilder: (_, __) => const Divider(
                                height: 1,
                                color: AppColors.lightGrey,
                              ),
                              itemBuilder: (context, index) {
                                final m = _members[index];
                                return _buildMemberRow(m);
                              },
                            ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),

        // 저장 중 로딩 오버레이
        if (_isSaving || _isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.05),
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }

  Widget _buildMemberRow(CureMemberModel member) {
    final imgUrl = member.profileImgUrl; // getter라고 가정
    final isExiled = member.isExiled; // exileYn 기반 getter라고 가정
    final isDummy = member.cureMemberSeq == 0;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: AppColors.lightGrey,
        backgroundImage: imgUrl != null ? NetworkImage(imgUrl) : null,
        child: imgUrl == null
            ? Text(
                member.displayName.isNotEmpty
                    ? member.displayName.substring(0, 1)
                    : '?',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              )
            : null,
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              member.displayName,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isExiled ? AppColors.grey : AppColors.blueTextSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          if (isDummy) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.lightGrey.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '예시',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],

          if (isExiled) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '추방됨',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(
        '권한: ${member.cureMemberGradeCmnm} · 타입: ${member.cureMemberTypeCmnm}',
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.grey,
        ),
      ),
      trailing: TextButton(
        onPressed: () => _openEditMemberBottomSheet(member),
        child: const Text(
          '편집',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.skyBlue,
          ),
        ),
      ),
    );
  }

  Future<void> _openEditMemberBottomSheet(CureMemberModel member) async {
    String selectedGrade = member.cureMemberGradeCmcd;
    String selectedType = member.cureMemberTypeCmcd;
    bool exile = member.isExiled;
    final isDummy = member.cureMemberSeq == 0;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.lightGrey,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Text(
                    member.displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.blueTextSecondary,
                    ),
                  ),
                  if (isDummy) ...[
                    const SizedBox(height: 4),
                    const Text(
                      '예시 멤버는 실제로 저장/변경되지 않습니다.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.grey,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  const Text(
                    '권한',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.blueTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _gradeOptions.map((opt) {
                      final code = opt['code']!;
                      final label = opt['label']!;
                      final selected = (selectedGrade == code);
                      return ChoiceChip(
                        label: Text(label),
                        selected: selected,
                        onSelected: (_) {
                          setModalState(() {
                            selectedGrade = code;
                          });
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),
                  const Text(
                    '타입',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.blueTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _typeOptions.map((opt) {
                      final code = opt['code']!;
                      final label = opt['label']!;
                      final selected = (selectedType == code);
                      return ChoiceChip(
                        label: Text(label),
                        selected: selected,
                        onSelected: (_) {
                          setModalState(() {
                            selectedType = code;
                          });
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '이 멤버 추방하기',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.blueTextSecondary,
                        ),
                      ),
                      Switch(
                        value: exile,
                        onChanged: (val) async {
                          // ⬇️ false → true 로 바꾸는 순간에만 확인 다이얼로그
                          if (!exile && val) {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('멤버 추방'),
                                content: Text(
                                  '"${member.displayName}"님을 정말 추방하시겠어요?\n'
                                  '추방된 멤버는 목록에서 보이지 않게 됩니다.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(false),
                                    child: const Text('취소'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(true),
                                    child: const Text('추방하기'),
                                  ),
                                ],
                              ),
                            );

                            if (confirmed != true) {
                              // 취소 시 스위치 상태 유지
                              return;
                            }
                          }

                          setModalState(() {
                            exile = val;
                          });
                        },
                        activeColor: const Color(0xFFA0C4FF),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('취소'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.of(context).pop();
                            await _saveMemberChange(
                              member: member,
                              gradeCode: selectedGrade,
                              typeCode: selectedType,
                              exile: exile,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFA0C4FF),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('저장'),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _saveMemberChange({
    required CureMemberModel member,
    required String gradeCode,
    required String typeCode,
    required bool exile,
  }) async {
    // 🔐 더미 멤버는 서버에 저장/추방 안 함
    if (member.cureMemberSeq == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('예시 멤버는 실제로 저장되지 않아요.'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final updated = await _service.mergeCureMember(
        cureMemberSeq: member.cureMemberSeq,
        gradeCode: gradeCode,
        typeCode: typeCode,
        exile: exile,
      );

      if (!mounted) return;

      setState(() {
        // ✅ 추방 상태가 되면 목록에서 제거
        if (updated.isExiled) {
          _members.removeWhere(
              (m) => m.cureMemberSeq == member.cureMemberSeq);
        } else {
          _members = _members.map((m) {
            if (m.cureMemberSeq == member.cureMemberSeq) {
              return updated;
            }
            return m;
          }).toList();

          // ✅ 추방이 아니라면 정렬 유지
          _sortMembers();
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            updated.isExiled
                ? '멤버를 추방했습니다.'
                : '멤버 정보가 저장되었습니다.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('멤버 저장 중 오류가 발생했어요.\n$e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}
