// lib/screens/requests_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/incoming_request_model.dart';
import '../providers/connections_provider.dart';
import '../theme/app_colors.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  final Set<String> _respondingTo = {};

  @override
  void initState() {
    super.initState();
    Provider.of<ConnectionsProvider>(context, listen: false).fetchIncomingRequests();
  }

  Color _parseColor(String hex) {
    final cleaned = hex.replaceAll('#', '');
    return Color(int.parse('FF$cleaned', radix: 16));
  }

  Future<void> _handleRespond(String connectionId, String status, String senderName) async {
    setState(() => _respondingTo.add(connectionId));

    final connectionsProvider = Provider.of<ConnectionsProvider>(context, listen: false);
    final success = await connectionsProvider.respond(connectionId, status);

    if (!mounted) return;

    setState(() => _respondingTo.remove(connectionId));

    if (success) {
      if (status == 'accepted') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("You're connected with $senderName!")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not respond to request')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final connectionsProvider = Provider.of<ConnectionsProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: Text('Requests', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        color: const Color(0xFF00E676),
        backgroundColor: AppColors.card(context),
        onRefresh: connectionsProvider.fetchIncomingRequests,
        child: _buildBody(connectionsProvider),
      ),
    );
  }

  Widget _buildBody(ConnectionsProvider connectionsProvider) {
    if (connectionsProvider.isLoading) {
      return ListView(
        children: const [
          SizedBox(height: 200),
          Center(child: CircularProgressIndicator(color: Color(0xFF00E676))),
        ],
      );
    }

    if (connectionsProvider.incomingRequests.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 200),
          Center(
            child: Text(
              'No pending requests',
              style: GoogleFonts.poppins(color: AppColors.textMuted(context), fontSize: 16),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: connectionsProvider.incomingRequests.length,
      itemBuilder: (context, index) {
        final request = connectionsProvider.incomingRequests[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildRequestCard(request),
        );
      },
    );
  }

  Widget _buildRequestCard(IncomingRequestModel request) {
    final isResponding = _respondingTo.contains(request.connectionId);

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
                backgroundColor: _parseColor(request.avatarColor),
                child: Text(
                  request.senderName.isNotEmpty ? request.senderName[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  request.age > 0 ? '${request.senderName}, ${request.age}' : request.senderName,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.textPrimary(context),
                  ),
                ),
              ),
            ],
          ),
          if (request.bio.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              request.bio,
              style: GoogleFonts.poppins(color: AppColors.textMuted(context), fontSize: 13),
            ),
          ],
          if (request.interests.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: request.interests.map((interest) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.subtleFill(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider(context)),
                  ),
                  child: Text(
                    interest,
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary(context)),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isResponding
                      ? null
                      : () => _handleRespond(request.connectionId, 'rejected', request.senderName),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                  ),
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: isResponding
                      ? null
                      : () => _handleRespond(request.connectionId, 'accepted', request.senderName),
                  child: isResponding
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : const Text('Accept'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
