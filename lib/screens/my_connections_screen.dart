// lib/screens/my_connections_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/connections_provider.dart';
import '../theme/app_colors.dart';
import 'pitch_screen.dart';

class MyConnectionsScreen extends StatefulWidget {
  const MyConnectionsScreen({super.key});

  @override
  State<MyConnectionsScreen> createState() => _MyConnectionsScreenState();
}

class _MyConnectionsScreenState extends State<MyConnectionsScreen> {
  @override
  void initState() {
    super.initState();
    Provider.of<ConnectionsProvider>(context, listen: false).fetchAcceptedConnections();
  }

  Color _parseColor(String hex) {
    final cleaned = hex.replaceAll('#', '');
    return Color(int.parse('FF$cleaned', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: Text('Connections', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      ),
      body: Consumer<ConnectionsProvider>(
        builder: (context, provider, _) {
          if (provider.isLoadingConnections && provider.acceptedConnections.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF00E676)),
            );
          }

          if (provider.acceptedConnections.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  "You haven't connected with anyone yet",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: AppColors.textMuted(context), fontSize: 16),
                ),
              ),
            );
          }

          return RefreshIndicator(
            color: const Color(0xFF00E676),
            backgroundColor: AppColors.card(context),
            onRefresh: provider.fetchAcceptedConnections,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.acceptedConnections.length,
              itemBuilder: (context, index) {
                final user = provider.acceptedConnections[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => PitchScreen(otherUser: user)),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.card(context),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: _parseColor(user.avatarColor),
                            child: Text(
                              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                              style: const TextStyle(
                                fontSize: 18,
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
                                  user.name,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color: AppColors.textPrimary(context),
                                  ),
                                ),
                                if (user.interests.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    user.interests.join(', '),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      color: AppColors.textMuted(context),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, color: AppColors.textFaint(context)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
