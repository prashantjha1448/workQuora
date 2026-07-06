import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/jobs_provider.dart';
import '../../core/utils/time_utils.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class JobDetailScreen extends StatefulWidget {
  final String jobId;
  const JobDetailScreen({super.key, required this.jobId});
  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  final _bidCtrl = TextEditingController();
  final _daysCtrl = TextEditingController();
  final _coverCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<JobsProvider>().fetchJobById(widget.jobId));
  }

  @override
  void dispose() {
    _bidCtrl.dispose();
    _daysCtrl.dispose();
    _coverCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final bid = num.tryParse(_bidCtrl.text.trim());
    final days = int.tryParse(_daysCtrl.text.trim());
    final cover = _coverCtrl.text.trim();

    if (bid == null || bid <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Enter a valid bid amount'), backgroundColor: AppColors.error));
      return;
    }
    if (days == null || days <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Enter valid estimated days'), backgroundColor: AppColors.error));
      return;
    }
    if (cover.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Add a short cover letter'), backgroundColor: AppColors.error));
      return;
    }

    final provider = context.read<JobsProvider>();
    final ok = await provider.submitProposal(jobId: widget.jobId, bidAmount: bid, estimatedDays: days, coverLetter: cover);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Proposal submitted!'), backgroundColor: AppColors.success));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.error ?? 'Could not submit proposal'), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final jobsProvider = context.watch<JobsProvider>();
    final job = jobsProvider.selectedJob;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Job Details'), backgroundColor: AppColors.background, elevation: 0),
      body: jobsProvider.isLoadingJob
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : job == null
              ? Center(child: Text('Job not found', style: TextStyle(color: AppColors.textSecondary)))
              : _buildBody(context, job),
    );
  }

  Widget _buildBody(BuildContext context, Map<String, dynamic> job) {
    final title = job['title'] ?? 'Job';
    final desc = job['description'] ?? '';
    final cat = job['category'] ?? '';
    final budgetMin = job['budgetRange']?['min'] ?? job['budget'] ?? 0;
    final budgetMax = job['budgetRange']?['max'];
    final status = job['status'] ?? 'open';
    final posted = timeAgo(job['createdAt']?.toString());
    final clientName = job['clientInfo']?['name'] ?? 'Client';
    final skills = List<String>.from(job['skillsRequired'] ?? []);
    final location = job['location']?['address'] ?? job['location']?['city'] ?? '';

    final jobsProvider = context.watch<JobsProvider>();
    final alreadyProposed = jobsProvider.hasProposedTo(widget.jobId);
    final proposal = jobsProvider.proposalFor(widget.jobId);
    final isOpen = status == 'open';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Text('$cat', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: (isOpen ? AppColors.success : AppColors.textSecondary).withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
            child: Text(status.toString().toUpperCase(), style: TextStyle(color: isOpen ? AppColors.success : AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ]),
        const SizedBox(height: 14),
        Text(title, style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        Text('Posted by $clientName${posted.isNotEmpty ? ' • $posted' : ''}', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
          child: Row(children: [
            Icon(Icons.currency_rupee, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(budgetMax != null ? '₹$budgetMin - ₹$budgetMax' : '₹$budgetMin', style: TextStyle(color: AppColors.primary, fontSize: 18, fontWeight: FontWeight.w900)),
            const Spacer(),
            if (location.toString().isNotEmpty) ...[
              Icon(Icons.location_on_outlined, color: AppColors.textSecondary, size: 16),
              const SizedBox(width: 4),
              Flexible(child: Text('$location', style: TextStyle(color: AppColors.textSecondary, fontSize: 12), overflow: TextOverflow.ellipsis)),
            ],
          ]),
        ),
        const SizedBox(height: 20),
        Text('Description', style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(desc, style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5)),
        if (skills.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text('Skills Required', style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: skills
                .map((s) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.primary.withOpacity(0.3))),
                      child: Text(s, style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                    ))
                .toList(),
          ),
        ],
        const SizedBox(height: 28),
        if (!isOpen)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
            child: Row(children: [
              Icon(Icons.lock_outline, color: AppColors.textSecondary),
              const SizedBox(width: 10),
              Expanded(child: Text('This job is no longer accepting proposals', style: TextStyle(color: AppColors.textSecondary, fontSize: 13))),
            ]),
          )
        else if (alreadyProposed)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.primary.withOpacity(0.3))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.check_circle, color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Text('You already applied to this job', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
              ]),
              if (proposal != null) ...[
                const SizedBox(height: 10),
                Text('Your bid: ₹${proposal['bidAmount'] ?? '-'} • ${proposal['estimatedDays'] ?? '-'} days', style: TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                if ((proposal['coverLetter'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(proposal['coverLetter'].toString(), style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ],
            ]),
          )
        else
          _proposalForm(context),
        const SizedBox(height: 20),
      ]),
    );
  }

  Widget _proposalForm(BuildContext context) {
    final jobsProvider = context.watch<JobsProvider>();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Submit a Proposal', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      AppTextField(controller: _bidCtrl, hint: 'Your bid amount (₹)', icon: Icons.currency_rupee, keyboardType: TextInputType.number),
      const SizedBox(height: 12),
      AppTextField(controller: _daysCtrl, hint: 'Estimated days to complete', icon: Icons.calendar_today_outlined, keyboardType: TextInputType.number),
      const SizedBox(height: 12),
      AppTextField(controller: _coverCtrl, hint: 'Why are you a good fit for this job?', icon: Icons.edit_note, maxLines: 4),
      const SizedBox(height: 16),
      AppButton(label: 'Submit Proposal', loading: jobsProvider.isSubmittingProposal, onPressed: _submit),
    ]);
  }
}
