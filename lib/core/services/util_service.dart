//
//
// import 'dart:math';
//
// import 'package:animate_do/animate_do.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
//
// import '../../features/auth/providers/auth_provider.dart';
// import '../../features/shared/widgets/custom_button.dart';
// import '../../features/shared/widgets/gradient_background.dart';
// import '../config/app_config.dart';
// import '../providers/app_providers.dart';
// import '../theme/app_colors.dart';
//
//
//
//

//
// class YouTubeBulkImporter {
//   final WidgetRef ref;
//
//   YouTubeBulkImporter(this.ref);
//
//   static final List<Map<String, dynamic>> _curatedFarmingVideos = [
//     // HARVESTING
//     {
//       'youtubeVideoId': 'd-uixwbvIQY',
//       'youtubeUrl': 'https://www.youtube.com/watch?v=d-uixwbvIQY',
//       'title': 'How Rice Is Harvested - Part 1: The Harvester And How It Works',
//       'description': 'Walkthrough of modern rice harvesting, drying and milling processes.',
//       'category': 'Harvesting',
//       'duration': '0:00',
//     },
//     {
//       'youtubeVideoId': 'avt9FDwUi6g',
//       'youtubeUrl': 'https://www.youtube.com/watch?v=avt9FDwUi6g',
//       'title': 'How Rice is Harvested in California!',
//       'description': 'A high-definition look at commercial rice harvesting operations.',
//       'category': 'Harvesting',
//       'duration': '0:00',
//     },
//     {
//       'youtubeVideoId': 'kT1R7Hkps5M',
//       'youtubeUrl': 'https://www.youtube.com/watch?v=kT1R7Hkps5M',
//       'title': 'How Tons of Rice Harvested & Processed | Modern Rice Agriculture Technology',
//       'description': 'Shows harvesting at scale and post-harvest processing in modern facilities.',
//       'category': 'Harvesting',
//       'duration': '0:00',
//     },
//     {
//       'youtubeVideoId': 't_cSKsIbkyM',
//       'youtubeUrl': 'https://www.youtube.com/watch?v=t_cSKsIbkyM',
//       'title': 'Louisiana Rice Harvest with Deere X9\'s',
//       'description': 'Field footage of large-scale rice harvesting with modern combines.',
//       'category': 'Harvesting',
//       'duration': '0:00',
//     },
//
//     // PLANTING
//     {
//       'youtubeVideoId': 'J_mMS3EkHok',
//       'youtubeUrl': 'https://www.youtube.com/watch?v=J_mMS3EkHok',
//       'title': 'Rice Farming: Complete Guide from Seeds to Harvest',
//       'description': 'End-to-end rice production guide: seed selection, planting options, and early management.',
//       'category': 'Planting',
//       'duration': '0:00',
//     },
//     {
//       'youtubeVideoId': 'TLnSb6QXkHo',
//       'youtubeUrl': 'https://www.youtube.com/watch?v=TLnSb6QXkHo',
//       'title': 'The System of Rice Intensification (SRI) | Transforming tradition',
//       'description': 'Introduction to SRI principles for higher yields, less water and improved management.',
//       'category': 'Planting',
//       'duration': '0:00',
//     },
//     {
//       'youtubeVideoId': 'KrBcwdAcYAc',
//       'youtubeUrl': 'https://www.youtube.com/watch?v=KrBcwdAcYAc',
//       'title': 'System of Rice Intensification (SRI): Producing more with less',
//       'description': 'Practical examples and farmer experiences implementing SRI.',
//       'category': 'Planting',
//       'duration': '0:00',
//     },
//     {
//       'youtubeVideoId': 'pFbWbCYLKu4',
//       'youtubeUrl': 'https://www.youtube.com/watch?v=pFbWbCYLKu4',
//       'title': 'Paddy (Rice) Cultivation: Seed Germination, Land Preparation, and Seed Sowing',
//       'description': 'Step-by-step demonstration of seed prep, nursery and early establishment.',
//       'category': 'Planting',
//       'duration': '0:00',
//     },
//
//     // IRRIGATION
//     {
//       'youtubeVideoId': 'tfKWKfagfFs',
//       'youtubeUrl': 'https://www.youtube.com/watch?v=tfKWKfagfFs',
//       'title': 'Alternate wetting and drying (AWD) — using less water to grow rice',
//       'description': 'AWD principles for saving water in irrigated rice systems (practical field advice).',
//       'category': 'Irrigation',
//       'duration': '0:00',
//     },
//     {
//       'youtubeVideoId': '0qu2T7JaVDw',
//       'youtubeUrl': 'https://www.youtube.com/watch?v=0qu2T7JaVDw',
//       'title': 'Alternate Wetting and Drying Rice Fields',
//       'description': 'Farmer-level demonstration of AWD and benefits for water and emissions.',
//       'category': 'Irrigation',
//       'duration': '0:00',
//     },
//     {
//       'youtubeVideoId': '8nB0z5ZU6KU',
//       'youtubeUrl': 'https://www.youtube.com/watch?v=8nB0z5ZU6KU',
//       'title': 'Driving paddy rice farming innovation with water monitoring systems (FAO)',
//       'description': 'FAO coverage of water-monitoring pilots in paddy fields and irrigation optimization.',
//       'category': 'Irrigation',
//       'duration': '0:00',
//     },
//     {
//       'youtubeVideoId': 'RT3kHbCbCZ8',
//       'youtubeUrl': 'https://www.youtube.com/watch?v=RT3kHbCbCZ8',
//       'title': '2021 Rice Field Day: Irrigation & Fertigation (Arkansas)',
//       'description': 'Research/extension field day footage about irrigation and fertigation practices.',
//       'category': 'Irrigation',
//       'duration': '0:00',
//     },
//
//     // PEST CONTROL
//     {
//       'youtubeVideoId': 'm24qTP4lHt0',
//       'youtubeUrl': 'https://www.youtube.com/watch?v=m24qTP4lHt0',
//       'title': 'IPM in Rice (English)',
//       'description': 'Integrated Pest Management basics and rice-specific pest control strategies.',
//       'category': 'Pest Control',
//       'duration': '0:00',
//     },
//     {
//       'youtubeVideoId': 'GXWZ8h_IMQA',
//       'youtubeUrl': 'https://www.youtube.com/watch?v=GXWZ8h_IMQA',
//       'title': 'Seeds of Innovation: Integrated Pest Management for Rice',
//       'description': 'Programs and tools to reduce reliance on chemical pesticides via IPM.',
//       'category': 'Pest Control',
//       'duration': '0:00',
//     },
//     {
//       'youtubeVideoId': 'Yb1ONJJq4hY',
//       'youtubeUrl': 'https://www.youtube.com/watch?v=Yb1ONJJq4hY',
//       'title': 'Integrated Pest Management Protects Vietnamese Rice',
//       'description': 'Case study of IPM adoption and benefits in smallholder rice systems.',
//       'category': 'Pest Control',
//       'duration': '0:00',
//     },
//     {
//       'youtubeVideoId': 'bGEXhrkpqeg',
//       'youtubeUrl': 'https://www.youtube.com/watch?v=bGEXhrkpqeg',
//       'title': 'Essential Rice Pest And Diseases Management Secrets',
//       'description': 'Practical ID and management advice for common rice pests and diseases.',
//       'category': 'Pest Control',
//       'duration': '0:00',
//     },
//
//     // FERTILIZATION
//     {
//       'youtubeVideoId': '_dbDVa3QjeA',
//       'youtubeUrl': 'https://www.youtube.com/watch?v=_dbDVa3QjeA',
//       'title': 'How To Make Compost from rice straw',
//       'description': 'Turning rice straw into usable compost — step-by-step (small & medium farms).',
//       'category': 'Fertilization',
//       'duration': '0:00',
//     },
//     {
//       'youtubeVideoId': 'pEMstSOAebY',
//       'youtubeUrl': 'https://www.youtube.com/watch?v=pEMstSOAebY',
//       'title': 'Soil Testing for Rice',
//       'description': 'How to take samples and interpret soil tests to guide fertilizer decisions.',
//       'category': 'Fertilization',
//       'duration': '0:00',
//     },
//     {
//       'youtubeVideoId': 'N25-Qw5MeSM',
//       'youtubeUrl': 'https://www.youtube.com/watch?v=N25-Qw5MeSM',
//       'title': 'A Step-by-Step Guide for Applying N-P-K in Rice / When and How',
//       'description': 'Timing and method guidance for N, P, K application in rice cropping systems.',
//       'category': 'Fertilization',
//       'duration': '0:00',
//     },
//     {
//       'youtubeVideoId': '_RdPKJkEfvw',
//       'youtubeUrl': 'https://www.youtube.com/watch?v=_RdPKJkEfvw',
//       'title': 'Rice Tissue Testing & Soil Sampling (Arkansas field day)',
//       'description': 'Field-day style guidance on tissue testing to refine fertilizer programs.',
//       'category': 'Fertilization',
//       'duration': '0:00',
//     },
//
//     // MACHINERY
//     {
//       'youtubeVideoId': 'yBOh81KAonQ',
//       'youtubeUrl': 'https://www.youtube.com/watch?v=yBOh81KAonQ',
//       'title': 'How to use Manual Rice Transplanter Machine | Rice / Paddy',
//       'description': 'Practical demo: operating a manual rice transplanter (small-medium farms).',
//       'category': 'Machinery',
//       'duration': '0:00',
//     },
//     {
//       'youtubeVideoId': '-_-1JS9U8Us',
//       'youtubeUrl': 'https://www.youtube.com/watch?v=-_-1JS9U8Us',
//       'title': 'Mechanical Rice Transplanting | Paddy Planting Machine',
//       'description': 'How mechanized transplanters work and field operation tips.',
//       'category': 'Machinery',
//       'duration': '0:00',
//     },
//     {
//       'youtubeVideoId': '75Sm5bpi0GM',
//       'youtubeUrl': 'https://www.youtube.com/watch?v=75Sm5bpi0GM',
//       'title': 'YANMAR | Transplanter operation on the field',
//       'description': 'Manufacturer demo: safe operation and features of a ride-on transplanter.',
//       'category': 'Machinery',
//       'duration': '0:00',
//     },
//     {
//       'youtubeVideoId': 'mqdr1qQtQwI',
//       'youtubeUrl': 'https://www.youtube.com/watch?v=mqdr1qQtQwI',
//       'title': 'Paano mag-operate at mag-maintain ng Rice Combine (Tagalog)',
//       'description': 'Local-language instruction on combine pre-op, operation and maintenance.',
//       'category': 'Machinery',
//       'duration': '0:00',
//     },
//
//     // SPRAYING
//     {
//       'youtubeVideoId': 'L4FSWCX39B4',
//       'youtubeUrl': 'https://www.youtube.com/watch?v=L4FSWCX39B4',
//       'title': 'Spray Drones replacing airplanes for MASSIVE Rice Fields in ...',
//       'description': 'Overview/demo of spray drones used at scale for rice spraying.',
//       'category': 'Spraying',
//       'duration': '0:00',
//     },
//     {
//       'youtubeVideoId': 'vGkCySgyJK8',
//       'youtubeUrl': 'https://www.youtube.com/watch?v=vGkCySgyJK8',
//       'title': 'Spraying Rice Fields by Drone in Chiang Mai',
//       'description': 'Real-world footage of drone spraying in Southeast Asian rice paddies.',
//       'category': 'Spraying',
//       'duration': '0:00',
//     },
//     {
//       'youtubeVideoId': 'poesaVUL1xw',
//       'youtubeUrl': 'https://www.youtube.com/watch?v=poesaVUL1xw',
//       'title': 'Calibrating Your Sprayer in 3 Easy Steps',
//       'description': 'Simple, practical calibration method to improve spray accuracy and safety.',
//       'category': 'Spraying',
//       'duration': '0:00',
//     },
//     {
//       'youtubeVideoId': 'PDrEACk7kXU',
//       'youtubeUrl': 'https://www.youtube.com/watch?v=PDrEACk7kXU',
//       'title': 'Arkansas Rice Farmer Finds Success with Spray Drone Application',
//       'description': 'Extension-style case study of a farmer adopting drone spraying for rice.',
//       'category': 'Spraying',
//       'duration': '0:00',
//     },
//
//     // MODERN TECHNIQUES
//     {
//       'youtubeVideoId': 'gUiG673Xgvg',
//       'youtubeUrl': 'https://www.youtube.com/watch?v=gUiG673Xgvg',
//       'title': 'Precision Farming in Japan: How smart tools ensure full rice bowls',
//       'description': 'How precision tools (sensors, GPS, guidance) are applied to rice.',
//       'category': 'Modern Techniques',
//       'duration': '0:00',
//     },
//     {
//       'youtubeVideoId': 'Exm-JUt5ifY',
//       'youtubeUrl': 'https://www.youtube.com/watch?v=Exm-JUt5ifY',
//       'title': 'AgriSentry: Smart IoT Pest Control for Sustainable Rice',
//       'description': 'Example of IoT devices and sensors used to support pest control.',
//       'category': 'Modern Techniques',
//       'duration': '0:00',
//     },
//     {
//       'youtubeVideoId': 'QT4TWbPLrN8',
//       'youtubeUrl': 'https://www.youtube.com/watch?v=QT4TWbPLrN8',
//       'title': 'Growing Up: How Vertical Farming Works',
//       'description': 'Intro to vertical farming systems and when they make sense.',
//       'category': 'Modern Techniques',
//       'duration': '0:00',
//     },
//     {
//       'youtubeVideoId': 'yDrrjWDsbiI',
//       'youtubeUrl': 'https://www.youtube.com/watch?v=yDrrjWDsbiI',
//       'title': 'Revolutionize Your Rice Farm with Smart Tech!',
//       'description': 'Overview of smart transplanting, drones, and precision tools for rice farms.',
//       'category': 'Modern Techniques',
//       'duration': '0:00',
//     },
//
//     // CROP ROTATION
//     {
//       'youtubeVideoId': 'yRg5K1OyEX4',
//       'youtubeUrl': 'https://www.youtube.com/watch?v=yRg5K1OyEX4',
//       'title': 'Crop Rotation - Why Is It Important?',
//       'description': 'Short explainer of rotation benefits for soil health and pest control.',
//       'category': 'Crop Rotation',
//       'duration': '0:00',
//     },
//     {
//       'youtubeVideoId': '3-0IQPPMrgI',
//       'youtubeUrl': 'https://www.youtube.com/watch?v=3-0IQPPMrgI',
//       'title': 'Rice/Soybean Rotation with Cover Crops: 2021 NERREC',
//       'description': 'Research/extension example of rice-soy rotation and cover crop integration.',
//       'category': 'Crop Rotation',
//       'duration': '0:00',
//     },
//     {
//       'youtubeVideoId': 'X_Euh4DGL_Y',
//       'youtubeUrl': 'https://www.youtube.com/watch?v=X_Euh4DGL_Y',
//       'title': 'Boost Yields with Cover Crops',
//       'description': 'How legumes and cover crops fit into rotations to boost soil fertility.',
//       'category': 'Crop Rotation',
//       'duration': '0:00',
//     },
//     {
//       'youtubeVideoId': 'QUqC24fQ5Lk',
//       'youtubeUrl': 'https://www.youtube.com/watch?v=QUqC24fQ5Lk',
//       'title': 'Crop Rotation 101',
//       'description': 'Practical planning for creating a multi-year rotation schedule.',
//       'category': 'Crop Rotation',
//       'duration': '0:00',
//     },
//
//     // ADDITIONAL / GENERAL (soil, weather, post-harvest, seed storage)
//     {
//       'youtubeVideoId': 'd1XesesAAzw',
//       'youtubeUrl': 'https://www.youtube.com/watch?v=d1XesesAAzw',
//       'title': 'Harvesting the Future (FAO project film)',
//       'description': 'FAO-style documentary on post-harvest techniques and value-chain improvements.',
//       'category': 'Modern Techniques',
//       'duration': '0:00',
//     },
//     {
//       'youtubeVideoId': 'E7FEFDC926c',
//       'youtubeUrl': 'https://www.youtube.com/watch?v=E7FEFDC926c',
//       'title': 'Storing Rice Seed',
//       'description': 'Practical seed storage tips to keep seed viability and reduce losses.',
//       'category': 'Planting',
//       'duration': '0:00',
//     },
//     {
//       'youtubeVideoId': '71aeT1--bCc',
//       'youtubeUrl': 'https://www.youtube.com/watch?v=71aeT1--bCc',
//       'title': 'How Can I Use Weather Station Data For Farming?',
//       'description': 'Using station data / hyper-local weather to make field decisions.',
//       'category': 'Modern Techniques',
//       'duration': '0:00',
//     },
//     {
//       'youtubeVideoId': 'SgZDrZCkZUI',
//       'youtubeUrl': 'https://www.youtube.com/watch?v=SgZDrZCkZUI',
//       'title': 'Harvest and Post-harvest Management (rice production module)',
//       'description': 'Covers drying, threshing, storage and simple post-harvest loss reduction.',
//       'category': 'Harvesting',
//       'duration': '0:00',
//     },
//   ];
//
//
//   Future<Map<String, dynamic>> importAllVideos() async {
//     int successCount = 0;
//     int failureCount = 0;
//     List<String> errors = [];
//
//     final videosRepository = ref.read(videosRepositoryProvider);
//     final currentUser = ref.read(currentUserProvider);
//
//     if (currentUser == null) {
//       throw Exception('User not authenticated');
//     }
//
//     for (final videoData in _curatedFarmingVideos) {
//       try {
//         // Use the better thumbnail system
//         final youtubeVideoId = videoData['youtubeVideoId'] as String;
//         final thumbnailUrl = YouTubeThumbnailUtils.getThumbnailUrl(
//             youtubeVideoId,
//             quality: 'hqdefault'  // Use medium quality as default (more reliable)
//         );
//
//         await videosRepository.createVideoFromYouTube(
//           youtubeUrl: videoData['youtubeUrl'],
//           title: videoData['title'],
//           description: videoData['description'],
//           category: videoData['category'],
//           authorName: 'Agrich Expert',
//           authorId: currentUser.uid,
//           duration: videoData['duration'] ?? '0:00',
//           customThumbnail: thumbnailUrl,
//         );
//         successCount++;
//       } catch (e) {
//         failureCount++;
//         errors.add('${videoData['title']}: $e');
//         print('Error importing video ${videoData['title']}: $e');
//       }
//
//       // Add a small delay to avoid overwhelming Firebase
//       await Future.delayed(const Duration(milliseconds: 200));
//     }
//
//     return {
//       'totalVideos': _curatedFarmingVideos.length,
//       'successCount': successCount,
//       'failureCount': failureCount,
//       'errors': errors,
//     };
//   }
//
//   // Import videos by category
//   Future<Map<String, dynamic>> importVideosByCategory(String category) async {
//     final categoryVideos = _curatedFarmingVideos
//         .where((video) => video['category'] == category)
//         .toList();
//
//     int successCount = 0;
//     int failureCount = 0;
//     List<String> errors = [];
//
//     final videosRepository = ref.read(videosRepositoryProvider);
//     final currentUser = ref.read(currentUserProvider);
//
//     if (currentUser == null) {
//       throw Exception('User not authenticated');
//     }
//
//     for (final videoData in categoryVideos) {
//       try {
//         await videosRepository.createVideoFromYouTube(
//           youtubeUrl: videoData['youtubeUrl'],
//           title: videoData['title'],
//           description: videoData['description'],
//           category: videoData['category'],
//           authorName: 'Agrich Expert',
//           authorId: currentUser.uid,
//           duration: videoData['duration'] ?? '0:00',
//         );
//         successCount++;
//       } catch (e) {
//         failureCount++;
//         errors.add('${videoData['title']}: $e');
//       }
//
//       await Future.delayed(const Duration(milliseconds: 200));
//     }
//
//     return {
//       'totalVideos': categoryVideos.length,
//       'successCount': successCount,
//       'failureCount': failureCount,
//       'errors': errors,
//     };
//   }
//
//   // Get video count by category
//   Map<String, int> getVideoCountByCategory() {
//     final Map<String, int> counts = {};
//
//     for (final category in AppConfig.videoCategories) {
//       counts[category] = _curatedFarmingVideos
//           .where((video) => video['category'] == category)
//           .length;
//     }
//
//     return counts;
//   }
//
//   // Get total video count
//   int get totalVideoCount => _curatedFarmingVideos.length;
// }
//
// class BulkImportScreen extends ConsumerStatefulWidget {
//   const BulkImportScreen({super.key});
//
//   @override
//   ConsumerState<BulkImportScreen> createState() => _BulkImportScreenState();
// }
//
// class _BulkImportScreenState extends ConsumerState<BulkImportScreen> {
//   late YouTubeBulkImporter _importer;
//   bool _isImporting = false;
//   String? _importStatus;
//   Map<String, dynamic>? _importResults;
//
//   @override
//   void initState() {
//     super.initState();
//     _importer = YouTubeBulkImporter(ref);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final videoCounts = _importer.getVideoCountByCategory();
//
//     return GradientBackground(
//       child: Scaffold(
//         backgroundColor: Colors.transparent,
//         appBar: AppBar(
//           title: const Text('Import YouTube Videos'),
//           backgroundColor: Colors.transparent,
//           elevation: 0,
//           foregroundColor: Colors.white,
//         ),
//         body: SafeArea(
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.all(20),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Overview Card
//                 FadeInUp(
//                   duration: const Duration(milliseconds: 600),
//                   child: Container(
//                     width: double.infinity,
//                     padding: const EdgeInsets.all(20),
//                     decoration: BoxDecoration(
//                       color: Colors.white.withValues(alpha: 0.1),
//                       borderRadius: BorderRadius.circular(16),
//                       border: Border.all(
//                         color: Colors.white.withValues(alpha: 0.2),
//                       ),
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Row(
//                           children: [
//                             Icon(
//                               Icons.video_library,
//                               color: AppColors.primaryGreen,
//                               size: 24,
//                             ),
//                             const SizedBox(width: 12),
//                             Text(
//                               'Video Import Overview',
//                               style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                                 color: Colors.white,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 16),
//                         Text(
//                           'Import ${_importer.totalVideoCount} curated farming videos across ${AppConfig.videoCategories.length} categories.',
//                           style: Theme.of(context).textTheme.bodyLarge?.copyWith(
//                             color: Colors.white.withValues(alpha: 0.9),
//                           ),
//                         ),
//                         const SizedBox(height: 12),
//                         Text(
//                           'All videos are educational, high-quality content specifically selected for agricultural learning.',
//                           style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                             color: Colors.white.withValues(alpha: 0.7),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//
//                 const SizedBox(height: 20),
//
//                 // Category Breakdown
//                 FadeInUp(
//                   duration: const Duration(milliseconds: 600),
//                   delay: const Duration(milliseconds: 100),
//                   child: Container(
//                     width: double.infinity,
//                     padding: const EdgeInsets.all(20),
//                     decoration: BoxDecoration(
//                       color: Colors.white.withValues(alpha: 0.1),
//                       borderRadius: BorderRadius.circular(16),
//                       border: Border.all(
//                         color: Colors.white.withValues(alpha: 0.2),
//                       ),
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           'Videos by Category',
//                           style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                             color: Colors.white,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         const SizedBox(height: 16),
//                         ...videoCounts.entries.map((entry) {
//                           return Padding(
//                             padding: const EdgeInsets.only(bottom: 8),
//                             child: Row(
//                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                               children: [
//                                 Text(
//                                   entry.key,
//                                   style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                                     color: Colors.white.withValues(alpha: 0.9),
//                                   ),
//                                 ),
//                                 Container(
//                                   padding: const EdgeInsets.symmetric(
//                                     horizontal: 8,
//                                     vertical: 4,
//                                   ),
//                                   decoration: BoxDecoration(
//                                     color: AppColors.primaryGreen.withValues(alpha: 0.2),
//                                     borderRadius: BorderRadius.circular(8),
//                                   ),
//                                   child: Text(
//                                     '${entry.value} videos',
//                                     style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                                       color: AppColors.primaryGreen,
//                                       fontWeight: FontWeight.w600,
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           );
//                         }).toList(),
//                       ],
//                     ),
//                   ),
//                 ),
//
//                 const SizedBox(height: 30),
//
//                 // Import Button
//                 FadeInUp(
//                   duration: const Duration(milliseconds: 600),
//                   delay: const Duration(milliseconds: 200),
//                   child: CustomButton(
//                     text: _isImporting ? 'Importing Videos...' : 'Import All Videos',
//                     onPressed: _isImporting ? null : _importAllVideos,
//                     isLoading: _isImporting,
//                     backgroundColor: AppColors.primaryGreen,
//                     textColor: Colors.white,
//                   ),
//                 ),
//
//                 const SizedBox(height: 20),
//
//                 // Import Status
//                 if (_importStatus != null) ...[
//                   FadeInUp(
//                     duration: const Duration(milliseconds: 400),
//                     child: Container(
//                       width: double.infinity,
//                       padding: const EdgeInsets.all(16),
//                       decoration: BoxDecoration(
//                         color: Colors.white.withValues(alpha: 0.1),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: Text(
//                         _importStatus!,
//                         style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                           color: Colors.white,
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                 ],
//
//                 // Import Results
//                 if (_importResults != null) ...[
//                   FadeInUp(
//                     duration: const Duration(milliseconds: 600),
//                     child: Container(
//                       width: double.infinity,
//                       padding: const EdgeInsets.all(20),
//                       decoration: BoxDecoration(
//                         color: Colors.white.withValues(alpha: 0.1),
//                         borderRadius: BorderRadius.circular(16),
//                         border: Border.all(
//                           color: AppColors.primaryGreen.withValues(alpha: 0.3),
//                         ),
//                       ),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Row(
//                             children: [
//                               Icon(
//                                 Icons.check_circle,
//                                 color: AppColors.primaryGreen,
//                                 size: 24,
//                               ),
//                               const SizedBox(width: 12),
//                               Text(
//                                 'Import Complete!',
//                                 style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                                   color: Colors.white,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 16),
//                           _buildResultRow('Total Videos', '${_importResults!['totalVideos']}'),
//                           _buildResultRow('Successfully Imported', '${_importResults!['successCount']}'),
//                           if (_importResults!['failureCount'] > 0)
//                             _buildResultRow('Failed', '${_importResults!['failureCount']}'),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildResultRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             label,
//             style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//               color: Colors.white.withValues(alpha: 0.9),
//             ),
//           ),
//           Text(
//             value,
//             style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//               color: AppColors.primaryGreen,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Future<void> _importAllVideos() async {
//     setState(() {
//       _isImporting = true;
//       _importStatus = 'Starting import process...';
//       _importResults = null;
//     });
//
//     try {
//       setState(() {
//         _importStatus = 'Importing ${_importer.totalVideoCount} videos...';
//       });
//
//       final results = await _importer.importAllVideos();
//
//       setState(() {
//         _isImporting = false;
//         _importStatus = null;
//         _importResults = results;
//       });
//
//       // Show success message
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             'Successfully imported ${results['successCount']} videos!',
//           ),
//           backgroundColor: AppColors.primaryGreen,
//           duration: const Duration(seconds: 3),
//         ),
//       );
//     } catch (e) {
//       setState(() {
//         _isImporting = false;
//         _importStatus = 'Import failed: $e';
//       });
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Import failed: $e'),
//           backgroundColor: Colors.red,
//           duration: const Duration(seconds: 3),
//         ),
//       );
//     }
//   }
// }
//
// class TipsUploaderScreen extends StatefulWidget {
//   const TipsUploaderScreen({super.key});
//
//   @override
//   State<TipsUploaderScreen> createState() => _TipsUploaderScreenState();
// }
//
// class _TipsUploaderScreenState extends State<TipsUploaderScreen> {
//   bool _isUploading = false;
//   int _uploadedCount = 0;
//   String _currentStatus = '';
//   List<String> _uploadLog = [];
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Upload Farming Tips'),
//         backgroundColor: Colors.green,
//         foregroundColor: Colors.white,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(20.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Header Info
//             Card(
//               child: Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       '100 Rice Farming Tips',
//                       style: Theme.of(context).textTheme.headlineSmall
//                           ?.copyWith(fontWeight: FontWeight.bold),
//                     ),
//                     const SizedBox(height: 8),
//                     const Text(
//                       'This will upload 100 expert rice farming tips covering:\n'
//                           '• Planting techniques (20 tips)\n'
//                           '• Water management (20 tips)\n'
//                           '• Fertilization (20 tips)\n'
//                           '• Pest control (20 tips)\n'
//                           '• Harvesting (10 tips)\n'
//                           '• General farming practices (10 tips)',
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//
//             const SizedBox(height: 20),
//
//             // Upload Button
//             SizedBox(
//               width: double.infinity,
//               height: 50,
//               child: ElevatedButton.icon(
//                 onPressed: _isUploading ? null : _uploadTips,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.green,
//                   foregroundColor: Colors.white,
//                 ),
//                 icon: _isUploading
//                     ? const SizedBox(
//                   width: 20,
//                   height: 20,
//                   child: CircularProgressIndicator(
//                     strokeWidth: 2,
//                     valueColor: AlwaysStoppedAnimation<Color>(
//                       Colors.white,
//                     ),
//                   ),
//                 )
//                     : const Icon(Icons.upload),
//                 label: Text(_isUploading ? 'Uploading...' : 'Upload 100 Tips'),
//               ),
//             ),
//
//             const SizedBox(height: 20),
//
//             // Progress Info
//             if (_isUploading || _uploadedCount > 0) ...[
//               Card(
//                 child: Padding(
//                   padding: const EdgeInsets.all(16.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         children: [
//                           const Icon(Icons.info, color: Colors.blue),
//                           const SizedBox(width: 8),
//                           const Text(
//                             'Progress',
//                             style: TextStyle(fontWeight: FontWeight.bold),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 8),
//                       LinearProgressIndicator(
//                         value: _uploadedCount / 100,
//                         backgroundColor: Colors.grey[300],
//                         valueColor: const AlwaysStoppedAnimation<Color>(
//                           Colors.green,
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       Text('Uploaded: $_uploadedCount / 100 tips'),
//                       if (_currentStatus.isNotEmpty)
//                         Text('Status: $_currentStatus'),
//                     ],
//                   ),
//                 ),
//               ),
//
//               const SizedBox(height: 20),
//             ],
//
//             // Upload Log
//             if (_uploadLog.isNotEmpty) ...[
//               Expanded(
//                 child: Card(
//                   child: Padding(
//                     padding: const EdgeInsets.all(16.0),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const Row(
//                           children: [
//                             Icon(Icons.list, color: Colors.grey),
//                             SizedBox(width: 8),
//                             Text(
//                               'Upload Log',
//                               style: TextStyle(fontWeight: FontWeight.bold),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 8),
//                         Expanded(
//                           child: ListView.builder(
//                             itemCount: _uploadLog.length,
//                             itemBuilder: (context, index) {
//                               final log = _uploadLog[index];
//                               final isError = log.contains('❌');
//                               return Padding(
//                                 padding: const EdgeInsets.symmetric(
//                                   vertical: 2.0,
//                                 ),
//                                 child: Text(
//                                   log,
//                                   style: TextStyle(
//                                     color: isError ? Colors.red : Colors.green,
//                                     fontSize: 12,
//                                   ),
//                                 ),
//                               );
//                             },
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }
//
//
//   Future<void> _uploadTips() async {
//     setState(() {
//       _isUploading = true;
//       _uploadedCount = 0;
//       _uploadLog.clear();
//       _currentStatus = 'Starting upload...';
//     });
//
//     final tips = RiceFarmingTipsData.getAllTips();
//     final random = Random();
//
//     for (int i = 0; i < tips.length; i++) {
//       try {
//         final tip = tips[i];
//
//         // Add metadata including randomIndex
//         final tipData = {
//           ...tip,
//           'isActive': true,
//           'likesCount': 0,
//           'viewCount': 0,
//           'randomIndex': random.nextDouble(), // 👈 here’s the key part
//           'createdAt': FieldValue.serverTimestamp(),
//           'updatedAt': FieldValue.serverTimestamp(),
//         };
//
//         // Upload to Firestore
//         await FirebaseFirestore.instance.collection('tips').add(tipData);
//
//         setState(() {
//           _uploadedCount = i + 1;
//           _currentStatus = 'Uploading: ${tip['title']}';
//           _uploadLog.add('✅ ${i + 1}/100: ${tip['title']}');
//         });
//
//         await Future.delayed(const Duration(milliseconds: 50));
//       } catch (e) {
//         setState(() {
//           _uploadLog.add('❌ Error ${i + 1}: $e');
//         });
//       }
//     }
//
//
//     setState(() {
//       _isUploading = false;
//       _currentStatus = 'Upload completed!';
//       _uploadLog.add('🎉 Successfully uploaded $_uploadedCount tips!');
//     });
//
//     if (mounted) {
//       _showSuccessDialog();
//     }
//   }
//
//
//   void _showSuccessDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Row(
//           children: [
//             Icon(Icons.check_circle, color: Colors.green),
//             SizedBox(width: 8),
//             Text('Upload Successful!'),
//           ],
//         ),
//         content: Text(
//           'Successfully uploaded $_uploadedCount rice farming tips to your database.',
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: const Text('OK'),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// // Complete 100 Tips Data Class
// class RiceFarmingTipsData {
//   static List<Map<String, dynamic>> getAllTips() {
//     return [
//       {
//         'title': 'Optimal Rice Planting Season',
//         'content':
//         'Plant rice during the rainy season when soil moisture is adequate. In tropical regions, plant between May and July for best results.',
//         'category': 'planting',
//         'author': 'Rice Farming Expert',
//         'difficulty': 'beginner',
//         'searchTerms': ['rice', 'planting', 'season', 'timing', 'rainy'],
//         'tags': ['rice', 'timing', 'weather'],
//       },
//       {
//         'title': 'Rice Seed Selection',
//         'content':
//         'Choose high-quality, disease-resistant rice varieties suited to your local climate. Look for seeds with 80-85% germination rate.',
//         'category': 'planting',
//         'author': 'Agricultural Specialist',
//         'difficulty': 'beginner',
//         'searchTerms': ['rice', 'seeds', 'varieties', 'quality', 'germination'],
//         'tags': ['rice', 'seeds', 'quality'],
//       },
//       {
//         'title': 'Seedbed Preparation for Rice',
//         'content':
//         'Prepare a well-drained seedbed with fine, leveled soil. Apply organic matter and ensure proper water management for healthy seedlings.',
//         'category': 'soil care',
//         'author': 'Rice Cultivation Expert',
//         'difficulty': 'intermediate',
//         'searchTerms': ['rice', 'seedbed', 'preparation', 'soil', 'drainage'],
//         'tags': ['rice', 'soil-prep', 'seedbed'],
//       },
//       {
//         'title': 'Rice Transplanting Timing',
//         'content':
//         'Transplant rice seedlings when they are 20-25 days old or have 4-5 leaves. Plant 2-3 seedlings per hill with 15-20cm spacing.',
//         'category': 'planting',
//         'author': 'Field Crop Specialist',
//         'difficulty': 'intermediate',
//         'searchTerms': [
//           'rice',
//           'transplanting',
//           'seedlings',
//           'spacing',
//           'timing',
//         ],
//         'tags': ['rice', 'transplanting', 'spacing'],
//       },
//       {
//         'title': 'Direct Seeding vs Transplanting',
//         'content':
//         'Direct seeding saves labor and time but requires excellent water management. Transplanting gives better weed control and plant establishment.',
//         'category': 'planting',
//         'author': 'Rice Production Specialist',
//         'difficulty': 'advanced',
//         'searchTerms': [
//           'rice',
//           'direct',
//           'seeding',
//           'transplanting',
//           'comparison',
//         ],
//         'tags': ['rice', 'seeding-methods', 'comparison'],
//       },
//       {
//         'title': 'Pre-germinated Seed Technology',
//         'content':
//         'Soak rice seeds for 24 hours, then incubate in moist cloth for 24-48 hours until shoots emerge. This ensures uniform germination.',
//         'category': 'planting',
//         'author': 'Seed Technology Expert',
//         'difficulty': 'intermediate',
//         'searchTerms': [
//           'rice',
//           'pre-germinated',
//           'seeds',
//           'soaking',
//           'germination',
//         ],
//         'tags': ['rice', 'seed-treatment', 'germination'],
//       },
//       {
//         'title': 'Rice Nursery Management',
//         'content':
//         'Maintain nursery beds with 1-2cm standing water. Apply balanced fertilizer and protect seedlings from pests and diseases.',
//         'category': 'planting',
//         'author': 'Nursery Management Specialist',
//         'difficulty': 'intermediate',
//         'searchTerms': [
//           'rice',
//           'nursery',
//           'seedlings',
//           'management',
//           'fertilizer',
//         ],
//         'tags': ['rice', 'nursery', 'seedling-care'],
//       },
//       {
//         'title': 'Spacing for Maximum Yield',
//         'content':
//         'Use 20x20cm spacing for transplanted rice and 15x15cm for direct seeded rice. Proper spacing ensures better tillering and higher yields.',
//         'category': 'planting',
//         'author': 'Agronomy Expert',
//         'difficulty': 'intermediate',
//         'searchTerms': ['rice', 'spacing', 'yield', 'tillering', 'planting'],
//         'tags': ['rice', 'spacing', 'yield-optimization'],
//       },
//       {
//         'title': 'Hardening Rice Seedlings',
//         'content':
//         'Reduce water levels gradually 3-5 days before transplanting. This hardens seedlings and improves their survival rate after transplanting.',
//         'category': 'planting',
//         'author': 'Transplanting Specialist',
//         'difficulty': 'intermediate',
//         'searchTerms': [
//           'rice',
//           'hardening',
//           'seedlings',
//           'transplanting',
//           'survival',
//         ],
//         'tags': ['rice', 'seedling-care', 'transplanting'],
//       },
//       {
//         'title': 'Zero Tillage Rice Planting',
//         'content':
//         'Plant rice directly into untilled soil using specialized machinery. This conserves moisture, reduces costs, and improves soil health.',
//         'category': 'planting',
//         'author': 'Conservation Agriculture Expert',
//         'difficulty': 'advanced',
//         'searchTerms': [
//           'rice',
//           'zero-tillage',
//           'conservation',
//           'soil-health',
//           'machinery',
//         ],
//         'tags': ['rice', 'conservation', 'sustainable'],
//       },
//       {
//         'title': 'System of Rice Intensification (SRI)',
//         'content':
//         'Plant single young seedlings (8-12 days old) with wide spacing (25x25cm). Use alternate wetting and drying for higher yields with less water.',
//         'category': 'planting',
//         'author': 'SRI Specialist',
//         'difficulty': 'advanced',
//         'searchTerms': [
//           'rice',
//           'SRI',
//           'intensification',
//           'single-seedling',
//           'water-saving',
//         ],
//         'tags': ['rice', 'SRI', 'intensive-farming'],
//       },
//       {
//         'title': 'Floating Rice Cultivation',
//         'content':
//         'In flood-prone areas, use floating rice varieties that can grow with rising water levels. Plant on raised beds for better drainage.',
//         'category': 'planting',
//         'author': 'Flood Management Expert',
//         'difficulty': 'advanced',
//         'searchTerms': [
//           'rice',
//           'floating',
//           'flood',
//           'varieties',
//           'water-management',
//         ],
//         'tags': ['rice', 'flood-management', 'adaptation'],
//       },
//       {
//         'title': 'Rice Variety Selection Guide',
//         'content':
//         'Choose short-duration varieties (90-120 days) for multiple cropping. Select aromatic varieties for premium markets and high-yielding varieties for food security.',
//         'category': 'planting',
//         'author': 'Rice Breeding Specialist',
//         'difficulty': 'intermediate',
//         'searchTerms': ['rice', 'varieties', 'selection', 'duration', 'market'],
//         'tags': ['rice', 'variety-selection', 'market'],
//       },
//       {
//         'title': 'Seed Treatment Before Planting',
//         'content':
//         'Treat rice seeds with fungicide and hot water (52°C for 10 minutes) to control seed-borne diseases. Air dry before planting.',
//         'category': 'planting',
//         'author': 'Plant Pathologist',
//         'difficulty': 'intermediate',
//         'searchTerms': [
//           'rice',
//           'seed-treatment',
//           'fungicide',
//           'disease-control',
//           'hot-water',
//         ],
//         'tags': ['rice', 'disease-prevention', 'seed-treatment'],
//       },
//       {
//         'title': 'Machine Transplanting Benefits',
//         'content':
//         'Use rice transplanting machines for uniform spacing, reduced labor costs, and faster planting. Ensure seedlings are 20-25 days old for machine compatibility.',
//         'category': 'planting',
//         'author': 'Agricultural Mechanization Expert',
//         'difficulty': 'advanced',
//         'searchTerms': [
//           'rice',
//           'machine',
//           'transplanting',
//           'mechanization',
//           'labor',
//         ],
//         'tags': ['rice', 'mechanization', 'efficiency'],
//       },
//       {
//         'title': 'Rainfed Rice Management',
//         'content':
//         'In rainfed areas, prepare fields before monsoon arrival. Use drought-tolerant varieties and practice water conservation techniques.',
//         'category': 'planting',
//         'author': 'Rainfed Agriculture Specialist',
//         'difficulty': 'intermediate',
//         'searchTerms': [
//           'rice',
//           'rainfed',
//           'drought-tolerant',
//           'monsoon',
//           'water-conservation',
//         ],
//         'tags': ['rice', 'rainfed', 'drought-management'],
//       },
//       {
//         'title': 'Aerobic Rice Cultivation',
//         'content':
//         'Grow rice like upland crops without standing water. Use aerobic rice varieties and drip irrigation for water-scarce regions.',
//         'category': 'planting',
//         'author': 'Water-Efficient Agriculture Expert',
//         'difficulty': 'advanced',
//         'searchTerms': [
//           'rice',
//           'aerobic',
//           'upland',
//           'water-efficient',
//           'drip-irrigation',
//         ],
//         'tags': ['rice', 'water-efficient', 'aerobic'],
//       },
//       {
//         'title': 'Companion Planting with Rice',
//         'content':
//         'Grow fish, ducks, or azolla with rice for integrated farming. This provides additional income and natural pest control.',
//         'category': 'planting',
//         'author': 'Integrated Farming Specialist',
//         'difficulty': 'advanced',
//         'searchTerms': ['rice', 'companion', 'integrated', 'fish', 'ducks'],
//         'tags': ['rice', 'integrated-farming', 'diversification'],
//       },
//       {
//         'title': 'Climate-Resilient Rice Varieties',
//         'content':
//         'Select varieties tolerant to salt, drought, submergence, or temperature stress based on your local climate challenges.',
//         'category': 'planting',
//         'author': 'Climate Adaptation Specialist',
//         'difficulty': 'intermediate',
//         'searchTerms': [
//           'rice',
//           'climate-resilient',
//           'stress-tolerant',
//           'adaptation',
//           'varieties',
//         ],
//         'tags': ['rice', 'climate-adaptation', 'resilience'],
//       },
//       {
//         'title': 'Rice Plant Population Optimization',
//         'content':
//         'Maintain 250-300 plants per square meter for optimal yield. Adjust plant population based on variety, season, and growing conditions.',
//         'category': 'planting',
//         'author': 'Crop Density Specialist',
//         'difficulty': 'intermediate',
//         'searchTerms': [
//           'rice',
//           'plant-population',
//           'density',
//           'yield-optimization',
//           'spacing',
//         ],
//         'tags': ['rice', 'plant-density', 'yield'],
//       },
//
//       {
//         'title': 'Rice Field Water Depth',
//         'content':
//         'Maintain 2-5cm water depth during vegetative stage. Increase to 5-10cm during reproductive stage for optimal grain development.',
//         'category': 'watering',
//         'author': 'Irrigation Specialist',
//         'difficulty': 'intermediate',
//         'searchTerms': ['rice', 'water', 'depth', 'irrigation', 'management'],
//         'tags': ['rice', 'water-management', 'irrigation'],
//       },
//       {
//         'title': 'Alternate Wetting and Drying (AWD)',
//         'content':
//         'Practice AWD to save water and reduce methane emissions. Allow fields to dry until soil cracks appear 15cm deep, then re-flood.',
//         'category': 'watering',
//         'author': 'Sustainable Agriculture Expert',
//         'difficulty': 'advanced',
//         'searchTerms': [
//           'rice',
//           'AWD',
//           'water-saving',
//           'irrigation',
//           'sustainable',
//         ],
//         'tags': ['rice', 'water-saving', 'sustainability'],
//       },
//       {
//         'title': 'Rice Field Drainage',
//         'content':
//         'Ensure proper drainage 2 weeks before harvest. This firms the soil for machinery and reduces grain moisture content.',
//         'category': 'watering',
//         'author': 'Rice Harvest Expert',
//         'difficulty': 'intermediate',
//         'searchTerms': ['rice', 'drainage', 'harvest', 'field', 'preparation'],
//         'tags': ['rice', 'drainage', 'harvest-prep'],
//       },
//       {
//         'title': 'Managing Water During Drought',
//         'content':
//         'During drought, prioritize water during critical growth stages: tillering, panicle initiation, and grain filling.',
//         'category': 'watering',
//         'author': 'Drought Management Specialist',
//         'difficulty': 'advanced',
//         'searchTerms': [
//           'rice',
//           'drought',
//           'water',
//           'management',
//           'critical-stages',
//         ],
//         'tags': ['rice', 'drought', 'water-stress'],
//       },
//       {
//         'title': 'Rainwater Harvesting for Rice',
//         'content':
//         'Collect rainwater in ponds during monsoon season. Use stored water during dry spells to maintain consistent rice field water levels.',
//         'category': 'watering',
//         'author': 'Water Conservation Expert',
//         'difficulty': 'intermediate',
//         'searchTerms': [
//           'rice',
//           'rainwater',
//           'harvesting',
//           'conservation',
//           'storage',
//         ],
//         'tags': ['rice', 'rainwater', 'conservation'],
//       },
//       {
//         'title': 'Drip Irrigation for Rice',
//         'content':
//         'Use drip irrigation in aerobic rice systems to save 40-50% water. Install drip lines 30cm apart with emitters every 20cm.',
//         'category': 'watering',
//         'author': 'Micro-irrigation Specialist',
//         'difficulty': 'advanced',
//         'searchTerms': [
//           'rice',
//           'drip',
//           'irrigation',
//           'water-efficient',
//           'aerobic',
//         ],
//         'tags': ['rice', 'drip-irrigation', 'water-efficient'],
//       },
//       {
//         'title': 'Rice Water Quality Management',
//         'content':
//         'Use clean water for irrigation. Test water for salinity, pH, and pollutants. Avoid water with EC > 3 dS/m for rice cultivation.',
//         'category': 'watering',
//         'author': 'Water Quality Expert',
//         'difficulty': 'intermediate',
//         'searchTerms': [
//           'rice',
//           'water-quality',
//           'salinity',
//           'pH',
//           'irrigation',
//         ],
//         'tags': ['rice', 'water-quality', 'salinity'],
//       },
//       {
//         'title': 'Flood Water Management',
//         'content':
//         'In flood-prone areas, maintain 20-30cm bunds around fields. Use pumps to drain excess water quickly to prevent crop damage.',
//         'category': 'watering',
//         'author': 'Flood Management Expert',
//         'difficulty': 'intermediate',
//         'searchTerms': [
//           'rice',
//           'flood',
//           'bunds',
//           'drainage',
//           'water-management',
//         ],
//         'tags': ['rice', 'flood-management', 'drainage'],
//       },
//       {
//         'title': 'Smart Irrigation Scheduling',
//         'content':
//         'Use soil moisture sensors and weather data to schedule irrigation. Water when soil moisture drops to 80% field capacity.',
//         'category': 'watering',
//         'author': 'Precision Agriculture Expert',
//         'difficulty': 'advanced',
//         'searchTerms': ['rice', 'smart', 'irrigation', 'sensors', 'precision'],
//         'tags': ['rice', 'smart-irrigation', 'precision'],
//       },
//       {
//         'title': 'Sprinkler Irrigation for Rice',
//         'content':
//         'Use sprinkler systems during land preparation and early growth stages. Switch to flooding during tillering and reproductive phases.',
//         'category': 'watering',
//         'author': 'Irrigation Systems Expert',
//         'difficulty': 'intermediate',
//         'searchTerms': [
//           'rice',
//           'sprinkler',
//           'irrigation',
//           'early-growth',
//           'water-management',
//         ],
//         'tags': ['rice', 'sprinkler', 'water-systems'],
//       },
//       {
//         'title': 'Water-Efficient Rice Varieties',
//         'content':
//         'Choose varieties that perform well under limited water conditions. Look for deep root systems and drought tolerance traits.',
//         'category': 'watering',
//         'author': 'Water-Efficient Crops Specialist',
//         'difficulty': 'intermediate',
//         'searchTerms': [
//           'rice',
//           'water-efficient',
//           'varieties',
//           'drought-tolerant',
//           'deep-roots',
//         ],
//         'tags': ['rice', 'water-efficient', 'variety-selection'],
//       },
//       {
//         'title': 'Mulching in Rice Fields',
//         'content':
//         'Use rice straw mulch in upland rice systems to conserve soil moisture and suppress weeds. Apply 2-3 tons per hectare.',
//         'category': 'watering',
//         'author': 'Soil Conservation Expert',
//         'difficulty': 'beginner',
//         'searchTerms': [
//           'rice',
//           'mulching',
//           'moisture',
//           'conservation',
//           'straw',
//         ],
//         'tags': ['rice', 'mulching', 'moisture-conservation'],
//       },
//       {
//         'title': 'Underground Water Conservation',
//         'content':
//         'Install percolation tanks and check dams to recharge groundwater. This ensures sustainable water supply for rice cultivation.',
//         'category': 'watering',
//         'author': 'Groundwater Management Expert',
//         'difficulty': 'advanced',
//         'searchTerms': [
//           'rice',
//           'groundwater',
//           'conservation',
//           'recharge',
//           'sustainability',
//         ],
//         'tags': ['rice', 'groundwater', 'sustainability'],
//       },
//       {
//         'title': 'Rice Water Productivity',
//         'content':
//         'Monitor water productivity as kg grain per cubic meter of water used. Target 0.8-1.2 kg/m³ for efficient water use.',
//         'category': 'watering',
//         'author': 'Water Productivity Specialist',
//         'difficulty': 'advanced',
//         'searchTerms': [
//           'rice',
//           'water-productivity',
//           'efficiency',
//           'monitoring',
//           'metrics',
//         ],
//         'tags': ['rice', 'water-productivity', 'monitoring'],
//       },
//       {
//         'title': 'Controlled Drainage Systems',
//         'content':
//         'Install water control structures to manage water levels precisely. This allows flexible water management throughout the growing season.',
//         'category': 'watering',
//         'author': 'Drainage Engineering Expert',
//         'difficulty': 'advanced',
//         'searchTerms': [
//           'rice',
//           'controlled',
//           'drainage',
//           'water-control',
//           'structures',
//         ],
//         'tags': ['rice', 'drainage-systems', 'water-control'],
//       },
//       {
//         'title': 'Rice Field Evapotranspiration',
//         'content':
//         'Monitor daily water loss through evapotranspiration (4-7mm/day). Adjust irrigation schedules based on weather conditions and crop stage.',
//         'category': 'watering',
//         'author': 'Crop Water Relations Expert',
//         'difficulty': 'advanced',
//         'searchTerms': [
//           'rice',
//           'evapotranspiration',
//           'water-loss',
//           'irrigation-scheduling',
//           'monitoring',
//         ],
//         'tags': ['rice', 'evapotranspiration', 'water-monitoring'],
//       },
//       {
//         'title': 'Saline Water Management',
//         'content':
//         'In coastal areas, use freshwater during critical growth stages and diluted saline water during less sensitive periods.',
//         'category': 'watering',
//         'author': 'Saline Agriculture Expert',
//         'difficulty': 'advanced',
//         'searchTerms': ['rice', 'saline', 'water', 'coastal', 'salt-tolerance'],
//         'tags': ['rice', 'saline-water', 'coastal-farming'],
//       },
//       {
//         'title': 'Water Storage Techniques',
//         'content':
//         'Build farm ponds and lined tanks to store water during abundant periods. Use stored water during water-scarce periods.',
//         'category': 'watering',
//         'author': 'Water Storage Specialist',
//         'difficulty': 'intermediate',
//         'searchTerms': [
//           'rice',
//           'water-storage',
//           'farm-ponds',
//           'tanks',
//           'conservation',
//         ],
//         'tags': ['rice', 'water-storage', 'conservation'],
//       },
//       {
//         'title': 'Timing of Water Application',
//         'content':
//         'Apply irrigation early morning or late evening to minimize evaporation losses. Avoid midday irrigation when evaporation is highest.',
//         'category': 'watering',
//         'author': 'Irrigation Timing Expert',
//         'difficulty': 'beginner',
//         'searchTerms': [
//           'rice',
//           'irrigation',
//           'timing',
//           'evaporation',
//           'water-loss',
//         ],
//         'tags': ['rice', 'irrigation-timing', 'efficiency'],
//       },
//       {
//         'title': 'Water pH Management',
//         'content':
//         'Maintain water pH between 6.0-7.5 for optimal rice growth. Use lime to raise pH and sulfur to lower pH if needed.',
//         'category': 'watering',
//         'author': 'Water Chemistry Specialist',
//         'difficulty': 'intermediate',
//         'searchTerms': ['rice', 'water', 'pH', 'management', 'lime'],
//         'tags': ['rice', 'water-chemistry', 'pH'],
//       },
//       {
//         'title': 'Rice NPK Fertilizer Timing',
//         'content':
//         'Apply nitrogen in 3 splits: 50% at basal, 25% at tillering, 25% at panicle initiation. Apply full P and K at transplanting.',
//         'category': 'fertilization',
//         'author': 'Soil Fertility Expert',
//         'difficulty': 'intermediate',
//         'searchTerms': ['rice', 'fertilizer', 'NPK', 'timing', 'split'],
//         'tags': ['fertilizer', 'NPK', 'timing'],
//       },
//       {
//         'title': 'Organic Manure for Rice',
//         'content':
//         'Incorporate 5–10 tons of farmyard manure per hectare before planting to improve soil fertility and structure.',
//         'category': 'fertilization',
//         'author': 'Organic Farming Specialist',
//         'difficulty': 'beginner',
//         'searchTerms': ['organic', 'manure', 'compost', 'soil fertility'],
//         'tags': ['organic', 'soil', 'fertility'],
//       },
//       {
//         'title': 'Micronutrient Management',
//         'content':
//         'Apply zinc sulfate (25kg/ha) in zinc-deficient soils. Foliar spray iron or manganese if deficiency symptoms appear.',
//         'category': 'fertilization',
//         'author': 'Crop Nutrition Expert',
//         'difficulty': 'advanced',
//         'searchTerms': ['zinc', 'iron', 'manganese', 'micronutrient'],
//         'tags': ['rice', 'micronutrients'],
//       },
//       {
//         'title': 'Green Manuring in Rice',
//         'content':
//         'Grow dhaincha or sunhemp before rice and incorporate them into the soil at flowering stage to boost organic nitrogen.',
//         'category': 'fertilization',
//         'author': 'Soil Health Specialist',
//         'difficulty': 'intermediate',
//         'searchTerms': ['green manure', 'organic', 'nitrogen'],
//         'tags': ['soil health', 'organic'],
//       },
//       {
//         'title': 'Site-Specific Nutrient Management',
//         'content':
//         'Use leaf color charts and soil testing to apply fertilizers precisely according to crop and soil needs.',
//         'category': 'fertilization',
//         'author': 'Precision Farming Specialist',
//         'difficulty': 'advanced',
//         'searchTerms': ['nutrient management', 'soil test', 'leaf color chart'],
//         'tags': ['precision farming', 'nutrients'],
//       },
//       {
//         'title': 'Slow Release Fertilizers',
//         'content':
//         'Apply coated urea or briquettes to reduce nitrogen losses and ensure steady nutrient supply.',
//         'category': 'fertilization',
//         'author': 'Fertilizer Technology Expert',
//         'difficulty': 'advanced',
//         'searchTerms': ['urea', 'slow release', 'briquettes'],
//         'tags': ['fertilizer', 'technology'],
//       },
//       {
//         'title': 'Balanced Fertilization',
//         'content':
//         'Avoid overuse of nitrogen. Balance N, P, K, and micronutrients for sustainable yield and soil health.',
//         'category': 'fertilization',
//         'author': 'Sustainable Farming Expert',
//         'difficulty': 'beginner',
//         'searchTerms': ['balanced fertilizer', 'sustainability'],
//         'tags': ['balanced nutrition'],
//       },
//       {
//         'title': 'Foliar Feeding for Rice',
//         'content':
//         'Spray 1–2% urea or potassium nitrate during critical stages to boost grain filling and yield.',
//         'category': 'fertilization',
//         'author': 'Plant Nutrition Specialist',
//         'difficulty': 'intermediate',
//         'searchTerms': ['foliar spray', 'urea', 'potassium nitrate'],
//         'tags': ['foliar feeding'],
//       },
//       {
//         'title': 'Biofertilizers for Rice',
//         'content':
//         'Use Azospirillum, Azotobacter, and phosphorus-solubilizing bacteria to reduce chemical fertilizer use.',
//         'category': 'fertilization',
//         'author': 'Biofertilizer Expert',
//         'difficulty': 'intermediate',
//         'searchTerms': ['biofertilizer', 'Azospirillum', 'Azotobacter'],
//         'tags': ['biofertilizer'],
//       },
//       {
//         'title': 'Integrated Nutrient Management',
//         'content':
//         'Combine chemical fertilizers with organic manures and biofertilizers for higher efficiency and soil health.',
//         'category': 'fertilization',
//         'author': 'Integrated Farming Specialist',
//         'difficulty': 'advanced',
//         'searchTerms': ['integrated nutrient', 'fertilizer', 'organic'],
//         'tags': ['INM', 'sustainability'],
//       },
//       {
//         'title': 'Silicon Application in Rice',
//         'content':
//         'Apply calcium silicate to strengthen plant tissues and improve resistance against pests and diseases.',
//         'category': 'fertilization',
//         'author': 'Crop Protection Specialist',
//         'difficulty': 'advanced',
//         'searchTerms': ['silicon', 'disease resistance'],
//         'tags': ['silicon', 'resilience'],
//       },
//       {
//         'title': 'Use of Vermicompost',
//         'content':
//         'Apply 2–3 tons/ha of vermicompost for enriched nutrients and better microbial activity in soil.',
//         'category': 'fertilization',
//         'author': 'Organic Fertility Expert',
//         'difficulty': 'beginner',
//         'searchTerms': ['vermicompost', 'organic', 'soil microbes'],
//         'tags': ['organic', 'vermicompost'],
//       },
//       {
//         'title': 'Fertilizer Deep Placement',
//         'content':
//         'Place urea super granules 7–10 cm below soil surface to minimize nitrogen losses.',
//         'category': 'fertilization',
//         'author': 'Nutrient Efficiency Specialist',
//         'difficulty': 'advanced',
//         'searchTerms': ['fertilizer placement', 'deep placement'],
//         'tags': ['urea', 'placement'],
//       },
//       {
//         'title': 'Phosphorus Management',
//         'content':
//         'Apply phosphorus at transplanting. Band application near root zone ensures better uptake.',
//         'category': 'fertilization',
//         'author': 'Soil Phosphorus Expert',
//         'difficulty': 'intermediate',
//         'searchTerms': ['phosphorus', 'fertilizer', 'uptake'],
//         'tags': ['phosphorus'],
//       },
//       {
//         'title': 'Potassium Role in Rice',
//         'content':
//         'Apply potassium to improve lodging resistance and grain quality. Essential during panicle initiation.',
//         'category': 'fertilization',
//         'author': 'Potash Specialist',
//         'difficulty': 'beginner',
//         'searchTerms': ['potassium', 'grain quality'],
//         'tags': ['potassium'],
//       },
//       {
//         'title': 'Nitrogen Loss Prevention',
//         'content':
//         'Avoid applying nitrogen during heavy rainfall to reduce leaching and volatilization.',
//         'category': 'fertilization',
//         'author': 'Nitrogen Management Expert',
//         'difficulty': 'intermediate',
//         'searchTerms': ['nitrogen', 'loss', 'leaching'],
//         'tags': ['nitrogen', 'loss-prevention'],
//       },
//       {
//         'title': 'Use of Farmyard Manure',
//         'content':
//         'Decompose farmyard manure properly before application to avoid weed seeds and pathogens.',
//         'category': 'fertilization',
//         'author': 'Organic Soil Specialist',
//         'difficulty': 'beginner',
//         'searchTerms': ['farmyard manure', 'organic'],
//         'tags': ['FYM', 'organic'],
//       },
//       {
//         'title': 'Sulfur Deficiency in Rice',
//         'content':
//         'Apply gypsum or elemental sulfur if rice leaves show yellowing similar to nitrogen deficiency.',
//         'category': 'fertilization',
//         'author': 'Soil Chemistry Expert',
//         'difficulty': 'intermediate',
//         'searchTerms': ['sulfur', 'deficiency', 'gypsum'],
//         'tags': ['sulfur'],
//       },
//       {
//         'title': 'Fertilizer Application Method',
//         'content':
//         'Broadcast evenly in standing water or use mechanical spreaders for uniform distribution.',
//         'category': 'fertilization',
//         'author': 'Field Agronomy Expert',
//         'difficulty': 'beginner',
//         'searchTerms': ['fertilizer application', 'broadcasting'],
//         'tags': ['application'],
//       },
//       {
//         'title': 'Fertilizer Dose Adjustment',
//         'content':
//         'Adjust doses based on soil type, rice variety, and yield goals for maximum efficiency.',
//         'category': 'fertilization',
//         'author': 'Soil Testing Specialist',
//         'difficulty': 'intermediate',
//         'searchTerms': ['fertilizer dose', 'soil type'],
//         'tags': ['fertilizer adjustment'],
//       },
//
//       // PEST CONTROL TIPS (61-80)
//       {
//         'title': 'Integrated Pest Management (IPM)',
//         'content':
//         'Combine biological, cultural, and chemical methods for sustainable pest control.',
//         'category': 'pest control',
//         'author': 'IPM Specialist',
//         'difficulty': 'advanced',
//         'searchTerms': ['IPM', 'pest control', 'sustainable'],
//         'tags': ['IPM'],
//       },
//       {
//         'title': 'Brown Planthopper Control',
//         'content':
//         'Avoid excessive nitrogen. Encourage natural predators like spiders and dragonflies.',
//         'category': 'pest control',
//         'author': 'Entomologist',
//         'difficulty': 'intermediate',
//         'searchTerms': ['brown planthopper', 'predators'],
//         'tags': ['pest', 'brown planthopper'],
//       },
//       {
//         'title': 'Rice Stem Borer Management',
//         'content':
//         'Use pheromone traps, resistant varieties, and timely planting to reduce infestation.',
//         'category': 'pest control',
//         'author': 'Pest Management Specialist',
//         'difficulty': 'intermediate',
//         'searchTerms': ['stem borer', 'pheromone traps'],
//         'tags': ['stem borer'],
//       },
//       {
//         'title': 'Leaf Folder Control',
//         'content':
//         'Release Trichogramma parasitoids and avoid indiscriminate pesticide sprays.',
//         'category': 'pest control',
//         'author': 'Biocontrol Expert',
//         'difficulty': 'advanced',
//         'searchTerms': ['leaf folder', 'biocontrol'],
//         'tags': ['leaf folder', 'biocontrol'],
//       },
//       {
//         'title': 'Rice Blast Disease',
//         'content':
//         'Plant resistant varieties and avoid late nitrogen application to control blast.',
//         'category': 'pest control',
//         'author': 'Plant Pathologist',
//         'difficulty': 'beginner',
//         'searchTerms': ['rice blast', 'disease control'],
//         'tags': ['blast disease'],
//       },
//       {
//         'title': 'Bacterial Leaf Blight',
//         'content':
//         'Use disease-free seeds and resistant varieties. Avoid high seeding density.',
//         'category': 'pest control',
//         'author': 'Plant Disease Specialist',
//         'difficulty': 'beginner',
//         'searchTerms': ['bacterial leaf blight'],
//         'tags': ['BLB'],
//       },
//       {
//         'title': 'Rodent Management in Rice Fields',
//         'content':
//         'Practice synchronized planting and field sanitation. Use baiting and traps.',
//         'category': 'pest control',
//         'author': 'Rodent Control Expert',
//         'difficulty': 'intermediate',
//         'searchTerms': ['rodent control', 'baiting'],
//         'tags': ['rodent'],
//       },
//       {
//         'title': 'Weed Management in Rice',
//         'content':
//         'Practice water management, hand weeding, and selective herbicides for weed control.',
//         'category': 'pest control',
//         'author': 'Weed Science Expert',
//         'difficulty': 'beginner',
//         'searchTerms': ['weed control', 'herbicides'],
//         'tags': ['weed'],
//       },
//       {
//         'title': 'Sheath Blight Disease',
//         'content':
//         'Reduce plant density and use resistant varieties to manage sheath blight.',
//         'category': 'pest control',
//         'author': 'Plant Pathologist',
//         'difficulty': 'intermediate',
//         'searchTerms': ['sheath blight'],
//         'tags': ['sheath blight'],
//       },
//       {
//         'title': 'Rice Tungro Virus',
//         'content':
//         'Control green leafhopper vector and use resistant varieties to prevent tungro disease.',
//         'category': 'pest control',
//         'author': 'Virologist',
//         'difficulty': 'advanced',
//         'searchTerms': ['tungro', 'virus'],
//         'tags': ['virus'],
//       },
//       {
//         'title': 'Armyworm Control',
//         'content':
//         'Encourage natural predators and apply biopesticides like Bt formulations.',
//         'category': 'pest control',
//         'author': 'Biocontrol Specialist',
//         'difficulty': 'intermediate',
//         'searchTerms': ['armyworm', 'biopesticide'],
//         'tags': ['armyworm'],
//       },
//       {
//         'title': 'False Smut Disease',
//         'content':
//         'Apply fungicides during booting stage and use clean seeds to prevent false smut.',
//         'category': 'pest control',
//         'author': 'Disease Control Expert',
//         'difficulty': 'intermediate',
//         'searchTerms': ['false smut', 'fungicide'],
//         'tags': ['false smut'],
//       },
//       {
//         'title': 'Snail Management in Rice Fields',
//         'content':
//         'Use bamboo stakes to attract snails and handpick. Maintain proper water levels.',
//         'category': 'pest control',
//         'author': 'Aquatic Pest Expert',
//         'difficulty': 'beginner',
//         'searchTerms': ['snails', 'control'],
//         'tags': ['snails'],
//       },
//       {
//         'title': 'Rice Hispa Beetle',
//         'content':
//         'Avoid excessive nitrogen. Spray neem-based products or recommended insecticides if infestation is high.',
//         'category': 'pest control',
//         'author': 'Insect Pest Specialist',
//         'difficulty': 'intermediate',
//         'searchTerms': ['hispa beetle'],
//         'tags': ['hispa'],
//       },
//       {
//         'title': 'Seedling Pest Protection',
//         'content':
//         'Protect nursery with insect nets and treat seeds with systemic insecticides.',
//         'category': 'pest control',
//         'author': 'Nursery Management Expert',
//         'difficulty': 'beginner',
//         'searchTerms': ['seedling protection'],
//         'tags': ['seedling pests'],
//       },
//       {
//         'title': 'Use of Resistant Varieties',
//         'content':
//         'Adopt pest- and disease-resistant varieties suitable for local conditions.',
//         'category': 'pest control',
//         'author': 'Plant Breeding Specialist',
//         'difficulty': 'beginner',
//         'searchTerms': ['resistant variety'],
//         'tags': ['resistant'],
//       },
//       {
//         'title': 'Bird Damage Control',
//         'content':
//         'Use bird scarers, reflective ribbons, or nets during grain filling stage.',
//         'category': 'pest control',
//         'author': 'Wildlife Management Expert',
//         'difficulty': 'beginner',
//         'searchTerms': ['bird control'],
//         'tags': ['birds'],
//       },
//       {
//         'title': 'Integrated Pest Management (IPM)',
//         'content':
//         'Combine biological, cultural, and chemical methods for sustainable pest control.',
//         'category': 'pest control',
//         'author': 'IPM Specialist',
//         'difficulty': 'advanced',
//         'searchTerms': ['IPM', 'pest control', 'sustainable'],
//         'tags': ['IPM'],
//       },
//       {
//         'title': 'Brown Planthopper Control',
//         'content':
//         'Avoid excessive nitrogen. Encourage natural predators like spiders and dragonflies.',
//         'category': 'pest control',
//         'author': 'Entomologist',
//         'difficulty': 'intermediate',
//         'searchTerms': ['brown planthopper', 'predators'],
//         'tags': ['pest', 'brown planthopper'],
//       },
//       {
//         'title': 'Rice Stem Borer Management',
//         'content':
//         'Use pheromone traps, resistant varieties, and timely planting to reduce infestation.',
//         'category': 'pest control',
//         'author': 'Pest Management Specialist',
//         'difficulty': 'intermediate',
//         'searchTerms': ['stem borer', 'pheromone traps'],
//         'tags': ['stem borer'],
//       },
//       {
//         'title': 'Leaf Folder Control',
//         'content':
//         'Release Trichogramma parasitoids and avoid indiscriminate pesticide sprays.',
//         'category': 'pest control',
//         'author': 'Biocontrol Expert',
//         'difficulty': 'advanced',
//         'searchTerms': ['leaf folder', 'biocontrol'],
//         'tags': ['leaf folder', 'biocontrol'],
//       },
//       {
//         'title': 'Rice Blast Disease',
//         'content':
//         'Plant resistant varieties and avoid late nitrogen application to control blast.',
//         'category': 'pest control',
//         'author': 'Plant Pathologist',
//         'difficulty': 'beginner',
//         'searchTerms': ['rice blast', 'disease control'],
//         'tags': ['blast disease'],
//       },
//       {
//         'title': 'Bacterial Leaf Blight',
//         'content':
//         'Use disease-free seeds and resistant varieties. Avoid high seeding density.',
//         'category': 'pest control',
//         'author': 'Plant Disease Specialist',
//         'difficulty': 'beginner',
//         'searchTerms': ['bacterial leaf blight'],
//         'tags': ['BLB'],
//       },
//       {
//         'title': 'Rodent Management in Rice Fields',
//         'content':
//         'Practice synchronized planting and field sanitation. Use baiting and traps.',
//         'category': 'pest control',
//         'author': 'Rodent Control Expert',
//         'difficulty': 'intermediate',
//         'searchTerms': ['rodent control', 'baiting'],
//         'tags': ['rodent'],
//       },
//       {
//         'title': 'Weed Management in Rice',
//         'content':
//         'Practice water management, hand weeding, and selective herbicides for weed control.',
//         'category': 'pest control',
//         'author': 'Weed Science Expert',
//         'difficulty': 'beginner',
//         'searchTerms': ['weed control', 'herbicides'],
//         'tags': ['weed'],
//       },
//       {
//         'title': 'Sheath Blight Disease',
//         'content':
//         'Reduce plant density and use resistant varieties to manage sheath blight.',
//         'category': 'pest control',
//         'author': 'Plant Pathologist',
//         'difficulty': 'intermediate',
//         'searchTerms': ['sheath blight'],
//         'tags': ['sheath blight'],
//       },
//       {
//         'title': 'Rice Tungro Virus',
//         'content':
//         'Control green leafhopper vector and use resistant varieties to prevent tungro disease.',
//         'category': 'pest control',
//         'author': 'Virologist',
//         'difficulty': 'advanced',
//         'searchTerms': ['tungro', 'virus'],
//         'tags': ['virus'],
//       },
//       {
//         'title': 'Armyworm Control',
//         'content':
//         'Encourage natural predators and apply biopesticides like Bt formulations.',
//         'category': 'pest control',
//         'author': 'Biocontrol Specialist',
//         'difficulty': 'intermediate',
//         'searchTerms': ['armyworm', 'biopesticide'],
//         'tags': ['armyworm'],
//       },
//       {
//         'title': 'False Smut Disease',
//         'content':
//         'Apply fungicides during booting stage and use clean seeds to prevent false smut.',
//         'category': 'pest control',
//         'author': 'Disease Control Expert',
//         'difficulty': 'intermediate',
//         'searchTerms': ['false smut', 'fungicide'],
//         'tags': ['false smut'],
//       },
//       {
//         'title': 'Snail Management in Rice Fields',
//         'content':
//         'Use bamboo stakes to attract snails and handpick. Maintain proper water levels.',
//         'category': 'pest control',
//         'author': 'Aquatic Pest Expert',
//         'difficulty': 'beginner',
//         'searchTerms': ['snails', 'control'],
//         'tags': ['snails'],
//       },
//       {
//         'title': 'Rice Hispa Beetle',
//         'content':
//         'Avoid excessive nitrogen. Spray neem-based products or recommended insecticides if infestation is high.',
//         'category': 'pest control',
//         'author': 'Insect Pest Specialist',
//         'difficulty': 'intermediate',
//         'searchTerms': ['hispa beetle'],
//         'tags': ['hispa'],
//       },
//       {
//         'title': 'Seedling Pest Protection',
//         'content':
//         'Protect nursery with insect nets and treat seeds with systemic insecticides.',
//         'category': 'pest control',
//         'author': 'Nursery Management Expert',
//         'difficulty': 'beginner',
//         'searchTerms': ['seedling protection'],
//         'tags': ['seedling pests'],
//       },
//       {
//         'title': 'Use of Resistant Varieties',
//         'content':
//         'Adopt pest- and disease-resistant varieties suitable for local conditions.',
//         'category': 'pest control',
//         'author': 'Plant Breeding Specialist',
//         'difficulty': 'beginner',
//         'searchTerms': ['resistant variety'],
//         'tags': ['resistant'],
//       },
//       {
//         'title': 'Bird Damage Control',
//         'content':
//         'Use bird scarers, reflective ribbons, or nets during grain filling stage.',
//         'category': 'pest control',
//         'author': 'Wildlife Management Expert',
//         'difficulty': 'beginner',
//         'searchTerms': ['bird control'],
//         'tags': ['birds'],
//       },
//       {
//         'title': 'White Tip Nematode',
//         'content':
//         'Use nematode-free seeds and crop rotation to prevent nematode infestations.',
//         'category': 'pest control',
//         'author': 'Nematology Expert',
//         'difficulty': 'advanced',
//         'searchTerms': ['white tip nematode', 'crop rotation'],
//         'tags': ['nematode'],
//       },
//       {
//         'title': 'Safe Pesticide Application',
//         'content':
//         'Follow recommended doses and timings. Use protective equipment during application.',
//         'category': 'pest control',
//         'author': 'Pesticide Safety Expert',
//         'difficulty': 'beginner',
//         'searchTerms': ['pesticide safety', 'protective equipment'],
//         'tags': ['safety'],
//       },
//
//       // HARVESTING TIPS (81-90)
//       {
//         'title': 'Proper Harvest Timing',
//         'content':
//         'Harvest when 80–85% of grains in the panicle are golden yellow for best yield and quality.',
//         'category': 'harvesting',
//         'author': 'Harvesting Specialist',
//         'difficulty': 'beginner',
//         'searchTerms': ['harvest timing', 'grain maturity'],
//         'tags': ['harvest timing'],
//       },
//       {
//         'title': 'Moisture Content at Harvest',
//         'content':
//         'Harvest at 20–24% grain moisture to minimize shattering and breakage losses.',
//         'category': 'harvesting',
//         'author': 'Post-Harvest Expert',
//         'difficulty': 'intermediate',
//         'searchTerms': ['grain moisture', 'harvest'],
//         'tags': ['moisture'],
//       },
//       {
//         'title': 'Use of Combine Harvesters',
//         'content':
//         'Adopt combine harvesters for timely and efficient harvesting in large fields.',
//         'category': 'harvesting',
//         'author': 'Mechanization Expert',
//         'difficulty': 'intermediate',
//         'searchTerms': ['combine harvester', 'mechanization'],
//         'tags': ['mechanization'],
//       },
//       {
//         'title': 'Manual Harvesting Practices',
//         'content':
//         'Use sharp sickles for manual harvesting. Bundle and stack properly to avoid losses.',
//         'category': 'harvesting',
//         'author': 'Traditional Farming Expert',
//         'difficulty': 'beginner',
//         'searchTerms': ['manual harvesting'],
//         'tags': ['manual'],
//       },
//       {
//         'title': 'Post-Harvest Drying',
//         'content':
//         'Dry paddy to 14% moisture within 24 hours of harvest to avoid fungal growth.',
//         'category': 'harvesting',
//         'author': 'Post-Harvest Specialist',
//         'difficulty': 'beginner',
//         'searchTerms': ['paddy drying', 'moisture'],
//         'tags': ['drying'],
//       },
//       {
//         'title': 'Threshing Practices',
//         'content':
//         'Use mechanical threshers for efficiency or manual beating on wooden platforms.',
//         'category': 'harvesting',
//         'author': 'Threshing Expert',
//         'difficulty': 'intermediate',
//         'searchTerms': ['threshing', 'mechanical'],
//         'tags': ['threshing'],
//       },
//       {
//         'title': 'Grain Storage Management',
//         'content':
//         'Store grains in moisture-proof bags or silos. Use fumigation if necessary.',
//         'category': 'harvesting',
//         'author': 'Storage Specialist',
//         'difficulty': 'intermediate',
//         'searchTerms': ['grain storage', 'silo'],
//         'tags': ['storage'],
//       },
//       {
//         'title': 'Harvest Loss Reduction',
//         'content':
//         'Train farmers on harvesting techniques to reduce shattering, spillage, and lodging losses.',
//         'category': 'harvesting',
//         'author': 'Farm Training Expert',
//         'difficulty': 'beginner',
//         'searchTerms': ['harvest loss reduction'],
//         'tags': ['loss reduction'],
//       },
//       {
//         'title': 'Harvesting During Rainy Season',
//         'content':
//         'Schedule harvest when rainfall probability is low. Use tarpaulins for temporary protection.',
//         'category': 'harvesting',
//         'author': 'Weather Management Expert',
//         'difficulty': 'intermediate',
//         'searchTerms': ['harvest rain', 'tarpaulin'],
//         'tags': ['rain management'],
//       },
//       {
//         'title': 'Proper Grain Handling',
//         'content':
//         'Avoid rough handling of paddy to minimize grain breakage during milling.',
//         'category': 'harvesting',
//         'author': 'Grain Quality Expert',
//         'difficulty': 'beginner',
//         'searchTerms': ['grain handling', 'breakage'],
//         'tags': ['handling'],
//       },
//
//       // GENERAL FARMING PRACTICES (91-100)
//       {
//         'title': 'Crop Rotation with Rice',
//         'content':
//         'Rotate rice with legumes or vegetables to break pest cycles and improve soil fertility.',
//         'category': 'general',
//         'author': 'Agroecology Specialist',
//         'difficulty': 'intermediate',
//         'searchTerms': ['crop rotation', 'legumes'],
//         'tags': ['rotation'],
//       },
//       {
//         'title': 'Rice-Fish Farming System',
//         'content':
//         'Integrate fish culture with rice farming for additional income and pest control.',
//         'category': 'general',
//         'author': 'Integrated Farming Expert',
//         'difficulty': 'advanced',
//         'searchTerms': ['rice-fish system'],
//         'tags': ['integration'],
//       },
//       {
//         'title': 'Use of Certified Seeds',
//         'content':
//         'Always use certified, high-quality seeds for uniform growth and better yields.',
//         'category': 'general',
//         'author': 'Seed Specialist',
//         'difficulty': 'beginner',
//         'searchTerms': ['certified seeds'],
//         'tags': ['seeds'],
//       },
//       {
//         'title': 'Climate-Smart Rice Farming',
//         'content':
//         'Adopt stress-tolerant varieties and water-saving techniques for climate resilience.',
//         'category': 'general',
//         'author': 'Climate Specialist',
//         'difficulty': 'advanced',
//         'searchTerms': ['climate-smart', 'resilience'],
//         'tags': ['climate-smart'],
//       },
//       {
//         'title': 'Farm Record Keeping',
//         'content':
//         'Maintain records of inputs, yields, and practices to improve decision-making.',
//         'category': 'general',
//         'author': 'Farm Management Expert',
//         'difficulty': 'beginner',
//         'searchTerms': ['farm records'],
//         'tags': ['record keeping'],
//       },
//       {
//         'title': 'Farmer Field Schools',
//         'content':
//         'Participate in field schools for knowledge exchange and skill improvement.',
//         'category': 'general',
//         'author': 'Extension Specialist',
//         'difficulty': 'beginner',
//         'searchTerms': ['farmer training'],
//         'tags': ['training'],
//       },
//       {
//         'title': 'Digital Tools in Rice Farming',
//         'content':
//         'Use mobile apps and advisory platforms for weather, pest alerts, and best practices.',
//         'category': 'general',
//         'author': 'AgriTech Specialist',
//         'difficulty': 'intermediate',
//         'searchTerms': ['digital tools', 'apps'],
//         'tags': ['digital'],
//       },
//       {
//         'title': 'Labor Management in Rice Farming',
//         'content':
//         'Plan labor needs in advance, especially during transplanting and harvesting.',
//         'category': 'general',
//         'author': 'Farm Economics Expert',
//         'difficulty': 'beginner',
//         'searchTerms': ['labor management'],
//         'tags': ['labor'],
//       },
//       {
//         'title': 'Soil Testing Before Planting',
//         'content':
//         'Conduct soil tests to determine nutrient requirements before each crop cycle.',
//         'category': 'general',
//         'author': 'Soil Analyst',
//         'difficulty': 'intermediate',
//         'searchTerms': ['soil testing'],
//         'tags': ['soil testing'],
//       },
//       {
//         'title': 'Sustainable Rice Farming Practices',
//         'content':
//         'Adopt eco-friendly practices like reduced tillage, organic inputs, and biodiversity conservation.',
//         'category': 'general',
//         'author': 'Sustainability Expert',
//         'difficulty': 'advanced',
//         'searchTerms': ['sustainable farming'],
//         'tags': ['sustainability'],
//       },
//     ];
//   }
// }


