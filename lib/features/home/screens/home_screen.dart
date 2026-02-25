import 'package:flutter/material.dart';
import 'package:econsultation/core/theme.dart';
import 'package:go_router/go_router.dart';
import '../bottomnavs/bottom_nav.dart';

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   int _selectedIndex = 0;

//   final List<Widget> _pages = [
//     const HomeDashboard(),
//     const DocumentsScreen(),
//     const FeedbackScreen(),
//     const SettingsScreen(),
//   ];

//   void _onItemTapped(int index) {
//     setState(() => _selectedIndex = index);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Welcome, Mr. Abebe", style: Theme.of(context).textTheme.titleMedium),
//         actions: [
//           DropdownButton<String>(
//             value: "EN",
//             items: const [
//               DropdownMenuItem(value: "EN", child: Text("EN")),
//               DropdownMenuItem(value: "AM", child: Text("AM")),
//             ],
//             onChanged: (value) {},
//           ),
//         ],
//       ),
//       body: _pages[_selectedIndex],
//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: _selectedIndex,
//         onTap: _onItemTapped,
//         items: const [
//           BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
//           BottomNavigationBarItem(icon: Icon(Icons.description), label: "Documents"),
//           BottomNavigationBarItem(icon: Icon(Icons.feedback), label: "Feedback"),
//           BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
//         ],
//       ),
//     );
//   }
// }

// // Placeholder widgets for each tab
// class HomeDashboard extends StatelessWidget {
//   const HomeDashboard({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return ListView(
//       padding: const EdgeInsets.all(16),
//       children: [
//         Text("News", style: Theme.of(context).textTheme.headlineMedium),
//         const SizedBox(height: 10),
//         SizedBox(
//           height: 150,
//           child: ListView(
//             scrollDirection: Axis.horizontal,
//             children: List.generate(3, (index) => Card(
//               child: SizedBox(width: 200, child: Center(child: Text("News Item $index"))),
//             )),
//           ),
//         ),
//         const SizedBox(height: 20),
//         Text("Regulations", style: Theme.of(context).textTheme.headlineMedium),
//         ...List.generate(5, (index) => ListTile(
//           title: Text("Regulation $index"),
//           subtitle: const Text("Agency: Ministry of Justice"),
//           trailing: const Chip(label: Text("Active")),
//         )),
//       ],
//     );
//   }
// }

// class DocumentsScreen extends StatelessWidget {
//   const DocumentsScreen({super.key});
//   @override
//   Widget build(BuildContext context) => const Center(child: Text("Documents List"));
// }

// class FeedbackScreen extends StatelessWidget {
//   const FeedbackScreen({super.key});
//   @override
//   Widget build(BuildContext context) => const Center(child: Text("Feedback Module"));
// }

// class SettingsScreen extends StatelessWidget {
//   const SettingsScreen({super.key});
//   @override
//   Widget build(BuildContext context) => const Center(child: Text("Settings"));
// }



