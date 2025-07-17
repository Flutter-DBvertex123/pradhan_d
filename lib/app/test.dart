// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
// //
// // void main() async {
// //   WidgetsFlutterBinding.ensureInitialized();
// //   await Firebase.initializeApp();
// //   runApp(MyApp());
// // }
// //
// // class MyApp extends StatelessWidget {
// //   @override
// //   Widget build(BuildContext context) {
// //     return MaterialApp(
// //       home: ReferralScreen(),
// //     );
// //   }
// // }
//
// class ReferralScreen extends StatefulWidget {
//   @override
//   _ReferralScreenState createState() => _ReferralScreenState();
// }
//
// class _ReferralScreenState extends State<ReferralScreen> {
//   String _referralLink = 'Click generate to create referral link';
//
//   Future<void> _createReferralLink() async {
//     final DynamicLinkParameters parameters = DynamicLinkParameters(
//       uriPrefix: 'https://pradhaan.page.link', // Replace with your domain
//       link: Uri.parse('https://dbvertex.com/refer?code=12345'), // Deep link with referral code
//       androidParameters: AndroidParameters(
//         packageName: 'com.ioninks.pradhaan', // Replace with your app's package name
//         minimumVersion: 1,
//       ),
//       iosParameters: IOSParameters(
//         bundleId: 'com.yourapp', // Optional if iOS not used
//         minimumVersion: '1.0.1',
//       ),
//       socialMetaTagParameters: SocialMetaTagParameters(
//         title: 'Join Now!',
//         description: 'Use my referral code to earn rewards.',
//         imageUrl: Uri.parse('https://dbvertex.com/assets/referral_banner.png'), // optional image
//       ),
//     );
//
//     try {
//       final ShortDynamicLink shortLink = await FirebaseDynamicLinks.instance.buildShortLink(parameters);
//       final Uri shortUrl = shortLink.shortUrl;
//
//       setState(() {
//         _referralLink = shortUrl.toString();
//       });
//     } catch (e) {
//       setState(() {
//         _referralLink = 'Failed to create link: $e';
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Referral System')),
//       body: Padding(
//         padding: const EdgeInsets.all(20.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text(
//               'Your Referral Link:',
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             SizedBox(height: 10),
//             SelectableText(
//               _referralLink,
//               style: TextStyle(color: Colors.blue, fontSize: 16),
//               textAlign: TextAlign.center,
//             ),
//             SizedBox(height: 30),
//             ElevatedButton(
//               onPressed: _createReferralLink,
//               child: Text('Generate Referral Link'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
