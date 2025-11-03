import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yourleague/User/services/notification_service.dart';
import 'package:yourleague/User/models/notification_model.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> with TickerProviderStateMixin {
  late TabController _tabController;
  List<NotificationModel> _allNotifications = [];
  List<NotificationModel> _todayNotifications = [];
  List<NotificationModel> _pendingNotifications = [];
  bool _isLoading = true;
  bool _notificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadNotifications();
    _checkNotificationPermissions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    
    try {
      final allNotifications = await NotificationService.instance.getAllNotifications();
      final todayNotifications = await NotificationService.instance.getTodayNotifications();
      final pendingNotifications = await NotificationService.instance.getPendingNotifications();
      
      setState(() {
        _allNotifications = allNotifications;
        _todayNotifications = todayNotifications;
        _pendingNotifications = pendingNotifications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement: $e')),
        );
      }
    }
  }

  Future<void> _checkNotificationPermissions() async {
    final enabled = await NotificationService.instance.areNotificationsEnabled();
    setState(() => _notificationsEnabled = enabled);
  }

  Future<void> _clearAllNotifications() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer toutes les notifications'),
        content: const Text('Êtes-vous sûr de vouloir supprimer toutes les notifications ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await NotificationService.instance.clearAllNotifications();
      await _loadNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Toutes les notifications ont été supprimées')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              text: 'Toutes',
              icon: Badge(
                label: Text('${_allNotifications.length}'),
                child: const Icon(Icons.notifications),
              ),
            ),
            Tab(
              text: 'Aujourd\'hui',
              icon: Badge(
                label: Text('${_todayNotifications.length}'),
                child: const Icon(Icons.today),
              ),
            ),
            Tab(
              text: 'En attente',
              icon: Badge(
                label: Text('${_pendingNotifications.length}'),
                child: const Icon(Icons.schedule),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotifications,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'clear':
                  _clearAllNotifications();
                  break;
                case 'settings':
                  NotificationService.instance.openNotificationSettings();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear',
                child: ListTile(
                  leading: Icon(Icons.clear_all),
                  title: Text('Supprimer toutes'),
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Paramètres'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (!_notificationsEnabled)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.orange.shade100,
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.orange),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Les notifications sont désactivées. Activez-les dans les paramètres.',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
                  TextButton(
                    onPressed: () => NotificationService.instance.openNotificationSettings(),
                    child: const Text('Paramètres'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildNotificationsList(_allNotifications),
                      _buildNotificationsList(_todayNotifications),
                      _buildNotificationsList(_pendingNotifications),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(List<NotificationModel> notifications) {
    if (notifications.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Aucune notification',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return _buildNotificationTile(notification);
        },
      ),
    );
  }

  Widget _buildNotificationTile(NotificationModel notification) {
    final isScheduled = notification.scheduledTime.isAfter(DateTime.now());
    final isPast = notification.scheduledTime.isBefore(DateTime.now());
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isScheduled 
              ? Colors.blue.shade100 
              : isPast 
                  ? Colors.grey.shade100 
                  : Colors.green.shade100,
          child: Text(
            notification.type.icon,
            style: const TextStyle(fontSize: 20),
          ),
        ),
        title: Text(
          notification.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.body),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.sports_soccer,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    notification.matchTitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  'Programmé: ${DateFormat('dd/MM/yyyy HH:mm').format(notification.scheduledTime)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isScheduled)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Programmé',
                  style: TextStyle(fontSize: 10, color: Colors.blue),
                ),
              )
            else if (notification.isDelivered)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Livré',
                  style: TextStyle(fontSize: 10, color: Colors.green),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Passé',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ),
            const SizedBox(height: 4),
            Text(
              DateFormat('HH:mm').format(notification.createdAt),
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        onTap: () => _showNotificationDetails(notification),
      ),
    );
  }

  void _showNotificationDetails(NotificationModel notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Match: ${notification.matchTitle}'),
            const SizedBox(height: 8),
            Text('Message: ${notification.body}'),
            const SizedBox(height: 8),
            Text('Créé le: ${DateFormat('dd/MM/yyyy à HH:mm').format(notification.createdAt)}'),
            const SizedBox(height: 8),
            Text('Programmé pour: ${DateFormat('dd/MM/yyyy à HH:mm').format(notification.scheduledTime)}'),
            const SizedBox(height: 8),
            Text('Type: ${notification.type.displayName}'),
            const SizedBox(height: 8),
            Text('Statut: ${notification.isDelivered ? 'Livré' : 'En attente'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}