// lib/screens/pitch_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/user_model.dart';
import '../providers/pitch_provider.dart';
import '../services/auth_service.dart';
import '../services/socket_service.dart';
import '../theme/app_colors.dart';

class PitchScreen extends StatefulWidget {
  final UserModel otherUser;

  const PitchScreen({super.key, required this.otherUser});

  @override
  State<PitchScreen> createState() => _PitchScreenState();
}

class _PitchScreenState extends State<PitchScreen> {
  final AuthService _authService = AuthService();
  final SocketService _socketService = SocketService();
  final TextEditingController _pitchController = TextEditingController();
  final TextEditingController _meetLinkController = TextEditingController();

  bool _isSending = false;
  bool _isSharingLink = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final provider = Provider.of<PitchProvider>(context, listen: false);
    provider.reset();
    await provider.fetchPitchWith(widget.otherUser.id);

    final userId = await _authService.getUserId();
    if (userId == null || !mounted) return;

    _socketService.connect(userId);
    _socketService.listenForPitchReceived(provider.handlePitchReceived);
    _socketService.listenForPitchResponded(provider.handlePitchResponded);
    _socketService.listenForPitchMatched(provider.handlePitchMatched);
    _socketService.listenForMeetLinkShared(provider.handleMeetLinkShared);
  }

  @override
  void dispose() {
    _socketService.disconnect();
    _pitchController.dispose();
    _meetLinkController.dispose();
    super.dispose();
  }

  Future<void> _handleSendPitch() async {
    final text = _pitchController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);
    final provider = Provider.of<PitchProvider>(context, listen: false);
    final success = await provider.sendPitch(widget.otherUser.id, text);
    if (!mounted) return;
    setState(() => _isSending = false);

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.errorMessage ?? 'Could not send pitch')),
      );
    }
  }

  Future<void> _handleRespond(String pitchId, String status) async {
    final provider = Provider.of<PitchProvider>(context, listen: false);
    await provider.respondToPitch(pitchId, status);
  }

  Future<void> _openMeetNew() async {
    final uri = Uri.parse('https://meet.google.com/new');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _handleShareLink() async {
    final link = _meetLinkController.text.trim();
    if (link.isEmpty) return;

    setState(() => _isSharingLink = true);
    final provider = Provider.of<PitchProvider>(context, listen: false);
    final success = await provider.shareMeetLink(widget.otherUser.id, link);
    if (!mounted) return;
    setState(() => _isSharingLink = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Meeting link shared with ${widget.otherUser.name}')),
      );
    }
  }

  Future<void> _handleJoinMeeting(String link) async {
    final uri = Uri.parse(link);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'accepted':
        return const Color(0xFF00E676);
      case 'rejected':
        return Colors.redAccent;
      default:
        return Colors.amberAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: Text(
          'Pitch to ${widget.otherUser.name}',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),
      body: Consumer<PitchProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF00E676)),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.otherUser.name}\'s pitch',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(context),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                _buildTheirPitchCard(provider),
                const SizedBox(height: 24),
                Text(
                  'Your pitch',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(context),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                _buildMyPitchCard(provider),
                if (provider.bothAccepted) ...[
                  const SizedBox(height: 32),
                  _buildMeetSection(provider),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTheirPitchCard(PitchProvider provider) {
    final pitch = provider.theirPitch;

    if (pitch == null) {
      return _card(
        child: Text(
          'No pitch received yet',
          style: GoogleFonts.poppins(color: AppColors.textMuted(context)),
        ),
      );
    }

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(pitch.text, style: GoogleFonts.poppins(color: AppColors.textPrimary(context), fontSize: 14)),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(pitch.status).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _statusColor(pitch.status)),
                ),
                child: Text(
                  pitch.status,
                  style: TextStyle(color: _statusColor(pitch.status), fontSize: 12),
                ),
              ),
              const Spacer(),
              if (pitch.status == 'pending') ...[
                TextButton(
                  onPressed: () => _handleRespond(pitch.id, 'rejected'),
                  child: const Text('Reject', style: TextStyle(color: Colors.redAccent)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _handleRespond(pitch.id, 'accepted'),
                  child: const Text('Accept'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMyPitchCard(PitchProvider provider) {
    final pitch = provider.myPitch;

    if (pitch == null) {
      return _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _pitchController,
              maxLines: 4,
              style: TextStyle(color: AppColors.textPrimary(context)),
              decoration: const InputDecoration(
                hintText: 'Describe the project you want to build or learn together...',
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSending ? null : _handleSendPitch,
                child: _isSending
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : const Text('Send Pitch'),
              ),
            ),
          ],
        ),
      );
    }

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(pitch.text, style: GoogleFonts.poppins(color: AppColors.textPrimary(context), fontSize: 14)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColor(pitch.status).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _statusColor(pitch.status)),
            ),
            child: Text(
              pitch.status,
              style: TextStyle(color: _statusColor(pitch.status), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeetSection(PitchProvider provider) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🎉 Pitch matched! Start a meeting',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF00E676),
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Create a Google Meet, then paste the link below to share it.',
            style: GoogleFonts.poppins(color: AppColors.textMuted(context), fontSize: 13),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _openMeetNew,
              child: const Text('Create Google Meet →'),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _meetLinkController,
            style: TextStyle(color: AppColors.textPrimary(context)),
            decoration: const InputDecoration(hintText: 'Paste meet.google.com/... link'),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSharingLink ? null : _handleShareLink,
              child: _isSharingLink
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                    )
                  : Text('Share Link with ${widget.otherUser.name}'),
            ),
          ),
          if (provider.meetLink != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _handleJoinMeeting(provider.meetLink!),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676)),
                child: const Text('Join Meeting →'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}