// lib/features/admin/data/services/admin_data_uploader.dart - FIXED VERSION

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../../core/config/app_config.dart';
import '../theme/app_colors.dart';

class AdminDataUploader {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Upload admin users data to the main users collection
  /// This ensures compatibility with existing currentUserProfile provider
  Future<void> uploadAdminData({
    required String superAdminUid,
    required String adminUid,
    required String moderatorUid,
  }) async {
    try {
      print('🚀 Starting admin data upload to main users collection...');

      // Upload the three admin accounts to main users collection
      await _uploadAdminUser(
        uid: superAdminUid,
        email: 'admin@agrich.com',
        username: 'Super Administrator',
        role: 'superAdmin',
      );

      await _uploadAdminUser(
        uid: adminUid,
        email: 'superadmin@agrich.com',
        username: 'Administrator',
        role: 'admin',
      );

      await _uploadAdminUser(
        uid: moderatorUid,
        email: 'moderator@agrich.com',
        username: 'Content Moderator',
        role: 'moderator',
      );

      // Initialize system configuration (separate collection is fine for this)
      await _initializeSystemConfig();

      // Create initial admin action log entry
      await _createInitialAdminLog(superAdminUid);

      print('✅ Admin data upload completed successfully!');
      print('📧 Admin emails configured:');
      print('   - admin@agrich.com (Super Admin) - UID: $superAdminUid');
      print('   - superadmin@agrich.com (Admin) - UID: $adminUid');
      print('   - moderator@agrich.com (Moderator) - UID: $moderatorUid');

    } catch (e) {
      print('❌ Error uploading admin data: $e');
      rethrow;
    }
  }

