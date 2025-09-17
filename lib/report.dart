import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'localization/app_localizations.dart';
import 'widgets/app_top_bar.dart';

class MyReportsScreen extends StatelessWidget {
  final String userId;

  const MyReportsScreen({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Query reportsQuery = FirebaseFirestore.instance
        .collection('reports')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'Not Approved');

    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppTopBar(title: Text(l.myPendingReports, style: TextStyle(color: theme.appBarTheme.foregroundColor))),
      body: StreamBuilder<QuerySnapshot>(
        stream: reportsQuery.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
                child: Text(
                  '${l.error}: ${snapshot.error}',
                  style: TextStyle(color: theme.colorScheme.error),
                ));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return Center(child: Text(l.noPendingReports, style: TextStyle(color: theme.textTheme.bodyLarge?.color)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              String complaintText = data['complaintText'] ?? '';
              String dateStr = data['date'] ?? '';
              String category = data['category'] ?? '';
              String reportId = docs[index].id;

              // Truncate complaint text for a concise preview.
              String shortComplaint = complaintText.length > 40
                  ? '${complaintText.substring(0, 40)}...'
                  : complaintText;

              // Get image string for hero animation (if any).
              String imageBase64 = data['image'] ?? '';

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReportDetailScreen(
                        reportId: reportId,
                        complaintText: complaintText,
                        date: dateStr,
                        quantity: data['quantity'] ?? 0,
                        weightPerKg: data['weightPerKg'] is int
                            ? (data['weightPerKg'] as int).toDouble()
                            : (data['weightPerKg'] ?? 0.0),
                        status: data['status'] ?? '',
                        userId: userId,
                        imageBase64: imageBase64,
                        category: category,
                      ),
                    ),
                  );
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  elevation: 3,
                  color: theme.cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isDark ? Colors.green.shade900 : Colors.green.shade100,
                      child: Icon(Icons.report, color: isDark ? Colors.greenAccent : Colors.green),
                    ),
                    title: Text(
                      category,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: theme.textTheme.titleLarge?.color),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          shortComplaint,
                          style: TextStyle(fontSize: 14, color: theme.textTheme.bodyMedium?.color),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.calendar_today,
                                size: 14, color: theme.iconTheme.color?.withOpacity(0.7)),
                            const SizedBox(width: 4),
                            Text(
                              dateStr,
                              style: TextStyle(
                                  fontSize: 12, color: theme.textTheme.bodySmall?.color),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: theme.iconTheme.color,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ReportDetailScreen extends StatelessWidget {
  final String reportId;
  final String complaintText;
  final String date;
  final int quantity;
  final double weightPerKg;
  final String status;
  final String userId;
  final String imageBase64;
  final String category;

  const ReportDetailScreen({
    Key? key,
    required this.reportId,
    required this.complaintText,
    required this.date,
    required this.quantity,
    required this.weightPerKg,
    required this.status,
    required this.userId,
    required this.imageBase64,
    required this.category,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // Decode the Base64 image.
    Uint8List? imageBytes;
    if (imageBase64.isNotEmpty) {
      try {
        imageBytes = base64Decode(imageBase64);
      } catch (e) {
        imageBytes = null;
      }
    }

    return Scaffold(
      appBar: AppTopBar(title: Text(AppLocalizations.of(context)!.reportDetails, style: TextStyle(color: theme.appBarTheme.foregroundColor))),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageBytes != null)
              Hero(
                tag: 'reportImage_$reportId',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.memory(
                    imageBytes,
                    width: double.infinity,
                    height: 220,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              category,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: theme.textTheme.titleLarge?.color),
            ),
            const Divider(thickness: 1.5),
            const SizedBox(height: 8),
            Text(
              '${AppLocalizations.of(context)!.complaint}:',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.greenAccent : Colors.green.shade700),
            ),
            const SizedBox(height: 4),
            Text(
              complaintText,
              style: TextStyle(fontSize: 16, color: theme.textTheme.bodyLarge?.color),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.confirmation_number, color: theme.iconTheme.color),
                const SizedBox(width: 8),
                Text(
                  '${AppLocalizations.of(context)!.quantityLabel}: $quantity',
                  style: TextStyle(fontSize: 16, color: theme.textTheme.bodyLarge?.color),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.scale, color: theme.iconTheme.color),
                const SizedBox(width: 8),
                Text(
                  '${AppLocalizations.of(context)!.weightPerKgLabel}: $weightPerKg',
                  style: TextStyle(fontSize: 16, color: theme.textTheme.bodyLarge?.color),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, color: theme.iconTheme.color),
                const SizedBox(width: 8),
                Text(
                  date,
                  style: TextStyle(fontSize: 16, color: theme.textTheme.bodyLarge?.color),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.info_outline, color: theme.iconTheme.color),
                const SizedBox(width: 8),
                Text(
                  '${AppLocalizations.of(context)!.statusLabel}: $status',
                  style: TextStyle(fontSize: 16, color: theme.textTheme.bodyLarge?.color),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                   return Text(
                     AppLocalizations.of(context)!.loadingUserInfo,
                    style: TextStyle(fontSize: 16, color: theme.textTheme.bodyLarge?.color),
                  );
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                   return Text(
                     AppLocalizations.of(context)!.unknownUser,
                    style: TextStyle(fontSize: 16, color: theme.textTheme.bodyLarge?.color),
                  );
                }
                final userData =
                snapshot.data!.data() as Map<String, dynamic>;
                String userName = userData['name'] ?? "Unknown";
                return Row(
                  children: [
                    Icon(Icons.person, color: theme.iconTheme.color),
                    const SizedBox(width: 8),
                    Text(
                      '${AppLocalizations.of(context)!.reportedBy}: $userName',
                      style: TextStyle(fontSize: 16, color: theme.textTheme.bodyLarge?.color),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
