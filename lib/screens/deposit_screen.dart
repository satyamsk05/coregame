import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/sound_manager.dart';
import '../shared/widgets/bounceable.dart';

class DepositScreen extends StatefulWidget {
  final double balance;
  final double totalDeposited;
  final int vipLevel;
  final String activeGateway;
  final ValueChanged<double> onBalanceChanged;
  final ValueChanged<double> onTotalDepositedChanged;
  final ValueChanged<int> onVipLevelChanged;
  final ValueChanged<String> onActiveGatewayChanged;
  final VoidCallback onBackPressed;

  const DepositScreen({
    super.key,
    required this.balance,
    required this.totalDeposited,
    required this.vipLevel,
    required this.activeGateway,
    required this.onBalanceChanged,
    required this.onTotalDepositedChanged,
    required this.onVipLevelChanged,
    required this.onActiveGatewayChanged,
    required this.onBackPressed,
  });

  @override
  State<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends State<DepositScreen> {
  late final TextEditingController _depositController;
  final _formKey = GlobalKey<FormState>();
  late String _localActiveGateway;

  final List<Map<String, dynamic>> _packages = [
    {'label': '100', 'price': 100, 'extra': ''},
    {'label': '200', 'price': 200, 'extra': ''},
    {'label': '300', 'price': 300, 'extra': ''},
    {'label': '510', 'price': 500, 'extra': 'Extra +2%'},
    {'label': '1020', 'price': 1000, 'extra': 'Extra +2%'},
    {'label': '2040', 'price': 2000, 'extra': 'Extra +2%'},
    {'label': '5150', 'price': 5000, 'extra': 'Extra +3%'},
    {'label': '8240', 'price': 8000, 'extra': 'Extra +3%'},
    {'label': '10300', 'price': 10000, 'extra': 'Extra +3%'},
  ];

  @override
  void initState() {
    super.initState();
    _depositController = TextEditingController(text: '100');
    _localActiveGateway = widget.activeGateway.isEmpty ? 'UmPay' : widget.activeGateway;
  }

  @override
  void dispose() {
    _depositController.dispose();
    super.dispose();
  }

  void _executeDeposit(double amount) {
    widget.onBalanceChanged(widget.balance + amount);
    _checkVipUpgrade(amount);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF00C853),
        content: Text(
          'Recharged ₹${amount.toStringAsFixed(2)} Successfully!',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  void _checkVipUpgrade(double addedDeposit) {
    double newDeposited = widget.totalDeposited + addedDeposit;
    widget.onTotalDepositedChanged(newDeposited);
    int oldLevel = widget.vipLevel;
    int newLevel = oldLevel;
    
    if (newDeposited >= 500.0) {
      newLevel = 8;
    } else if (newDeposited >= 200.0) {
      newLevel = 7;
    } else if (newDeposited >= 100.0) {
      newLevel = 2;
    } else {
      newLevel = 1;
    }

    if (newLevel > oldLevel) {
      widget.onVipLevelChanged(newLevel);
      _showVipLevelUpDialog(oldLevel, newLevel);
    }
  }

  void _showVipLevelUpDialog(int oldLevel, int newLevel) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 320.0,
          height: 200.0,
          decoration: BoxDecoration(
            color: const Color(0xFF1E2024),
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: const Color(0xFF2E3135), width: 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.stars, color: Color(0xFFFFD700), size: 48.0),
              const SizedBox(height: 10.0),
              Text(
                'CONGRATULATIONS!',
                style: GoogleFonts.alfaSlabOne(fontSize: 14.0, color: const Color(0xFF00C853)),
              ),
              const SizedBox(height: 6.0),
              Text(
                'YOU UPGRADED TO VIP $newLevel!',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11.0),
              ),
              const SizedBox(height: 12.0),
              Bounceable(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E3135),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: const Text('OK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final int crossAxisCount = screenWidth < 680 ? 4 : 5;
    final double childAspectRatio = screenWidth < 680 ? 1.25 : 1.12;

    return Scaffold(
      backgroundColor: const Color(0xFF161618),
      body: SafeArea(
        child: Column(
          children: [
            // Header Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              decoration: const BoxDecoration(
                color: Color(0xFF1E2024),
                border: Border(
                  bottom: BorderSide(color: Color(0xFF2E3135), width: 1.5),
                ),
              ),
              child: Row(
                children: [
                  Bounceable(
                    onTap: widget.onBackPressed,
                    child: Container(
                      width: 32.0,
                      height: 32.0,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E3135),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF3E4347)),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 16.0),
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Text(
                    'SHOP / DEPOSIT',
                    style: GoogleFonts.pressStart2p(
                      textStyle: const TextStyle(
                        fontSize: 12.0,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Balance indicator capsule matching top bar
                  Container(
                    height: 34.0,
                    decoration: BoxDecoration(
                      color: const Color(0xFF161618),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: const Color(0xFF2E3135), width: 1.2),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Row(
                      children: [
                        Image.asset('assets/coin.png', width: 16.0, height: 16.0),
                        const SizedBox(width: 8.0),
                        Text(
                          '₹${widget.balance.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Body Content Area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Left Sidebar (Gateways)
                    Container(
                      width: 140.0,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E2024),
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(color: const Color(0xFF2E3135), width: 1.0),
                      ),
                      padding: const EdgeInsets.all(12.0),
                      child: SingleChildScrollView(
                        child: Column(
                          children: ['UmPay', 'wddpay', 'CloudsPay', 'ZipPay'].map((gateway) {
                            final bool isActive = _localActiveGateway == gateway;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: isActive
                                  ? Container(
                                      height: 44.0,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF161618),
                                        borderRadius: BorderRadius.circular(8.0),
                                        border: Border.all(color: const Color(0xFF2E3135), width: 1.0),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 3.0,
                                            height: 16.0,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF24EE89),
                                              borderRadius: BorderRadius.circular(1.5),
                                            ),
                                          ),
                                          const SizedBox(width: 8.0),
                                          const Icon(Icons.payment, color: Color(0xFF24EE89), size: 16.0),
                                          const SizedBox(width: 8.0),
                                          Expanded(
                                            child: Text(
                                              gateway,
                                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.0),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : Bounceable(
                                      onTap: () {
                                        setState(() {
                                          _localActiveGateway = gateway;
                                        });
                                        widget.onActiveGatewayChanged(gateway);
                                      },
                                      child: Container(
                                        height: 44.0,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: Colors.transparent,
                                          borderRadius: BorderRadius.circular(8.0),
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                        child: Row(
                                          children: [
                                            const SizedBox(width: 11.0),
                                            const Icon(Icons.payment, color: Colors.white38, size: 16.0),
                                            const SizedBox(width: 8.0),
                                            Expanded(
                                              child: Text(
                                                gateway,
                                                style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 12.0),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16.0),
                    
                    // Right Content Panel
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E2024),
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(color: const Color(0xFF2E3135), width: 1.0),
                        ),
                        padding: const EdgeInsets.all(16.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Top Warning Label
                              Text(
                                'If you cannot recharge, choose another channel or try again.',
                                style: GoogleFonts.montserrat(
                                  textStyle: const TextStyle(color: Color(0xFFFFD54F), fontSize: 10.0, fontWeight: FontWeight.bold, letterSpacing: 0.2),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12.0),
                              
                              // Input field + formula indicator + recharge button
                              Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Container(
                                      height: 38.0,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF161618),
                                        borderRadius: BorderRadius.circular(6.0),
                                        border: Border.all(color: const Color(0xFF2E3135), width: 1.2),
                                      ),
                                      child: TextFormField(
                                        controller: _depositController,
                                        keyboardType: TextInputType.number,
                                        style: const TextStyle(color: Colors.white, fontSize: 13.0, fontWeight: FontWeight.bold),
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          hintText: 'Enter amount...',
                                          hintStyle: TextStyle(color: Colors.white24, fontSize: 12.0),
                                          contentPadding: EdgeInsets.only(left: 10.0, right: 10.0, bottom: 10.0),
                                        ),
                                        onChanged: (val) {
                                          setState(() {});
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8.0),
                                  // Formula Indicator
                                  Container(
                                    height: 38.0,
                                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF161618),
                                      borderRadius: BorderRadius.circular(6.0),
                                      border: Border.all(color: const Color(0xFF2E3135), width: 1.0),
                                    ),
                                    alignment: Alignment.center,
                                    child: Row(
                                      children: [
                                        Image.asset('assets/coin.png', width: 16.0, height: 16.0),
                                        const SizedBox(width: 6.0),
                                        Text(
                                          '${_depositController.text.isEmpty ? "0" : _depositController.text} = ₹${_depositController.text.isEmpty ? "0" : _depositController.text}',
                                          style: const TextStyle(color: Colors.white, fontSize: 12.0, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8.0),
                                  // Recharge Button
                                  Bounceable(
                                    onTap: () {
                                      if (_formKey.currentState!.validate()) {
                                        final amount = double.tryParse(_depositController.text) ?? 100;
                                        _executeDeposit(amount);
                                      }
                                    },
                                    child: Container(
                                      height: 38.0,
                                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF24EE89), Color(0xFF00C853)],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
                                        borderRadius: BorderRadius.circular(6.0),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF24EE89).withOpacity(0.2),
                                            blurRadius: 8.0,
                                            offset: const Offset(0, 2),
                                          )
                                        ]
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        'RECHARGE',
                                        style: GoogleFonts.montserrat(
                                          textStyle: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12.0,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16.0),
                              
                              // Packages Grid
                              Expanded(
                                child: GridView.builder(
                                  itemCount: _packages.length,
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    crossAxisSpacing: 10.0,
                                    mainAxisSpacing: 10.0,
                                    childAspectRatio: childAspectRatio,
                                  ),
                                  itemBuilder: (context, index) {
                                    final pack = _packages[index];
                                    return Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF161618),
                                        borderRadius: BorderRadius.circular(10.0),
                                        border: Border.all(color: const Color(0xFF2E3135), width: 1.2),
                                      ),
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          Column(
                                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                            children: [
                                              // Label coins
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFF2E3135),
                                                  borderRadius: BorderRadius.vertical(top: Radius.circular(8.0)),
                                                ),
                                                child: Text(
                                                  '${pack['label']} Coins',
                                                  style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 9.5, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                              // Coin Image
                                              Image.asset(
                                                'assets/coin.png',
                                                width: 24.0,
                                                height: 24.0,
                                              ),
                                              // Buy Button
                                              Bounceable(
                                                onTap: () {
                                                  setState(() {
                                                    _depositController.text = pack['price'].toString();
                                                  });
                                                  _executeDeposit(pack['price'].toDouble());
                                                },
                                                child: Container(
                                                  width: double.infinity,
                                                  margin: const EdgeInsets.symmetric(horizontal: 10.0),
                                                  height: 26.0,
                                                  decoration: BoxDecoration(
                                                    gradient: const LinearGradient(
                                                      colors: [Color(0xFFFE9E22), Color(0xFFD87C04)],
                                                      begin: Alignment.topCenter,
                                                      end: Alignment.bottomCenter,
                                                    ),
                                                    borderRadius: BorderRadius.circular(20.0),
                                                  ),
                                                  alignment: Alignment.center,
                                                  child: Text(
                                                    '₹${pack['price']}',
                                                    style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w900),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (pack['extra'].isNotEmpty)
                                            Positioned(
                                              top: -6,
                                              left: -6,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFFF3356),
                                                  borderRadius: BorderRadius.circular(4.0),
                                                ),
                                                child: Text(
                                                  pack['extra'],
                                                  style: const TextStyle(color: Colors.white, fontSize: 7.0, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
