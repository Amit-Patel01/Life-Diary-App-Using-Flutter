import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import '../models/diary_model.dart';
import '../services/drive_service.dart';
import 'add_diary_screen.dart';

class HomeScreen extends StatefulWidget {
  final Function(ThemeMode)? onThemeChanged;
  
  const HomeScreen({super.key, this.onThemeChanged});
  
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Box<DiaryEntry> _diaryBox = Hive.box<DiaryEntry>('diaryBox');
  final DriveService _driveService = DriveService();
  
  bool _isLoading = false;
  bool _isSyncing = false;
  bool _isImporting = false;
  
  // Theme customization
  Color _backgroundColor = Colors.white;
  Color _fontColor = Colors.black87;

  @override
  void initState() {
    super.initState();
    _checkDriveConnection();
  }

  Future<void> _checkDriveConnection() async {
    final isSignedIn = _driveService.googleSignIn.currentUser != null;
    if (isSignedIn && !_driveService.isSignedIn) {
      setState(() {});
    }
  }

  Future<void> _refreshDiaries() async {
    setState(() {});
  }

  Future<void> _syncWithDrive() async {
    if (_isSyncing) return;

    setState(() {
      _isSyncing = true;
    });

    try {
      if (!_driveService.isSignedIn) {
        final success = await _driveService.signIn();
        if (!success) {
          _showSnackBar('Failed to sign in with Google', isError: true);
          return;
        }
      }

      // Get all local entries
      final localEntries = _diaryBox.values.toList();
      
      // Backup to Google Drive
      final backupId = await _driveService.backupAllDiaries(localEntries);
      
      if (backupId != null) {
        _showSnackBar('Backup successful!');
      } else {
        _showSnackBar('Backup failed', isError: true);
      }
    } catch (e) {
      _showSnackBar('Sync error: $e', isError: true);
    } finally {
      setState(() {
        _isSyncing = false;
      });
    }
  }