  /// Upload individual admin user to main users collection
  /// This follows the existing UserModel structure
  Future<void> _uploadAdminUser({
    required String uid,
    required String email,
    required String username,
    required String role,
  }) async {
    // Create user data following the existing UserModel structure
    final userData = {
      // Basic user info (compatible with UserModel)
      'email': email,
      'username': username,
      'phoneNumber': '', // Empty for now, can be updated later
      'profilePictureUrl': '',
      'bio': 'AgriCH ${_getRoleDisplayName(role)}',
      'location': 'System',
      'joinedAt': FieldValue.serverTimestamp(),
      'isEmailVerified': true,
      'isPhoneVerified': false,

      // Admin-specific fields
      'isAdmin': true,
      'adminRole': role,
      'adminPermissions': _getPermissionsForRole(role),
      'adminSince': FieldValue.serverTimestamp(),
      'adminStatus': 'active',

      // Activity tracking
      'lastActiveAt': FieldValue.serverTimestamp(),
      'isActive': true,

      // Stats (initialize to 0)
      'postsCount': 0,
      'commentsCount': 0,
      'likesReceived': 0,

      // Setup metadata
      'setupVersion': '1.0',
      'setupDate': DateTime.now().toIso8601String(),
      'createdBy': 'admin_setup',
    };

    // Save to main users collection (same as regular users)
    await _firestore
        .collection(AppConfig.usersCollection)
        .doc(uid)
        .set(userData, SetOptions(merge: true));

    print('✅ Created ${_getRoleDisplayName(role)}: $email ($uid)');
  }

