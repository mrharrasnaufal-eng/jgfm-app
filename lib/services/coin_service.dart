import 'package:flutter/material.dart';

import '../models/coin_transaction.dart';

/// Placeholder coin service. All earn/spend actions show "Segera Hadir".
/// Will be replaced with real backend integration in Fase 5.
class CoinService extends ChangeNotifier {
  int _balance = 0;
  final List<CoinTransaction> _transactions = [];
  bool _dailyLoginClaimed = false;

  int get balance => _balance;
  List<CoinTransaction> get transactions => List.unmodifiable(_transactions);
  bool get dailyLoginClaimed => _dailyLoginClaimed;

  /// Whether the coin system is active (connected to backend).
  /// Always false for now — UI shows "Segera Hadir" for all actions.
  bool get isActive => false;

  /// Placeholder: earn coins from watching ad.
  /// Returns false because system is not active yet.
  bool earnFromAd() => false;

  /// Placeholder: earn coins from daily login.
  bool claimDailyLogin() => false;

  /// Placeholder: earn coins from mission.
  bool earnFromMission(String missionId) => false;

  /// Placeholder: spend coins.
  bool spend(int amount, String description) => false;

  /// Get total earned coins.
  int get totalEarned => _transactions
      .where((t) => t.isEarning)
      .fold(0, (sum, t) => sum + t.amount);
}
