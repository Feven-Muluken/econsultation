import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/storage/secure_storage.dart';
import '../../../core/theme.dart';
import '../bottomnavs/bottom_nav.dart';

class SettingsScreen extends StatefulWidget {
	const SettingsScreen({super.key});

	@override
	State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
	String _selectedLanguage = 'Language';

	Future<void> _openMyAccount() async {
		final token = await SecureStorage.readToken();
		if (!mounted) {
			return;
		}

		final isLoggedIn = token != null && token.trim().isNotEmpty;
		if (!isLoggedIn) {
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Please sign in to access My Account.')),
			);
			return;
		}

		context.go('/my-account');
	}

	Future<void> _openLanguageSheet() async {
		await showModalBottomSheet<void>(
			context: context,
			shape: const RoundedRectangleBorder(
				borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
			),
			builder: (context) {
				return SafeArea(
					child: Padding(
						padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
						child: Column(
							mainAxisSize: MainAxisSize.min,
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								Text(
									'Choose language',
									style: Theme.of(context)
											.textTheme
											.titleMedium
											?.copyWith(fontWeight: FontWeight.w700),
								),
								const SizedBox(height: 12),
								ListTile(
									contentPadding: EdgeInsets.zero,
									title: const Text('English'),
									trailing: _selectedLanguage == 'English'
											? const Icon(Icons.check, color: AppTheme.primaryDark)
											: null,
									onTap: () {
										setState(() => _selectedLanguage = 'English');
										Navigator.of(context).pop();
									},
								),
								ListTile(
									contentPadding: EdgeInsets.zero,
									title: const Text('Amharic'),
									trailing: _selectedLanguage == 'Amharic'
											? const Icon(Icons.check, color: AppTheme.primaryDark)
											: null,
									onTap: () {
										setState(() => _selectedLanguage = 'Amharic');
										Navigator.of(context).pop();
									},
								),
							],
						),
					),
				);
			},
		);
	}

	void _openInfoDialog({
		required String title,
		required String message,
	}) {
		showDialog<void>(
			context: context,
			builder: (context) {
				return AlertDialog(
					title: Text(title),
					content: Text(message),
					actions: [
						TextButton(
							onPressed: () => Navigator.of(context).pop(),
							child: const Text('Close'),
						),
					],
				);
			},
		);
	}

	@override
	Widget build(BuildContext context) {
		final theme = Theme.of(context);

		return Scaffold(
			backgroundColor: AppTheme.background,
			body: LayoutBuilder(
				builder: (context, constraints) {
					final maxWidth = constraints.maxWidth;
					final maxHeight = constraints.maxHeight;
					final horizontalPadding = (maxWidth * 0.06).clamp(16.0, 32.0);
					final contentMaxWidth = maxWidth > 720 ? 720.0 : maxWidth;
					final headerRadius = (maxWidth * 0.06).clamp(16.0, 28.0);

					return SafeArea(
						child: Column(
							children: [
								Container(
									width: double.infinity,
									decoration: BoxDecoration(
										gradient: AppTheme.brandGradient,
										borderRadius: BorderRadius.only(
											bottomLeft: Radius.circular(headerRadius),
											bottomRight: Radius.circular(headerRadius),
										),
									),
									child: Center(
										child: ConstrainedBox(
											constraints: BoxConstraints(maxWidth: contentMaxWidth),
											child: Stack(
												children: [
													Positioned(
														left: 0,
														bottom: 0,
														child: Image.asset(
															'assets/splash/backlogo.png',
															width: 96,
															height: 100,
															fit: BoxFit.contain,
														),
													),
													Padding(
														padding: EdgeInsets.fromLTRB(
															horizontalPadding,
															maxHeight * 0.05,
															horizontalPadding,
															24,
														),
														child: Column(
															children: [
																const SizedBox(height: 12),
																Row(
																	children: [
																		IconButton(
																			onPressed: () => context.go('/home'),
																			icon: const Icon(
																				Icons.arrow_back_ios,
																				color: AppTheme.surface,
																			),
																		),
																		Expanded(
																			child: Text(
																				'Settings',
																				textAlign: TextAlign.center,
																				style: theme.textTheme.headlineMedium
																						?.copyWith(
																					color: AppTheme.surface,
																					fontWeight: FontWeight.w600,
																				),
																			),
																		),
																		// IconButton(
																		// 	onPressed: () => context.go('/home'),
																		// 	icon: const Icon(
																		// 		Icons.menu,
																		// 		color: AppTheme.surface,
																		// 	),
																		// ),
																	],
																),
															],
														),
													),
												],
											),
										),
									),
								),
								Expanded(
									child: SingleChildScrollView(
										padding: EdgeInsets.symmetric(
											horizontal: horizontalPadding,
											vertical: 24,
										),
										child: ConstrainedBox(
											constraints: BoxConstraints(maxWidth: contentMaxWidth),
											child: Column(
												crossAxisAlignment: CrossAxisAlignment.start,
												children: [
                          const SizedBox(height: 12),
                          _buildSectionTitle('Profile'),
                          Column(
                            children: [
                              _buildSettingsTile(
                                icon: Icons.person_outline,
                                title: 'My Account',
                                        onTap: _openMyAccount,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildSectionTitle('Language'),
                          Column(
                            children: [
                              _buildSettingsTile(
                                icon: Icons.language,
                                title: _selectedLanguage,
                                onTap: _openLanguageSheet,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildSectionTitle('App Information'),
                          Column(
                            children: [
                              _buildSettingsTile(
                                icon: Icons.lock_outline,
                                title: 'Privacy Policy',
                                onTap: () => _openInfoDialog(
                                  title: 'Privacy Policy',
                                  message:
                                      'Your feedback and bookmarks are stored securely on this device.',
                                ),
                              ),
                              // const SizedBox(height: 12),
                              _buildSettingsTile(
                                icon: Icons.info_outline,
                                title: 'About the App',
                                onTap: () => _openInfoDialog(
                                  title: 'About the App',
                                  message:
                                      'E-Consultation helps users browse draft documents and submit feedback.',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () {
                              handleLogout();
                              context.go("/");
                            },
                             child: Text(
                              'Logout',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppTheme.statusRed,
                                fontWeight: FontWeight.w600,
                                
                              ),
                             )
                          )
												],
											),
										),
									),
								),
							],
						),
					);
				},
			),
			bottomNavigationBar: BottomNavBar(
				selectedIndex: 3,
				onIndexChanged: (index) {
					switch (index) {
						case 0:
							context.go('/home');
							break;
						case 1:
							context.go('/documents');
							break;
						case 2:
							context.go('/feedback');
							break;
						case 3:
							break;
					}
				},
			),
		);
	}

	Widget _buildSectionTitle(String title) {
		return Padding(
			padding: const EdgeInsets.only(bottom: 8),
			child: Text(
				title,
				style: Theme.of(context).textTheme.labelSmall?.copyWith(
							color: AppTheme.secondaryText,
							fontWeight: FontWeight.w600,
						),
			),
		);
	}

	Widget _buildSettingsTile({
		required IconData icon,
		required String title,
		required VoidCallback onTap,
	}) {
		return Container(
			margin: const EdgeInsets.only(bottom: 8),
			decoration: BoxDecoration(
				color: AppTheme.surface,
				borderRadius: BorderRadius.circular(10),
				border: Border.all(color: AppTheme.borderColor),
			),
			child: ListTile(
				onTap: onTap,
				dense: true,
				contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
				leading: Icon(icon, color: AppTheme.primaryDark, size: 20),
				title: Text(
					title,
					style: Theme.of(context).textTheme.bodyMedium?.copyWith(
								color: AppTheme.primaryText,
								fontWeight: FontWeight.w500,
							),
				),
				trailing: const Icon(
					Icons.arrow_forward_ios,
					size: 14,
					color: AppTheme.primaryDark,
				),
			),
		);
	}
  Future<void> handleLogout() async {
    await SecureStorage.clearToken();
    if(!mounted) return;
  }
}
