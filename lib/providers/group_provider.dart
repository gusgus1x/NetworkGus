import 'package:flutter/material.dart';
import '../models/group_model.dart';
import '../services/group_service.dart';

class GroupProvider extends ChangeNotifier {
  List<Group> _groups = [];
  bool _isLoading = false;

  List<Group> get groups => _groups;
  bool get isLoading => _isLoading;

  Future<void> fetchGroups() async {
    _isLoading = true;
    notifyListeners();
    _groups = await GroupService().getGroups();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> createGroup(Group group) async {
    await GroupService().createGroup(group);
    await fetchGroups();
  }

  Future<void> joinGroup(String groupId, String userId) async {
    await GroupService().joinGroup(groupId, userId);
    await fetchGroups();
  }

  Future<void> leaveGroup(String groupId, String userId) async {
    await GroupService().leaveGroup(groupId, userId);
    await fetchGroups();
  }

  Future<void> deleteGroup(String groupId) async {
    await GroupService().deleteGroup(groupId);
    await fetchGroups();
  }
}
