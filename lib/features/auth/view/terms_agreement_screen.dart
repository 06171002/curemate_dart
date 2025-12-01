// lib/features/auth/view/terms_agreement_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../routes/route_paths.dart';
import '../viewmodel/auth_viewmodel.dart';
import '../model/policy_model.dart';

class TermsAgreementScreen extends StatefulWidget {
  const TermsAgreementScreen({super.key});

  @override
  State<TermsAgreementScreen> createState() => _TermsAgreementScreenState();
}

class _TermsAgreementScreenState extends State<TermsAgreementScreen> {
  // 선택된 약관 ID(policySeq)들을 저장
  final Set<int> _agreedPolicyIds = {};
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // 화면 진입 시 약관 목록 조회
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthViewModel>().fetchPolicies().then((_) {
        if (mounted) {
          setState(() => _isInitialized = true);
        }
      });
    });
  }

  // 전체 동의 토글
  void _toggleAll(bool? value, List<PolicyModel> policies) {
    setState(() {
      if (value == true) {
        _agreedPolicyIds.addAll(policies.map((e) => e.policySeq));
      } else {
        _agreedPolicyIds.clear();
      }
    });
  }

  // 개별 항목 토글
  void _toggleItem(int id, bool? value) {
    setState(() {
      if (value == true) {
        _agreedPolicyIds.add(id);
      } else {
        _agreedPolicyIds.remove(id);
      }
    });
  }

  // 시작하기 버튼
  Future<void> _onStartPressed() async {
    final viewModel = context.read<AuthViewModel>();
    await viewModel.completeTermsAgreement(_agreedPolicyIds.toList());
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AuthViewModel>();
    final policies = viewModel.policies;

    // 전체 동의 여부 확인
    final bool isAllAgreed = policies.isNotEmpty &&
        _agreedPolicyIds.length == policies.length;

    // 필수 약관 모두 동의했는지 확인
    final bool requiredAllAgreed = policies
        .where((p) => p.isRequired)
        .every((p) => _agreedPolicyIds.contains(p.policySeq));

    final bool canProceed = requiredAllAgreed && !viewModel.isLoading && _isInitialized;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top:true,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              const Text(
                '환영합니다!\n아래 약관에 동의하시면\nCure Mate 이용이 시작됩니다',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  height: 1.4,
                  color: AppColors.black,
                ),
              ),

              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  margin: const EdgeInsets.only(top: 20, bottom: 40),
                  width: 100,
                  height: 100,
                  child: const Icon(Icons.health_and_safety, size: 80, color: AppColors.mainBtn),
                ),
              ),

              if (viewModel.isLoading && !_isInitialized)
                const Expanded(child: Center(child: CircularProgressIndicator()))
              else ...[
                // 전체 동의
                _buildCheckboxRow(
                  value: isAllAgreed,
                  label: '전체 동의',
                  isBold: true,
                  onChanged: (v) => _toggleAll(v, policies),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Divider(height: 1, color: AppColors.lightGrey),
                ),

                // 약관 리스트 (Expanded로 남은 공간 사용)
                Expanded(
                  child: ListView.builder(
                    itemCount: policies.length,
                    itemBuilder: (context, index) {
                      final policy = policies[index];
                      // 필수/선택 텍스트
                      final String suffix = policy.isRequired ? '(필수)' : '(선택)';

                      return _buildCheckboxRow(
                        value: _agreedPolicyIds.contains(policy.policySeq),
                        label: '${policy.policyNm} $suffix',
                        hasArrow: policy.hasDetail, // 상세 내용 없으면 화살표 숨김
                        onChanged: (v) => _toggleItem(policy.policySeq, v),
                        onTapArrow: () {
                          // ✅ 상세 화면 이동 (쿼리 파라미터 사용)
                          // 예: /terms_detail?seq=1
                          context.push(
                            Uri(
                              path: RoutePaths.termsDetail,
                              queryParameters: {'seq': policy.policySeq.toString()},
                            ).toString(),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],

              // 시작하기 버튼
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: canProceed ? _onStartPressed : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.mainBtn,
                    disabledBackgroundColor: AppColors.lightGrey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: viewModel.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                    '시작하기',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: canProceed ? Colors.white : Colors.grey[500],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckboxRow({
    required bool value,
    required String label,
    required Function(bool?) onChanged,
    bool isBold = false,
    bool hasArrow = false,
    VoidCallback? onTapArrow,
  }) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => onChanged(!value),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: value,
                      onChanged: onChanged,
                      activeColor: AppColors.mainBtn,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      side: BorderSide(color: Colors.grey[400]!, width: 1.5),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        if (hasArrow)
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onPressed: onTapArrow,
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(12),
          ),
      ],
    );
  }
}