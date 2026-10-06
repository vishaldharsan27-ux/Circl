// lib/widgets/user_card.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/users_provider.dart';
import '../screens/pitch_screen.dart';
import '../theme/app_colors.dart';
import 'connect_bottom_sheet.dart';

class UserCard extends StatefulWidget {
  final UserModel user;
  final List<String> selectedInterests;

  const UserCard({
    super.key,
    required this.user,
    required this.selectedInterests,
  });

  @override
  State<UserCard> createState() => _UserCardState();
}

class _UserCardState extends State<UserCard> {
  bool _isConnecting = false;
  String? _optimisticStatus;

  String get _effectiveStatus => _optimisticStatus ?? widget.user.connectionStatus;

  Color _parseColor(String hex) {
    final cleaned = hex.replaceAll('#', '');
    return Color(int.parse('FF$cleaned', radix: 16));
  }

  Future<void> _handleConnect() async {
    setState(() => _isConnecting = true);

    final usersProvider = Provider.of<UsersProvider>(context, listen: false);
    final success = await usersProvider.sendConnection(widget.user.id);

    if (!mounted) return;

    setState(() {
      _isConnecting = false;
      if (success) _optimisticStatus = 'pending';
    });

    if (success) {
      showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.card(context),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => ConnectBottomSheet(name: widget.user.name),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not send connection request')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: _parseColor(widget.user.avatarColor),
                child: Text(
                  widget.user.name.isNotEmpty
                      ? widget.user.name[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.user.name}, ${widget.user.age}',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.user.distanceKm} km away',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF00E676),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Match: ${widget.user.matchPercent}%',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF00E676),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          if (widget.user.preference != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.user.preferenceMatch
                        ? const Color(0xFF00E676).withValues(alpha: 0.15)
                        : AppColors.subtleFill(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: widget.user.preferenceMatch
                          ? const Color(0xFF00E676)
                          : AppColors.divider(context),
                    ),
                  ),
                  child: Text(
                    'Looking to ${widget.user.preference}',
                    style: TextStyle(
                      fontSize: 11,
                      color: widget.user.preferenceMatch
                          ? const Color(0xFF00E676)
                          : AppColors.textMuted(context),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (widget.user.bio.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              widget.user.bio,
              style: GoogleFonts.poppins(color: AppColors.textMuted(context), fontSize: 13),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.user.interests.map((interest) {
              final isShared = widget.selectedInterests.contains(interest);
              final isRelated =
                  !isShared && widget.user.relatedInterests.contains(interest);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isShared
                      ? const Color(0xFF00E676)
                      : AppColors.subtleFill(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isShared
                        ? const Color(0xFF00E676)
                        : isRelated
                            ? Colors.amberAccent
                            : AppColors.divider(context),
                  ),
                ),
                child: Text(
                  interest,
                  style: TextStyle(
                    fontSize: 12,
                    color: isShared
                        ? Colors.black
                        : isRelated
                            ? Colors.amberAccent
                            : AppColors.textSecondary(context),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: _buildActionButton(),
          ),
        ],
      ),
    );
  }

  void _openPitchScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PitchScreen(otherUser: widget.user)),
    );
  }

  Widget _buildActionButton() {
    if (_effectiveStatus == 'accepted') {
      return OutlinedButton(
        onPressed: _openPitchScreen,
        child: const Text('Connected ✓ · Pitch Project →'),
      );
    }

    if (_effectiveStatus == 'pending') {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
        ),
        child: Text(
          'Request Pending',
          style: GoogleFonts.poppins(color: Colors.white54, fontWeight: FontWeight.w600),
        ),
      );
    }

    return OutlinedButton(
      onPressed: _isConnecting ? null : _handleConnect,
      child: _isConnecting
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF00E676),
              ),
            )
          : const Text('Connect →'),
    );
  }
}