class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final searchController = TextEditingController();
  String selectedLanguage = 'English';
  int selectedNavIndex = 0;

  final List<Regulation> regulations = [
    Regulation(
      title: 'Draft Law on Digital Services Act',
      ministry: 'Ministry of Technology',
      category: 'Technology Law',
      status: 'Open for Consultation',
      statusColor: AppTheme.statusGreenBg,
      statusTextColor: AppTheme.statusGreen,
      iconType: 'gavel',
    ),
    Regulation(
      title: 'Environmental Protection Regulations',
      ministry: 'Environmental Protection Agency',
      category: 'Environmental Law',
      status: 'Finalized',
      statusColor: AppTheme.statusGrayBg,
      statusTextColor: AppTheme.statusGray,
      iconType: 'leaf',
    ),
    Regulation(
      title: 'Environmental Protection Regulations',
      ministry: 'Environmental Protection Agency',
      category: 'Environmental Law',
      status: 'Urgent Review',
      statusColor: AppTheme.statusRedBg,
      statusTextColor: AppTheme.statusRed,
      iconType: 'heartbeat',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header with gradient
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: AppTheme.brandGradient,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting + Language toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello',
                            // style: GoogleFonts.inter(
                            //   fontSize: 14,
                            //   color: Colors.white70,
                            // ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Mr Abebe!!',
                            // style: GoogleFonts.inter(
                            //   fontSize: 24,
                            //   fontWeight: FontWeight.w600,
                            //   color: Colors.white,
                            // ),
                          ),
                        ],
                      ),
                      _buildLanguageToggle(),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Search Bar
                  TextField(
                    controller: searchController,
                    // style: GoogleFonts.inter(
                    //   fontSize: 14,
                    //   color: AppTheme.secondaryText,
                    // ),
                    decoration: InputDecoration(
                      hintText: 'Acts, amendments, publication etc',
                      // hintStyle: GoogleFonts.inter(
                      //   color: AppColors.secondaryText,
                      //   fontSize: 14,
                      // ),
                      filled: true,
                      fillColor: const Color(0xFFEDF3FF),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.borderColor),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppTheme.secondaryText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // News Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'News',
                          // style: GoogleFonts.inter(
                          //   fontSize: 18,
                          //   fontWeight: FontWeight.w600,
                          //   color: AppColors.primaryText,
                          // ),
                        ),
                        GestureDetector(
                          onTap: () {},
                          child: Text(
                            'Load More',
                            // style: GoogleFonts.inter(
                            //   fontSize: 14,
                            //   color: AppColors.secondaryText,
                            //   decoration: TextDecoration.underline,
                            // ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // News Cards
                    SizedBox(
                      height: 200,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildNewsCard(
                            'New Cooperative Law Amendment Tabled in Parliament',
                            'https://api.builder.io/api/v1/image/assets/TEMP/63ec2125ab541427e4beac4da50bf97bcf932666?width=450',
                          ),
                          const SizedBox(width: 16),
                          _buildNewsCard(
                            'New Cooperative Law Amendment Tabled',
                            'https://api.builder.io/api/v1/image/assets/TEMP/be005c82b8f495cb34f0547a4609e9b0dee335bb?width=450',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Regulations Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Regulations',
                          // style: GoogleFonts.inter(
                          //   fontSize: 18,
                          //   fontWeight: FontWeight.w600,
                          //   color: AppColors.primaryText,
                          // ),
                        ),
                        const Icon(Icons.list, color: AppTheme.secondaryText),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Regulation Cards
                    Column(
                      children: regulations
                          .map((reg) => Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _buildRegulationCard(reg),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 100), // Space for bottom nav
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: selectedNavIndex,
        onIndexChanged: (index) {
          setState(() => selectedNavIndex = index);
        },
      ),
    );
  }

  Widget _buildLanguageToggle() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF749DED)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _buildLanguageButton('English', true),
          _buildLanguageButton('አማርኛ', false),
        ],
      ),
    );
  }

  Widget _buildLanguageButton(String lang, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => selectedLanguage = lang),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFBED4FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          lang,
          // style: GoogleFonts.inter(
          //   fontSize: 12,
          //   fontWeight: FontWeight.w500,
          //   color: isSelected ? AppColors.primaryText : Colors.white,
          // ),
        ),
      ),
    );
  }

  Widget _buildNewsCard(String title, String imageUrl) {
    return Container(
      width: 200,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Container(color: Colors.grey[200]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                title,
                // style: GoogleFonts.inter(
                //   fontSize: 12,
                //   fontWeight: FontWeight.w600,
                //   color: AppColors.lightText,
                //   height: 1.5,
                // ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildRegulationCard(Regulation regulation) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: _buildRegulationIcon(regulation.iconType),
            ),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  regulation.title,
                  // style: GoogleFonts.inter(
                  //   fontSize: 16,
                  //   fontWeight: FontWeight.w600,
                  //   color: AppColors.primaryText,
                  // ),
                ),
                const SizedBox(height: 4),
                Text(
                  regulation.ministry,
                  // style: GoogleFonts.publicSans(
                  //   fontSize: 14,
                  //   fontWeight: FontWeight.w500,
                  //   color: AppColors.lightText,
                  // ),
                ),
                const SizedBox(height: 4),
                Text(
                  regulation.category,
                  // style: GoogleFonts.inter(
                  //   fontSize: 12,
                  //   color: AppColors.lightText,
                  // ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: regulation.statusColor,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Text(
                    regulation.status,
                    // style: GoogleFonts.inter(
                    //   fontSize: 12,
                    //   fontWeight: FontWeight.w500,
                    //   color: regulation.statusTextColor,
                    // ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegulationIcon(String iconType) {
    switch (iconType) {
      case 'gavel':
        return const Icon(Icons.gavel, color: AppTheme.primaryText);
      case 'leaf':
        return const Icon(Icons.eco, color: AppTheme.primaryText);
      case 'heartbeat':
        return const Icon(Icons.favorite, color: AppTheme.primaryText);
      default:
        return const Icon(Icons.description, color: AppTheme.primaryText);
    }
  }
}

class Regulation {
  final String title;
  final String ministry;
  final String category;
  final String status;
  final Color statusColor;
  final Color statusTextColor;
  final String iconType;

  Regulation({
    required this.title,
    required this.ministry,
    required this.category,
    required this.status,
    required this.statusColor,
    required this.statusTextColor,
    required this.iconType,
  });
}




