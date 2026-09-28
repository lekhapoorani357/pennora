import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../services/subscription_service.dart';

/// Phase 4 — Student Verification & Trial Status Page.
///
/// Allows eligible students to:
///   1. View current student verification status (unverified / verified_edu / self_declared_demo)
///   2. Verify via educational email domain (.edu, .ac.in, .edu.in)
///   3. Optionally self-declare demo eligibility (clearly marked is_demo)
///   4. Activate the 30-day student trial
///   5. View remaining trial days with a progress bar and urgency indicators
///
/// Security model:
///   - Backend enforces all eligibility rules — client cannot fake student status
///   - One trial per user, enforced server-side
///   - Verified (.edu) vs. self-declared demo are visually distinct
class StudentVerificationPage extends StatefulWidget {
  const StudentVerificationPage({super.key});

  @override
  State<StudentVerificationPage> createState() => _StudentVerificationPageState();
}

class _StudentVerificationPageState extends State<StudentVerificationPage>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  bool _isVerifying = false;
  bool _isActivatingTrial = false;
  String? _errorMessage;
  String? _successMessage;

  final _eduEmailController = TextEditingController();
  final _institutionController = TextEditingController();
  bool _isDemoSelfDeclared = false;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _loadStudentStatus();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _eduEmailController.dispose();
    _institutionController.dispose();
    super.dispose();
  }

  Future<void> _loadStudentStatus() async {
    setState(() => _isLoading = true);
    await SubscriptionService.instance.fetchStudentStatus();
    await SubscriptionService.instance.fetchStatus();
    if (mounted) {
      setState(() => _isLoading = false);
      _fadeCtrl.forward();
    }
  }

  Future<void> _verify() async {
    final email = _eduEmailController.text.trim();
    final institution = _institutionController.text.trim();

    if (!_isDemoSelfDeclared && email.isEmpty) {
      setState(() => _errorMessage = 'Please enter your educational email address.');
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final ok = await SubscriptionService.instance.verifyStudent(
      studentEmail: email.isEmpty ? null : email,
      institutionName: institution.isEmpty ? null : institution,
      isDemoSelfDeclared: _isDemoSelfDeclared,
    );

    if (mounted) {
      setState(() => _isVerifying = false);
      if (ok) {
        _eduEmailController.clear();
        _institutionController.clear();
        setState(() => _successMessage = _isDemoSelfDeclared
            ? 'Demo eligibility granted. Clearly marked as self-declared (is_demo=true).'
            : 'Student eligibility verified via educational domain.');
        await _loadStudentStatus();
      } else {
        setState(() => _errorMessage =
            'Verification failed. Ensure your email ends with .edu, .ac.in, or .edu.in, '
            'or enable the demo self-declaration toggle below.');
      }
    }
  }

  Future<void> _activateStudentTrial() async {
    setState(() {
      _isActivatingTrial = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final ok = await SubscriptionService.instance.activateTrial(planCode: 'student_monthly');

    if (mounted) {
      setState(() => _isActivatingTrial = false);
      if (ok) {
        setState(() => _successMessage = '🎓 30-Day Student Trial activated successfully!');
        await _loadStudentStatus();
      } else {
        setState(() => _errorMessage =
            'Trial activation failed. You may have already used your one-time student trial, '
            'or your eligibility still needs verification.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final svc = SubscriptionService.instance;

    final verificationStatus = svc.studentVerificationStatus;
    final isEligible = svc.isStudentEligible;
    final institution = svc.studentInstitution;
    final trialDays = svc.studentTrialDays;
    final remainingDays = svc.remainingTrialDays;
    final inTrial = svc.inTrial;
    final isPremium = svc.isPremium;
    final tier = svc.tier;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text(
          'Student Verification',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.4),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.pagePaddingH,
                  vertical: AppDimensions.space16,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeroBanner(isDark, trialDays),
                        const SizedBox(height: AppDimensions.space20),
                        if (inTrial && tier == 'student') ...[
                          _buildActiveTrialCard(isDark, remainingDays, trialDays),
                          const SizedBox(height: AppDimensions.space16),
                        ],
                        if (isPremium && !inTrial && tier == 'student') ...[
                          _buildPaidStudentCard(isDark, institution),
                          const SizedBox(height: AppDimensions.space16),
                        ],
                        _buildVerificationStatusCard(isDark, verificationStatus, isEligible, institution),
                        const SizedBox(height: AppDimensions.space16),
                        if (_successMessage != null) ...[
                          _buildAlert(_successMessage!, isSuccess: true, isDark: isDark),
                          const SizedBox(height: AppDimensions.space12),
                        ],
                        if (_errorMessage != null) ...[
                          _buildAlert(_errorMessage!, isSuccess: false, isDark: isDark),
                          const SizedBox(height: AppDimensions.space12),
                        ],
                        if (!isEligible || verificationStatus == 'unverified') ...[
                          _buildVerificationForm(isDark),
                          const SizedBox(height: AppDimensions.space16),
                        ],
                        if (isEligible && !isPremium) ...[
                          _buildTrialActivationCard(isDark, trialDays),
                          const SizedBox(height: AppDimensions.space16),
                        ],
                        _buildSecurityNotice(isDark),
                        const SizedBox(height: AppDimensions.space32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildHeroBanner(bool isDark, int trialDays) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(60),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(25),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: const Icon(Icons.school_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: AppDimensions.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Student Plan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$trialDays-Day Free Trial · ₹49/mo · .edu / .ac.in eligibility',
                  style: TextStyle(fontSize: 12, color: Colors.white.withAlpha(200)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '50% OFF',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTrialCard(bool isDark, int remainingDays, int totalDays) {
    final urgency = remainingDays <= 3;
    final warning = remainingDays <= 7 && remainingDays > 3;
    final statusColor = urgency
        ? AppColors.error
        : (warning ? AppColors.warning : AppColors.success);
    final bgColor = urgency
        ? AppColors.errorLight
        : (warning ? AppColors.warningLight : AppColors.successLight);

    return Container(
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : bgColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: statusColor.withAlpha(100)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                urgency ? Icons.warning_amber_rounded : Icons.timer_rounded,
                color: statusColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                urgency ? 'Trial Expiring Soon!' : 'Active Student Trial',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: statusColor),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$remainingDays days remaining',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (remainingDays / totalDays).clamp(0.0, 1.0),
                        backgroundColor: statusColor.withAlpha(30),
                        valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                        minHeight: 7,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$totalDays-day student trial',
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimensions.space16),
              Icon(Icons.school_rounded, color: statusColor, size: 38),
            ],
          ),
          if (urgency) ...[
            const SizedBox(height: AppDimensions.space10),
            Text(
              'Upgrade to the paid Student plan to keep your benefits after the trial ends.',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaidStudentCard(bool isDark, String? institution) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.successLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.success.withAlpha(80)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 22),
          const SizedBox(width: AppDimensions.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Active Student Subscription (Paid)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  institution != null ? 'Verified: $institution' : 'All student benefits active.',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationStatusCard(
    bool isDark,
    String verificationStatus,
    bool isEligible,
    String? institution,
  ) {
    final isVerifiedEdu = verificationStatus == 'verified_edu';
    final isSelfDeclared = verificationStatus == 'self_declared_demo';
    final isUnverified = verificationStatus == 'unverified';

    final Color statusColor;
    final IconData statusIcon;
    final String statusTitle;
    final String statusSubtitle;
    final Color bgColor;

    if (isVerifiedEdu) {
      statusColor = AppColors.success;
      statusIcon = Icons.verified_rounded;
      statusTitle = 'Verified Educational Domain';
      statusSubtitle = institution != null
          ? 'Verified via institutional affiliation — $institution'
          : 'Your email domain is recognized as an accredited educational institution.';
      bgColor = isDark ? AppColors.darkSurface : AppColors.successLight;
    } else if (isSelfDeclared) {
      statusColor = AppColors.warning;
      statusIcon = Icons.info_rounded;
      statusTitle = 'Self-Declared Demo Eligibility';
      statusSubtitle =
          'Eligibility accepted in demo/development mode. '
          'Not verified via accredited domain. Marked is_demo=true on all records.';
      bgColor = isDark ? AppColors.darkSurface : AppColors.warningLight;
    } else {
      statusColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
      statusIcon = Icons.badge_outlined;
      statusTitle = 'Not Yet Verified';
      statusSubtitle =
          'Verify with your educational institution email (.edu, .ac.in, .edu.in) '
          'to unlock the subsidized student rate and free trial.';
      bgColor = isDark ? AppColors.darkSurface : const Color(0xFFF1F5F9);
    }

    return Container(
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: statusColor.withAlpha(isUnverified ? 40 : 80)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(statusIcon, color: statusColor, size: 22),
          const SizedBox(width: AppDimensions.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusTitle,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isUnverified
                        ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                        : statusColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  statusSubtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    height: 1.4,
                  ),
                ),
                if (isSelfDeclared) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withAlpha(25),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.warning.withAlpha(60)),
                    ),
                    child: const Text(
                      'is_demo = true  ·  Demo / Development mode only',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationForm(bool isDark) {
    final cardColor = isDark ? AppColors.darkSurface : AppColors.cardBackground;
    final borderColor = isDark ? AppColors.navyBorder : AppColors.cardBorder;
    final labelColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final inputColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.space20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: borderColor),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withAlpha(6),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.mail_outline_rounded, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'VERIFY STUDENT ELIGIBILITY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space16),

          // Educational Email
          Text(
            'Educational Email Address',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _eduEmailController,
            enabled: !_isDemoSelfDeclared,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(fontSize: 14, color: inputColor),
            decoration: InputDecoration(
              hintText: 'yourname@university.edu',
              hintStyle: TextStyle(fontSize: 13, color: labelColor),
              prefixIcon: Icon(Icons.alternate_email_rounded, size: 18, color: labelColor),
              filled: true,
              fillColor: isDark ? AppColors.darkSurfaceVariant : const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: borderColor.withAlpha(80)),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Accepted domains: .edu · .ac.in · .edu.in — no document uploads required.',
            style: TextStyle(fontSize: 10, color: labelColor),
          ),

          const SizedBox(height: AppDimensions.space14),

          // Institution Name (optional)
          Text(
            'Institution Name (optional)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _institutionController,
            style: TextStyle(fontSize: 14, color: inputColor),
            decoration: InputDecoration(
              hintText: 'e.g. IIT Bombay, Harvard University',
              hintStyle: TextStyle(fontSize: 13, color: labelColor),
              prefixIcon: Icon(Icons.account_balance_rounded, size: 18, color: labelColor),
              filled: true,
              fillColor: isDark ? AppColors.darkSurfaceVariant : const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),

          const SizedBox(height: AppDimensions.space16),

          // Demo / Self-declared toggle
          Container(
            padding: const EdgeInsets.all(AppDimensions.space12),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceVariant.withAlpha(80)
                  : const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isDemoSelfDeclared
                    ? AppColors.warning.withAlpha(120)
                    : borderColor,
              ),
            ),
            child: Row(
              children: [
                Switch(
                  value: _isDemoSelfDeclared,
                  onChanged: (val) => setState(() => _isDemoSelfDeclared = val),
                  activeThumbColor: AppColors.warning,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Demo / Self-declared eligibility',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                      Text(
                        'For development/testing only. '
                        'Clearly marked is_demo=true. Not for production accounts.',
                        style: TextStyle(fontSize: 10, color: labelColor, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppDimensions.space20),

          // Verify Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isVerifying ? null : _verify,
              icon: _isVerifying
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.verified_outlined, size: 18),
              label: Text(
                _isVerifying ? 'Verifying…' : 'Verify Student Eligibility',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrialActivationCard(bool isDark, int trialDays) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withAlpha(isDark ? 40 : 15),
            AppColors.secondary.withAlpha(isDark ? 30 : 10),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.primary.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.rocket_launch_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Activate Your $trialDays-Day Student Trial',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space10),
          Text(
            'You are eligible for the Pennora Student subsidized plan. '
            'Activate your $trialDays-day free trial — no payment required. '
            'One trial per account, enforced server-side.',
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppDimensions.space16),
          ...[
            'Full AI Copilot with investment simulator',
            'Student-subsidized rate (₹49/mo after trial)',
            'Career & education savings trackers',
            'Ad-free experience',
          ].map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(Icons.check_rounded, color: AppColors.success, size: 15),
                    const SizedBox(width: 8),
                    Text(
                      f,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: AppDimensions.space16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isActivatingTrial ? null : _activateStudentTrial,
              icon: _isActivatingTrial
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.school_rounded, size: 18),
              label: Text(
                _isActivatingTrial
                    ? 'Activating…'
                    : 'Start $trialDays-Day Student Trial',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'One trial per account · Backend-enforced · No credit card required',
              style: TextStyle(
                fontSize: 10,
                color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityNotice(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space12),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceVariant.withAlpha(80)
            : AppColors.lightLavender,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppColors.navyBorder : AppColors.lavenderBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.security_rounded, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              const Text(
                'SECURITY MODEL',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...[
            'Eligibility is enforced server-side — client cannot fake student status',
            'One trial per user account, enforced in backend analytics events',
            'Trial expiry automatically removes premium entitlement',
            'Self-declared demo is clearly marked is_demo=true on all records',
            'Paid student subscription is distinctly tracked from trial status',
          ].map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '· ',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      s,
                      style: TextStyle(
                        fontSize: 10,
                        height: 1.4,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlert(String message, {required bool isSuccess, required bool isDark}) {
    final color = isSuccess ? AppColors.success : AppColors.error;
    final bg = isSuccess
        ? (isDark ? AppColors.darkSurface : AppColors.successLight)
        : (isDark ? AppColors.darkSurface : AppColors.errorLight);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
