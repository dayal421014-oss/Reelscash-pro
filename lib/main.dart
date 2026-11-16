import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  runApp(const ReelsCashApp());
}

class ReelsCashApp extends StatelessWidget {
  const ReelsCashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ReelsCash Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0E1A),
        primaryColor: const Color(0xFF00F5A0),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00F5A0),
          secondary: Color(0xFF00D9F5),
          surface: Color(0xFF131A2E),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Color(0xFF00F5A0))),
          );
        }
        if (snapshot.hasData && snapshot.data != null) {
          return MainDashboard(user: snapshot.data!);
        }
        return const LoginScreen();
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _refCtrl = TextEditingController(text: 'DAYAL2026');
  bool _isLogin = true;
  bool _loading = false;

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    if (email.isEmpty || pass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Valid email aur kam se kam 6 digit password daalein')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      UserCredential cred;
      if (_isLogin) {
        cred = await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: pass);
      } else {
        cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: pass);
      }
      final uid = cred.user!.uid;
      final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);
      final snap = await userDoc.get();
      if (!snap.exists) {
        await userDoc.set({
          'email': email,
          'coins': 1000,
          'streak': 1,
          'lastCheckIn': '',
          'watchedToday': 0,
          'spinsToday': 0,
          'isVip': false,
          'referredBy': _refCtrl.text.trim(),
          'myRefCode': 'RC${uid.substring(0, 5).toUpperCase()}',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 36),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(colors: [Color(0xFF00F5A0), Color(0xFF00D9F5)]),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF00F5A0).withOpacity(0.35), blurRadius: 24),
                  ],
                ),
                child: const Icon(Icons.play_circle_fill, size: 54, color: Color(0xFF0A0E1A)),
              ),
              const SizedBox(height: 20),
              const Text(
                'ReelsCash Pro',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 6),
              const Text(
                'Watch Informative Shorts & Earn Rewards',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  filled: true,
                  fillColor: const Color(0xFF131A2E),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _passCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password (min 6 chars)',
                  filled: true,
                  fillColor: const Color(0xFF131A2E),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              if (!_isLogin) ...[
                const SizedBox(height: 14),
                TextField(
                  controller: _refCtrl,
                  decoration: InputDecoration(
                    labelText: 'Referral Code (Optional)',
                    filled: true,
                    fillColor: const Color(0xFF131A2E),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
              const SizedBox(height: 22),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00F5A0),
                  foregroundColor: const Color(0xFF0A0E1A),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(_isLogin ? 'Login Now' : 'Create Free Account (+1000 Coins)',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              TextButton(
                onPressed: () => setState(() => _isLogin = !_isLogin),
                child: Text(
                  _isLogin ? 'Naya account banayein? Register karein' : 'Pehle se account hai? Login karein',
                  style: const TextStyle(color: Color(0xFF00D9F5)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MainDashboard extends StatefulWidget {
  final User user;
  const MainDashboard({super.key, required this.user});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _ensureAppConfig();
  }

  Future<void> _ensureAppConfig() async {
    final cfg = FirebaseFirestore.instance.collection('app_config').doc('settings');
    final snap = await cfg.get();
    if (!snap.exists) {
      await cfg.set({
        'coinPerVideo': 500,
        'dailyVideoLimit': 10,
        'minWithdrawINR': 50,
        'vipPriceINR': 99,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdminEmail = widget.user.email?.toLowerCase() == 'dayal421014@gmail.com';
    final pages = [
      EarnTab(uid: widget.user.uid),
      ReferTab(uid: widget.user.uid),
      WalletTab(uid: widget.user.uid, email: widget.user.email ?? ''),
      SupportTab(uid: widget.user.uid, email: widget.user.email ?? ''),
      AdminTab(isDirectAdmin: isAdminEmail),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF131A2E),
        title: const Row(
          children: [
            Icon(Icons.bolt, color: Color(0xFF00F5A0)),
            SizedBox(width: 6),
            Text('ReelsCash Pro', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(widget.user.uid).snapshots(),
            builder: (context, snap) {
              final data = snap.data?.data() as Map<String, dynamic>? ?? {};
              final coins = data['coins'] ?? 0;
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00F5A0).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF00F5A0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.monetization_on, size: 16, color: Color(0xFFFFD700)),
                    const SizedBox(width: 4),
                    Text('$coins', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00F5A0))),
                  ],
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, size: 20),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: pages[_tabIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: (i) => setState(() => _tabIndex = i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF131A2E),
        selectedItemColor: const Color(0xFF00F5A0),
        unselectedItemColor: Colors.white54,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.play_circle_outline), label: 'Earn'),
          BottomNavigationBarItem(icon: Icon(Icons.group_add), label: 'Refer'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Wallet'),
          BottomNavigationBarItem(icon: Icon(Icons.support_agent), label: 'Support'),
          BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: 'Admin'),
        ],
      ),
    );
  }
}

class EarnTab extends StatefulWidget {
  final String uid;
  const EarnTab({super.key, required this.uid});

  @override
  State<EarnTab> createState() => _EarnTabState();
}

class _EarnTabState extends State<EarnTab> {
  int _watchingIndex = -1;
  int _secondsLeft = 0;
  Timer? _timer;
  bool _spinning = false;

  final List> _videos = [
    {'title': 'AI Tools Se Productivity Kaise Badhayein', 'tag': 'Tech • 15s'},
    {'title': 'Smart Personal Finance & Saving Rules', 'tag': 'Finance • 15s'},
    {'title': 'Top 5 Digital Skills in 2026', 'tag': 'Career • 15s'},
    {'title': 'Healthy Morning Routine for Focus', 'tag': 'Wellness • 15s'},
  ];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startWatch(int index, int watchedToday, int dailyLimit, int coinReward) {
    if (_watchingIndex != -1) return;
    if (watchedToday >= dailyLimit) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Aaj ki $dailyLimit videos limit poori ho gayi hai! Kal phir dekhein.')),
      );
      return;
    }
    setState(() {
      _watchingIndex = index;
      _secondsLeft = 15;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) async {
      if (_secondsLeft <= 1) {
        t.cancel();
        await FirebaseFirestore.instance.collection('users').doc(widget.uid).update({
          'coins': FieldValue.increment(coinReward),
          'watchedToday': FieldValue.increment(1),
        });
        if (mounted) {
          setState(() => _watchingIndex = -1);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Badhai ho! +$coinReward Coins aapke wallet me add ho gaye!')),
          );
        }
      } else {
        if (mounted) setState(() => _secondsLeft--);
      }
    });
  }

  Future<void> _claimDailyCheckIn(String lastCheckIn, int streak) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (lastCheckIn == today) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aaj ka Daily Bonus pehle hi claim ho chuka hai!')),
      );
      return;
    }
    final nextStreak = (streak % 7) + 1;
    final bonus = nextStreak * 200;
    await FirebaseFirestore.instance.collection('users').doc(widget.uid).update({
      'coins': FieldValue.increment(bonus),
      'streak': nextStreak,
      'lastCheckIn': today,
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Day $nextStreak Streak! +$bonus Coins mile!')),
      );
    }
  }

  Future<void> _spinWheel(int spinsToday) async {
    if (_spinning) return;
    if (spinsToday >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aaj ke 3 Lucky Spins poore ho gaye!')),
      );
      return;
    }
    setState(() => _spinning = true);
    await Future.delayed(const Duration(seconds: 1));
    final rewards = [100, 150, 200, 250, 300, 500];
    final won = rewards[Random().nextInt(rewards.length)];
    await FirebaseFirestore.instance.collection('users').doc(widget.uid).update({
      'coins': FieldValue.increment(won),
      'spinsToday': FieldValue.increment(1),
    });
    if (mounted) {
      setState(() => _spinning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lucky Spin Jeeta: +$won Coins!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('app_config').doc('settings').snapshots(),
      builder: (context, cfgSnap) {
        final cfg = cfgSnap.data?.data() as Map<String, dynamic>? ?? {};
        final coinPerVideo = cfg['coinPerVideo'] ?? 500;
        final dailyLimit = cfg['dailyVideoLimit'] ?? 10;

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(widget.uid).snapshots(),
          builder: (context, userSnap) {
            final u = userSnap.data?.data() as Map<String, dynamic>? ?? {};
            final watchedToday = u['watchedToday'] ?? 0;
            final streak = u['streak'] ?? 1;
            final lastCheckIn = u['lastCheckIn'] ?? '';
            final spinsToday = u['spinsToday'] ?? 0;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _actionCard(
                        icon: Icons.calendar_today,
                        title: 'Daily Streak (Day $streak)',
                        subtitle: 'Claim up to +1400 Coins',
                        btnText: 'Check-In',
                        onTap: () => _claimDailyCheckIn(lastCheckIn, streak),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _actionCard(
                        icon: Icons.casino,
                        title: 'Lucky Spin (${3 - spinsToday} left)',
                        subtitle: 'Win up to 500 Coins',
                        btnText: _spinning ? '...' : 'Spin Now',
                        onTap: () => _spinWheel(spinsToday),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Watch & Earn Shorts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('Today: $watchedToday / $dailyLimit', style: const TextStyle(color: Color(0xFF00F5A0))),
                  ],
                ),
                const SizedBox(height: 10),
                ...List.generate(_videos.length, (i) {
                  final v = _videos[i];
                  final isWatching = _watchingIndex == i;
                  return Card(
                    color: const Color(0xFF131A2E),
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(14),
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF00F5A0).withOpacity(0.15),
                        child: const Icon(Icons.play_arrow, color: Color(0xFF00F5A0)),
                      ),
                      title: Text(v['title']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${v['tag']} • Reward: +$coinPerVideo Coins',
                          style: const TextStyle(color: Colors.white70)),
                      trailing: ElevatedButton(
                        onPressed: () => _startWatch(i, watchedToday, dailyLimit, coinPerVideo),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isWatching ? Colors.orange : const Color(0xFF00F5A0),
                          foregroundColor: const Color(0xFF0A0E1A),
                        ),
                        child: Text(isWatching ? '${_secondsLeft}s' : 'Watch'),
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        );
      },
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String btnText,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF131A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF00D9F5)),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Colors.white60, fontSize: 11)),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D9F5),
                foregroundColor: const Color(0xFF0A0E1A),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: Text(btnText, style: const TextStyle(fontW
