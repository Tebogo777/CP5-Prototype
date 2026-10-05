import 'dart:async';
import 'package:flutter/material.dart';

void main() {
  runApp(const VirtualStudentCardApp());
}

class VirtualStudentCardApp extends StatelessWidget {
  const VirtualStudentCardApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Virtual Student Card',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A73E8)),
        useMaterial3: true,
      ),
      home: const MainDashboard(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainDashboard extends StatefulWidget {
  const MainDashboard({Key? key}) : super(key: key);

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;

  // Google Pay-style Card Activation States
  bool _isCardActive = false;
  int _timeRemaining = 0;
  Timer? _activationTimer;

  // Financial & Transaction State
  double _accountBalance = 150.00;
  final List<String> _transactionHistory = ["Initial Balance Loaded: +R150.00"];

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    // Animation controller for the contactless pulsing wave effect
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _activationTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  // Simulates biometrics / screen lock unlock similar to Google Pay
  void _promptBiometricActivation() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.fingerprint, size: 64, color: Color(0xFF1A73E8)),
              const SizedBox(height: 16),
              const Text(
                "Verify Identity",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Confirm biometrics or PIN to activate tap-to-pay and campus access.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A73E8),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  _activateCard();
                },
                child: const Text("Authenticate & Activate"),
              ),
            ],
          ),
        );
      },
    );
  }

  // Activates the card for 30 seconds
  void _activateCard() {
    _activationTimer?.cancel();
    setState(() {
      _isCardActive = true;
      _timeRemaining = 30;
    });

    _activationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemaining > 1) {
        setState(() {
          _timeRemaining--;
        });
      } else {
        _deactivateCard("Card timed out for security.");
      }
    });

    _showSnackBar("Card activated! Hold phone near terminal.");
  }

  void _deactivateCard(String reason) {
    _activationTimer?.cancel();
    setState(() {
      _isCardActive = false;
      _timeRemaining = 0;
    });
    _showSnackBar(reason);
  }

  // Terminal tap handler requiring Google Pay-style active state
  void _simulateTap(String serviceName, double? cost) {
    if (!_isCardActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.lock, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Card locked. Tap 'Hold to Reader' to activate first!",
                ),
              ),
            ],
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      if (cost != null) {
        if (_accountBalance >= cost) {
          _accountBalance -= cost;
          _transactionHistory.insert(
            0,
            "$serviceName: -R${cost.toStringAsFixed(2)}",
          );
          _showTapSuccessDialog(serviceName, cost);
        } else {
          _showSnackBar("Transaction Failed: Insufficient balance.");
        }
      } else {
        _transactionHistory.insert(0, "$serviceName Access Granted");
        _showTapSuccessDialog(serviceName, null);
      }
      // Re-lock card after successful tap like Google Pay
      _deactivateCard("Card locked after successful transaction.");
    });
  }

  void _showTapSuccessDialog(String serviceName, double? cost) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 56),
        title: const Text("Terminal Accepted"),
        content: Text(
          cost != null
              ? "Payment of R${cost.toStringAsFixed(2)} confirmed at $serviceName."
              : "Access verified at $serviceName.",
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Done"),
          ),
        ],
      ),
    );
  }

  void _loadFunds(double amount) {
    setState(() {
      _accountBalance += amount;
      _transactionHistory.insert(
        0,
        "Bank Top-Up: +R${amount.toStringAsFixed(2)}",
      );
      _showSnackBar("Loaded R${amount.toStringAsFixed(2)} to account.");
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      _buildCardTab(),
      _buildWalletTab(),
      _buildEcosystemTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Virtual Student Card"),
        centerTitle: true,
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.credit_card),
            label: "Card & Tap",
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet),
            label: "Wallet",
          ),
          NavigationDestination(
            icon: Icon(Icons.hub_outlined),
            label: "Campus Services",
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: Google Pay-Style Digital Card
  // ==========================================
  Widget _buildCardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Google Pay style NFC Ready Indicator
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: _isCardActive
                  ? Colors.green.shade50
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isCardActive ? Colors.green : Colors.grey.shade300,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isCardActive
                      ? Icons.contactless
                      : Icons.contactless_outlined,
                  color: _isCardActive ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  _isCardActive
                      ? "Ready to Tap ($_timeRemaining s remaining)"
                      : "Hold near reader or tap below to activate",
                  style: TextStyle(
                    color: _isCardActive
                        ? Colors.green.shade900
                        : Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Digital Student Card with glow effect when active
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _isCardActive ? _pulseAnimation.value : 1.0,
                child: child,
              );
            },
            child: Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: _isCardActive
                      ? [const Color(0xFF1976D2), const Color(0xFF0D47A1)]
                      : [const Color(0xFF37474F), const Color(0xFF263238)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: !_isCardActive ? Colors.black26 : Colors.blue,
                    blurRadius: _isCardActive ? 20 : 8,
                    spreadRadius: _isCardActive ? 2 : 0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "CUT SMART PASS",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Icon(
                        Icons.contactless,
                        color: _isCardActive
                            ? Colors.greenAccent
                            : Colors.white54,
                        size: 28,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.person,
                          size: 36,
                          color: Colors.blueGrey,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            "TR Dithejane",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "ID: 220026101",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Status: REGISTERED",
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _isCardActive
                              ? Colors.greenAccent.shade700
                              : Colors.white24,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _isCardActive ? "ACTIVE" : "STANDBY",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Activation Trigger Button (Google Pay / Apple Pay Style)
          if (!_isCardActive)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A73E8),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _promptBiometricActivation,
              icon: const Icon(Icons.fingerprint),
              label: const Text(
                "Activate Card to Tap",
                style: TextStyle(fontSize: 16),
              ),
            )
          else
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => _deactivateCard("Card manually locked."),
              icon: const Icon(Icons.lock),
              label: const Text("Cancel / Lock Card"),
            ),

          const SizedBox(height: 30),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Simulate Campus NFC Readers",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            tileColor: Colors.grey.shade100,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            leading: const Icon(Icons.meeting_room, color: Colors.blue),
            title: const Text("Main Campus Gate Turnstile"),
            subtitle: const Text("Requires activated card tap"),
            trailing: ElevatedButton(
              onPressed: () => _simulateTap("Main Campus Gate", null),
              child: const Text("Tap"),
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            tileColor: Colors.grey.shade100,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            leading: const Icon(Icons.co_present, color: Colors.indigo),
            title: const Text("Classroom Attendance Terminal"),
            subtitle: const Text("Registers lecture presence"),
            trailing: ElevatedButton(
              onPressed: () => _simulateTap("Classroom Attendance", null),
              child: const Text("Tap"),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: Printing & Bank Balance
  // ==========================================
  Widget _buildWalletTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            color: const Color(0xFF0F9D58),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Campus Balance",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "R ${_accountBalance.toStringAsFixed(2)}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0F9D58),
                    ),
                    onPressed: () => _loadFunds(50.0),
                    icon: const Icon(Icons.add),
                    label: const Text("Bank Top-Up (+R50.00)"),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            tileColor: Colors.grey.shade100,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            leading: const Icon(Icons.print, color: Colors.teal),
            title: const Text("Library Printing Station"),
            subtitle: const Text("R5.50 per print job"),
            trailing: ElevatedButton(
              onPressed: () => _simulateTap("Library Printer", 5.50),
              child: const Text("Tap to Pay"),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Transaction History",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: _transactionHistory.length,
              itemBuilder: (ctx, i) => ListTile(
                dense: true,
                leading: const Icon(Icons.receipt_outlined),
                title: Text(_transactionHistory[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 3: Smart Campus Ecosystem Services
  // ==========================================
  Widget _buildEcosystemTab() {
    final List<Map<String, dynamic>> services = [
      {"name": "Residence Turnstile", "icon": Icons.domain, "cost": null},
      {"name": "Campus Cafeteria", "icon": Icons.fastfood, "cost": 32.50},
      {"name": "Library Checkout", "icon": Icons.local_library, "cost": null},
      {"name": "Campus Shuttle", "icon": Icons.directions_bus, "cost": 12.00},
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Tap-to-Use Services",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            "Activate card before tapping any of the campus terminals.",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: services.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) {
                final s = services[i];
                return ListTile(
                  tileColor: Colors.grey.shade50,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade50,
                    child: Icon(s["icon"] as IconData, color: Colors.blue),
                  ),
                  title: Text(s["name"] as String),
                  subtitle: Text(
                    s["cost"] != null
                        ? "Cost: R${(s["cost"] as double).toStringAsFixed(2)}"
                        : "Free Access Verification",
                  ),
                  trailing: ElevatedButton(
                    onPressed: () =>
                        _simulateTap(s["name"] as String, s["cost"] as double?),
                    child: const Text("Tap Terminal"),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