  Future<void> _deleteDiary(int index) async {
    final entry = _diaryBox.getAt(index);
    if (entry == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: const Text('Are you sure you want to delete this diary entry?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _diaryBox.deleteAt(index);
      _showSnackBar('Entry deleted');
      setState(() {});
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy - hh:mm a').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.book, color: Colors.black),
            const SizedBox(width: 8),
            const Text('Daily Diary', style: TextStyle(color: Colors.black)),
          ],
        ),
        actions: [
          // Settings menu with theme, background color, font color, and import
          PopupMenuButton<String>(
            icon: const Icon(Icons.settings, color: Colors.black),
            tooltip: 'Settings',
            onSelected: (String value) {
              if (value == 'import') {
                _importFromDrive();
              } else if (value.startsWith('theme_')) {
                final mode = value == 'theme_system' 
                    ? ThemeMode.system 
                    : value == 'theme_light' 
                        ? ThemeMode.light 
                        : ThemeMode.dark;
                widget.onThemeChanged?.call(mode);
              } else if (value.startsWith('bg_')) {
                _showBackgroundColorPicker();
              } else if (value.startsWith('font_')) {
                _showFontColorPicker();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'import',
                child: Row(
                  children: [
                    Icon(Icons.cloud_download, color: Colors.blue),
                    SizedBox(width: 12),
                    Text('Import from Drive'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                enabled: false,
                child: Text('Theme', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const PopupMenuItem(
                value: 'theme_system',
                child: Row(
                  children: [
                    Icon(Icons.brightness_auto, color: Colors.orange),
                    SizedBox(width: 12),
                    Text('System'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'theme_light',
                child: Row(
                  children: [
                    Icon(Icons.light_mode, color: Colors.amber),
                    SizedBox(width: 12),
                    Text('Light'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'theme_dark',
                child: Row(
                  children: [
                    Icon(Icons.dark_mode, color: Colors.indigo),
                    SizedBox(width: 12),
                    Text('Dark'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                enabled: false,
                child: Text('Customize', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const PopupMenuItem(
                value: 'bg_color',
                child: Row(
                  children: [
                    Icon(Icons.format_paint, color: Colors.purple),
                    SizedBox(width: 12),
                    Text('Background Color'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'font_color',
                child: Row(
                  children: [
                    Icon(Icons.text_fields, color: Colors.teal),
                    SizedBox(width: 12),
                    Text('Font Color'),
                  ],
                ),
              ),
            ],
          ),
          if (_isSyncing)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
              ),
            )
          else
            IconButton(
              icon: Icon(
                _driveService.isSignedIn 
                    ? Icons.cloud_done 
                    : Icons.cloud_upload,
                color: _driveService.isSignedIn 
                    ? Colors.green 
                    : Colors.black,
              ),
              onPressed: _syncWithDrive,
              tooltip: 'Backup to Google Drive',
            ),
        ],
      ),
      body: Container(
        color: _backgroundColor,
        child: _diaryBox.isEmpty
            ? _buildEmptyState(theme)
            : RefreshIndicator(
                onRefresh: _refreshDiaries,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 100, 16, 100),
                  itemCount: _diaryBox.length,
                  itemBuilder: (context, index) {
                    final entry = _diaryBox.getAt(index)!;
                    return _buildDiaryCard(entry, index, theme);
                  },
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddDiary(),
        icon: const Icon(Icons.add),
        label: const Text('New Entry'),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.book_outlined,
            size: 100,
            color: theme.colorScheme.primary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No diary entries yet',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the button below to write your first entry',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildDiaryCard(DiaryEntry entry, int index, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showDiaryDetails(entry),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(entry.date),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      onPressed: () => _deleteDiary(index),
                      color: Colors.red.shade300,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  entry.text,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: _fontColor,
                  ),
                ),
                if (entry.image != null) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(entry.image!),
                      height: 100,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 100,
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: const Center(
                            child: Icon(Icons.broken_image),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDiaryDetails(DiaryEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(entry.date),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  entry.text,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.6,
                    color: _fontColor,
                  ),
                ),
                if (entry.image != null) ...[
                  const SizedBox(height: 24),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(entry.image!),
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          child: const Center(
                            child: Icon(Icons.broken_image, size: 50),
                          ),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToAddDiary() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AddDiaryScreen()),
    );
    if (result == true) {
      setState(() {});
    }
  }

  // Import diary entries from Google Drive
  Future<void> _importFromDrive() async {
    if (_isImporting) return;

    setState(() {
      _isImporting = true;
    });

    try {
      if (!_driveService.isSignedIn) {
        final success = await _driveService.signIn();
        if (!success) {
          _showSnackBar('Failed to sign in with Google', isError: true);
          return;
        }
      }

      // Download entries from Google Drive
      final driveEntries = await _driveService.downloadDiaries();
      
      if (driveEntries.isEmpty) {
        _showSnackBar('No entries found in Google Drive', isError: true);
        return;
      }

      // Import each entry to local storage
      int importedCount = 0;
      for (final entry in driveEntries) {
        await _diaryBox.add(entry);
        importedCount++;
      }

      _showSnackBar('Successfully imported $importedCount entries from Drive!');
      setState(() {});
    } catch (e) {
      _showSnackBar('Import error: $e', isError: true);
    } finally {
      setState(() {
        _isImporting = false;
      });
    }
  }

  // Show background color picker
  void _showBackgroundColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Background Color'),
        content: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _buildColorOption(Colors.white, 'White'),
            _buildColorOption(Colors.grey[100]!, 'Light Grey'),
            _buildColorOption(Colors.blue[50]!, 'Light Blue'),
            _buildColorOption(Colors.green[50]!, 'Light Green'),
            _buildColorOption(Colors.pink[50]!, 'Light Pink'),
            _buildColorOption(Colors.purple[50]!, 'Light Purple'),
            _buildColorOption(Colors.amber[50]!, 'Light Amber'),
            _buildColorOption(Colors.teal[50]!, 'Light Teal'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Show font color picker
  void _showFontColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Font Color'),
        content: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _buildFontColorOption(Colors.black87, 'Black'),
            _buildFontColorOption(Colors.grey[800]!, 'Dark Grey'),
            _buildFontColorOption(Colors.blueGrey[700]!, 'Blue Grey'),
            _buildFontColorOption(Colors.brown[700]!, 'Brown'),
            _buildFontColorOption(Colors.indigo[700]!, 'Indigo'),
            _buildFontColorOption(Colors.deepPurple[700]!, 'Deep Purple'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Build color option for background
  Widget _buildColorOption(Color color, String name) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _backgroundColor = color;
        });
        Navigator.pop(context);
        _showSnackBar('Background color changed to $name');
      },
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(name, style: TextStyle(fontSize: 10, color: Colors.black54)),
        ),
      ),
    );
  }

  // Build color option for font
  Widget _buildFontColorOption(Color color, String name) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _fontColor = color;
        });
        Navigator.pop(context);
        _showSnackBar('Font color changed to $name');
      },
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(name, style: TextStyle(fontSize: 10, color: Colors.white)),
        ),
      ),
    );
  }
}

