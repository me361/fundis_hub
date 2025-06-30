import 'package:flutter/material.dart';

class PaymentScreen extends StatelessWidget {
  final String fundiName;
  final int totalAmount;

  const PaymentScreen({
    super.key,
    required this.fundiName,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('M-Pesa Payment'),
        backgroundColor: Colors.green[700],
      ),
      body: Center(
        child: Card(
          elevation: 4,
          margin: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.payment, size: 60, color: Colors.green[700]),
                const SizedBox(height: 20),
                Text(
                  'Pay to $fundiName',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                Text(
                  'Total: KES $totalAmount',
                  style: const TextStyle(fontSize: 18, color: Colors.black87),
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  icon: const Icon(Icons.send),
                  label: const Text('Pay with M-Pesa'),
                  onPressed: () {
                    // You can trigger a payment flow or show success here
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Payment Initiated'),
                        content: const Text('A payment request has been sent via M-Pesa.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('OK'),
                          )
                        ],
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
