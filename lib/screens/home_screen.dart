// lib/screens/home_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/connections_provider.dart';
import '../providers/users_provider.dart';
import '../services/auth_service.dart';
import '../services/socket_service.dart';
import '../theme/app_colors.dart';
import '../widgets/user_card.dart';
import 'dashboard_screen.dart';
import 'my_connections_screen.dart';
import 'profile_screen.dart';
import 'requests_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final SocketService _socketService = SocketService();

  Position? _currentPosition;
  bool _isLocating = true;
  String _locationLabel = 'Locating...';
  bool _liveUpdatesStarted = false;

  StreamSubscription<Position>? _positionSubscription;
  Timer? _refreshTimer;
  DateTime? _lastLocationPushAt;

  @override
  void initState() {
    super.initState();
    _initHome();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _refreshTimer?.cancel();
    _socketService.disconnect();
    super.dispose();
  }

  Future<void> _initHome() async {
    await _connectSocket();
    if (mounted) {
      Provider.of<ConnectionsProvider>(context, listen: false).fetchIncomingRequests();
    }
    await _fetchLocationAndUsers();
  }

  Future<void> _connectSocket() async {
    final userId = await _authService.getUserId();
    if (userId == null) return;

    _socketService.connect(userId);
    _socketService.listenForConnectionAccepted((data) {
      if (!mounted) return;
      final name = data is Map ? (data['receiverName'] ?? 'Someone') : 'Someone';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$name accepted your connection request!')),
      );
    });
    _socketService.listenForConnectionRequests((data) {
      if (!mounted) return;
      Provider.of<ConnectionsProvider>(context, listen: false)
          .addIncomingRequestFromSocket(data);
      final name = data is Map ? (data['senderName'] ?? 'Someone') : 'Someone';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$name wants to connect with you!')),
      );
    });
  }

  Future<void> _fetchLocationAndUsers() async {
    setState(() {
      _isLocating = true;
      _locationLabel = 'Locating...';
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLocating = false;
          _locationLabel = 'Location disabled';
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _isLocating = false;
          _locationLabel = 'Location permission denied';
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _currentPosition = position;

      if (!mounted) return;

      setState(() {
        _isLocating = false;
        _locationLabel =
            '${position.latitude.toStringAsFixed(2)}, ${position.longitude.toStringAsFixed(2)}';
      });

      final usersProvider = Provider.of<UsersProvider>(context, listen: false);
      await usersProvider.fetchNearbyUsers(position.latitude, position.longitude);

      if (!_liveUpdatesStarted) {
        _liveUpdatesStarted = true;
        _startLiveLocationUpdates();
        _startPeriodicRefresh();
      }
    } catch (e) {
      setState(() {
        _isLocating = false;
        _locationLabel = 'Unable to get location';
      });
    }
  }

  void _startLiveLocationUpdates() {
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((position) {
      if (!mounted) return;
      _currentPosition = position;
      setState(() {
        _locationLabel =
            '${position.latitude.toStringAsFixed(2)}, ${position.longitude.toStringAsFixed(2)} • Live';
      });

      final now = DateTime.now();
      if (_lastLocationPushAt == null ||
          now.difference(_lastLocationPushAt!) > const Duration(seconds: 8)) {
        _lastLocationPushAt = now;
        Provider.of<UsersProvider>(context, listen: false)
            .pushLocation(position.latitude, position.longitude);
      }
    });
  }

  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (_currentPosition == null || !mounted) return;
      Provider.of<UsersProvider>(context, listen: false).fetchNearbyUsers(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
    });
  }

  Future<void> _handleRefresh() async {
    if (_currentPosition == null) {
      await _fetchLocationAndUsers();
      return;
    }
    final usersProvider = Provider.of<UsersProvider>(context, listen: false);
    await usersProvider.fetchNearbyUsers(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final usersProvider = Provider.of<UsersProvider>(context);
    final connectionsProvider = Provider.of<ConnectionsProvider>(context);
    final selectedInterests = authProvider.currentUser?.interests ?? [];

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: Text(
          'Circl',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF00E676),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Color(0xFF00E676), size: 18),
                const SizedBox(width: 4),
                Text(
                  _locationLabel,
                  style: TextStyle(color: AppColors.textSecondary(context), fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.people_outline),
            tooltip: 'Connections',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MyConnectionsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.dashboard_outlined),
            tooltip: 'Dashboard',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DashboardScreen()),
              );
            },
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.mail_outline),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RequestsScreen()),
                  );
                },
              ),
              if (connectionsProvider.pendingCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '${connectionsProvider.pendingCount}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF00E676),
        backgroundColor: AppColors.card(context),
        onRefresh: _handleRefresh,
        child: _buildBody(usersProvider, selectedInterests),
      ),
    );
  }

  Widget _buildBody(UsersProvider usersProvider, List<String> selectedInterests) {
    if (_isLocating || usersProvider.isLoading) {
      return ListView(
        children: const [
          SizedBox(height: 200),
          Center(
            child: CircularProgressIndicator(color: Color(0xFF00E676)),
          ),
        ],
      );
    }

    if (usersProvider.nearbyUsers.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 200),
          Center(
            child: Text(
              'No one nearby',
              style: GoogleFonts.poppins(color: AppColors.textMuted(context), fontSize: 16),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: usersProvider.nearbyUsers.length,
      itemBuilder: (context, index) {
        final user = usersProvider.nearbyUsers[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: UserCard(
            user: user,
            selectedInterests: selectedInterests,
          ),
        );
      },
    );
  }
}
