import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../services/household_service.dart';
import '../../services/subscription_service.dart';

class FamilyHouseholdPage extends StatefulWidget {
  const FamilyHouseholdPage({super.key});

  @override
  State<FamilyHouseholdPage> createState() => _FamilyHouseholdPageState();
}

class _FamilyHouseholdPageState extends State<FamilyHouseholdPage> {
  final _emailController = TextEditingController();
  final _nameController = TextEditingController(text: 'My Family Household');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      HouseholdService.instance.fetchMyHousehold();
      HouseholdService.instance.fetchMyInvitations();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _showInviteDialog(BuildContext context) {
    _emailController.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Invite Family Member'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the email address of the family member you wish to invite.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Member Email',
                hintText: 'spouse@example.com',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Privacy Note: Adding a member shares family plan entitlement. Their private transactions and goals remain strictly isolated.',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = _emailController.text.trim();
              final messenger = ScaffoldMessenger.of(context);
              if (email.isEmpty || !email.contains('@')) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Please enter a valid email address')),
                );
                return;
              }
              Navigator.of(ctx).pop();
              final success = await HouseholdService.instance.inviteMember(email);
              if (!mounted) return;
              if (success) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Invitation sent to $email')),
                );
              } else {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(HouseholdService.instance.errorMessage ?? 'Failed to invite'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Send Invite'),
          ),
        ],
      ),
    );
  }

  void _showCreateHouseholdDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Family Household'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Set a name for your family group to share your Pennora Family subscription.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Household Name',
                hintText: 'The Henderson Family',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final messenger = ScaffoldMessenger.of(context);
              final name = _nameController.text.trim();
              final success = await HouseholdService.instance.createHousehold(
                name.isEmpty ? 'My Family Household' : name,
              );
              if (!mounted) return;
              if (success) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Family household created!')),
                );
              } else {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(HouseholdService.instance.errorMessage ?? 'Failed to create'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: Listenable.merge([HouseholdService.instance, SubscriptionService.instance]),
      builder: (context, _) {
        final service = HouseholdService.instance;
        final subService = SubscriptionService.instance;
        final household = service.household;
        final isFamilySub = subService.tier == 'family';
        final myInvitations = service.myInvitations;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Family Household'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
                onPressed: () {
                  service.fetchMyHousehold();
                  service.fetchMyInvitations();
                },
              ),
            ],
          ),
          body: service.isLoading && household == null
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () async {
                    await service.fetchMyHousehold();
                    await service.fetchMyInvitations();
                  },
                  child: ListView(
                    padding: const EdgeInsets.all(AppDimensions.space16),
                    children: [
                      // Pending Invitations Banner (if any incoming)
                      if (myInvitations.isNotEmpty) ...[
                        _buildIncomingInvitationsCard(context, myInvitations, isDark),
                        const SizedBox(height: AppDimensions.space16),
                      ],

                      // Privacy Fortress Banner
                      _buildPrivacyBanner(context, isDark),
                      const SizedBox(height: AppDimensions.space16),

                      if (household == null)
                        _buildNoHouseholdView(context, isFamilySub, isDark)
                      else ...[
                        _buildHouseholdSummaryCard(context, household, service, isDark),
                        const SizedBox(height: AppDimensions.space16),
                        _buildMembersSection(context, service, isDark),
                        const SizedBox(height: AppDimensions.space16),
                        _buildPrivacySettingsCard(context, service, isDark),
                      ],
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildPrivacyBanner(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space12),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withAlpha(60)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: AppColors.primary, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Strict Privacy Guarantee',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Family members receive full subscription entitlements, but personal accounts, bank sync, transactions, and goals remain completely private by default.',
                  style: TextStyle(fontSize: 11, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoHouseholdView(BuildContext context, bool isFamilySub, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.navyBorder : AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.group_add_outlined, size: 40, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Active Family Household',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            isFamilySub
                ? 'You have an active Pennora Family subscription. Create your household to invite up to 5 family members.'
                : 'To create a household, upgrade to the Pennora Family Plan. Family members enjoy full Premium features under a single subscription.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          if (isFamilySub)
            ElevatedButton.icon(
              onPressed: () => _showCreateHouseholdDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Create Household'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.star_outline),
              label: const Text('View Family Plans'),
            ),
        ],
      ),
    );
  }

  Widget _buildHouseholdSummaryCard(
    BuildContext context,
    Map<String, dynamic> household,
    HouseholdService service,
    bool isDark,
  ) {
    final name = (household['name'] ?? 'Family Household').toString();
    final count = service.currentCount;
    final max = service.maxMembers;
    final isOwner = service.isOwner;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.navyBorder : AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isOwner ? 'OWNER / ADMIN' : 'MEMBER',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.people_outline, size: 16, color: AppColors.textSecondaryLight),
              const SizedBox(width: 6),
              Text(
                '$count of $max member slots used',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: max > 0 ? (count / max).clamp(0.0, 1.0) : 0.0,
              backgroundColor: isDark ? AppColors.navyBorder : const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersSection(BuildContext context, HouseholdService service, bool isDark) {
    final members = service.members;
    final isOwner = service.isOwner;
    final canInvite = isOwner && (service.currentCount < service.maxMembers);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Family Members',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (canInvite)
              TextButton.icon(
                onPressed: () => _showInviteDialog(context),
                icon: const Icon(Icons.person_add_outlined, size: 16),
                label: const Text('Invite Member', style: TextStyle(fontSize: 12)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        ...members.map((m) => _buildMemberTile(context, m, isOwner, service, isDark)),
      ],
    );
  }

  Widget _buildMemberTile(
    BuildContext context,
    HouseholdMemberModel member,
    bool isOwner,
    HouseholdService service,
    bool isDark,
  ) {
    final isMemberOwner = member.role == 'owner';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: isDark ? AppColors.darkSurface : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isDark ? AppColors.navyBorder : AppColors.cardBorder),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isMemberOwner ? AppColors.primary : AppColors.success.withAlpha(40),
          child: Icon(
            isMemberOwner ? Icons.admin_panel_settings : Icons.person,
            color: isMemberOwner ? Colors.white : AppColors.success,
            size: 20,
          ),
        ),
        title: Text(
          member.fullName,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          '${member.email.isNotEmpty ? member.email : "Member"} • ${isMemberOwner ? "Owner" : "Family Member"}',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
        trailing: isMemberOwner
            ? null
            : isOwner
                ? IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: AppColors.error, size: 20),
                    tooltip: 'Remove from household',
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Remove Member?'),
                          content: Text('Remove ${member.fullName} from this family household? They will lose family plan entitlement.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('Remove'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        await service.removeOrLeave(member.id);
                      }
                    },
                  )
                : null,
      ),
    );
  }

  Widget _buildIncomingInvitationsCard(
    BuildContext context,
    List<HouseholdInvitationModel> invitations,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: AppColors.warning.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.mail_outline, color: AppColors.warning, size: 20),
              SizedBox(width: 8),
              Text(
                'Incoming Household Invitations',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...invitations.map(
            (inv) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        inv.householdName,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      Text(
                        'Invited by ${inv.invitedBy}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => HouseholdService.instance.declineInvitation(inv.id),
                      child: const Text('Decline', style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 12)),
                    ),
                    ElevatedButton(
                      onPressed: () => HouseholdService.instance.acceptInvitation(inv.id),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                      child: const Text('Accept', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySettingsCard(BuildContext context, HouseholdService service, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.navyBorder : AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Personal Privacy Settings',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'By default, your financial data is completely hidden from family members. You may optionally share summary totals with your household.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight, height: 1.4),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Share financial totals with household', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            subtitle: const Text('Allows members to view monthly savings contributions', style: TextStyle(fontSize: 11)),
            value: false, // Default strict false
            onChanged: (val) {
              service.updateFinancialSharing(val);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(val ? 'Financial sharing enabled' : 'Financial sharing disabled (private)'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