  /// Get display name for role
  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'superAdmin':
        return 'Super Administrator';
      case 'admin':
        return 'Administrator';
      case 'moderator':
        return 'Moderator';
      default:
        return 'Admin';
    }
  }

  /// Initialize system configuration (this can be in a separate collection)
  Future<void> _initializeSystemConfig() async {
    final systemConfig = {
      'app': {
        'name': 'AgriCH 2.0',
        'version': '2.0.0',
        'environment': 'production',
      },
      'admin': {
        'maxLoginAttempts': 5,
        'sessionTimeout': 24, // hours
        'requireTwoFactor': false,
        'emails': [
          'admin@agrich.com',
          'superadmin@agrich.com',
          'moderator@agrich.com',
        ],
      },
      'content': {
        'autoModeration': true,
        'maxPostLength': 500,
        'maxCommentLength': 200,
        'allowedFileTypes': ['jpg', 'jpeg', 'png', 'gif'],
        'maxFileSize': 5, // MB
      },
      'notifications': {
        'emailAlerts': true,
        'reportThreshold': 5,
        'alertEmails': ['admin@agrich.com'],
      },
      'features': {
        'userRegistration': true,
        'publicPosts': true,
        'videoUploads': true,
        'chatSystem': true,
      },
      'maintenance': {
        'mode': false,
        'message': '',
        'scheduledAt': null,
      },
      'analytics': {
        'enabled': true,
        'retentionDays': 90,
        'trackUserActivity': true,
      },
      'setup': {
        'completed': true,
        'completedAt': FieldValue.serverTimestamp(),
        'adminsCreated': 3,
        'version': '1.0',
      },
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': 'system_setup',
    };

    await _firestore
        .collection(AppConfig.systemConfigCollection)
        .doc('config')
        .set(systemConfig, SetOptions(merge: true));

    print('✅ System configuration initialized');
  }

  /// Create initial admin action log
  Future<void> _createInitialAdminLog(String superAdminUid) async {
    final logEntry = {
      'adminId': superAdminUid,
      'adminName': 'Super Administrator',
      'actionType': 'systemSetup',
      'targetId': 'system',
      'description': 'Initial admin system setup completed - admins added to main users collection',
      'timestamp': FieldValue.serverTimestamp(),
      'metadata': {
        'setupVersion': '1.0',
        'adminsCreated': 3,
        'collections': ['users', 'system_config', 'admin_logs'],
        'adminEmails': [
          'admin@agrich.com',
          'superadmin@agrich.com',
          'moderator@agrich.com',
        ],
      },
    };

    await _firestore
        .collection(AppConfig.adminLogsCollection)
        .add(logEntry);

    print('✅ Initial admin log created');
  }

  /// Get permissions based on role
  List<String> _getPermissionsForRole(String role) {
    switch (role) {
      case 'superAdmin':
        return [
          'user.view',
          'user.create',
          'user.update',
          'user.delete',
          'user.suspend',
          'content.view',
          'content.create',
          'content.update',
          'content.delete',
          'content.moderate',
          'system.config',
          'system.logs',
          'system.analytics',
          'admin.manage',
          'reports.handle',
          'bulk.operations',
        ];
      case 'admin':
        return [
          'user.view',
          'user.update',
          'user.suspend',
          'content.view',
          'content.create',
          'content.update',
          'content.delete',
          'content.moderate',
          'system.logs',
          'reports.handle',
          'bulk.operations',
        ];
      case 'moderator':
        return [
          'user.view',
          'content.view',
          'content.moderate',
          'reports.handle',
        ];
      default:
        return [];
    }
  }

  /// Verify admin setup by checking main users collection
  Future<bool> verifyAdminSetup() async {
    try {
      // Check if admin users exist in main users collection
      final adminUsers = await _firestore
          .collection(AppConfig.usersCollection)
          .where('isAdmin', isEqualTo: true)
          .get();

      // Check if system config exists
      final systemConfig = await _firestore
          .collection(AppConfig.systemConfigCollection)
          .doc('config')
          .get();

      final hasAdmins = adminUsers.docs.isNotEmpty;
      final hasConfig = systemConfig.exists;

      print('🔍 Admin setup verification:');
      print('   - Admin users in main collection: ${hasAdmins ? "✅" : "❌"} (${adminUsers.docs.length} found)');
      print('   - System config: ${hasConfig ? "✅" : "❌"}');

      if (hasAdmins) {
        print('📋 Found admin users:');
        for (final doc in adminUsers.docs) {
          final data = doc.data();
          print('   - ${data['email']} (${data['adminRole']}) - ${doc.id}');
        }
      }

      return hasAdmins && hasConfig;
    } catch (e) {
      print('❌ Error verifying admin setup: $e');
      return false;
    }
  }

  /// Get admin user by UID from main users collection
  Future<Map<String, dynamic>?> getAdminUser(String uid) async {
    try {
      final doc = await _firestore
          .collection(AppConfig.usersCollection)
          .doc(uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        // Only return if user is actually an admin
        if (data['isAdmin'] == true) {
          data['uid'] = uid;
          return data;
        }
      }
      return null;
    } catch (e) {
      print('❌ Error getting admin user: $e');
      return null;
    }
  }

  /// List all admin users from main users collection
  Future<List<Map<String, dynamic>>> listAdminUsers() async {
    try {
      final snapshot = await _firestore
          .collection(AppConfig.usersCollection)
          .where('isAdmin', isEqualTo: true)
          .where('adminStatus', isEqualTo: 'active')
          .orderBy('adminSince')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['uid'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('❌ Error listing admin users: $e');
      return [];
    }
  }

  /// Update admin user in main users collection
  Future<void> updateAdminUser(String uid, Map<String, dynamic> updates) async {
    try {
      // Ensure we don't accidentally remove admin status
      if (updates.containsKey('isAdmin')) {
        updates.remove('isAdmin');
      }

      updates['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore
          .collection(AppConfig.usersCollection)
          .doc(uid)
          .update(updates);

      print('✅ Updated admin user: $uid');
    } catch (e) {
      print('❌ Error updating admin user: $e');
      rethrow;
    }
  }

  /// Deactivate admin user (set adminStatus to inactive, don't delete)
  Future<void> deactivateAdminUser(String uid, String reason) async {
    try {
      await _firestore
          .collection(AppConfig.usersCollection)
          .doc(uid)
          .update({
        'adminStatus': 'inactive',
        'adminDeactivatedAt': FieldValue.serverTimestamp(),
        'adminDeactivationReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Deactivated admin user: $uid');
    } catch (e) {
      print('❌ Error deactivating admin user: $e');
      rethrow;
    }
  }

  /// Reactivate admin user
  Future<void> reactivateAdminUser(String uid) async {
    try {
      await _firestore
          .collection(AppConfig.usersCollection)
          .doc(uid)
          .update({
        'adminStatus': 'active',
        'adminReactivatedAt': FieldValue.serverTimestamp(),
        'adminDeactivationReason': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Reactivated admin user: $uid');
    } catch (e) {
      print('❌ Error reactivating admin user: $e');
      rethrow;
    }
  }

  /// Check if a specific email is already set up as admin
  Future<bool> isEmailSetupAsAdmin(String email) async {
    try {
      final snapshot = await _firestore
          .collection(AppConfig.usersCollection)
          .where('email', isEqualTo: email)
          .where('isAdmin', isEqualTo: true)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get system configuration
  Future<Map<String, dynamic>?> getSystemConfig() async {
    try {
      final doc = await _firestore
          .collection(AppConfig.systemConfigCollection)
          .doc('config')
          .get();

      return doc.exists ? doc.data() : null;
    } catch (e) {
      print('❌ Error getting system config: $e');
      return null;
    }
  }
}