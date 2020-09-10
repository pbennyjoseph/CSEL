import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FavoriteLinksModel extends ChangeNotifier {
  final Set<String> favorite = Set<String>();

  void add(String x, String userId) {
    favorite.add(x);
    Firestore.instance.collection('CSEL_users').document(userId).updateData({
      'favLinks': FieldValue.arrayUnion([x]),
    });
    notifyListeners();
  }

  void remove(String x, String userId) {
    favorite.remove(x);
    Firestore.instance.collection('CSEL_users').document(userId).updateData({
      'favLinks': FieldValue.arrayRemove([x]),
    });
    notifyListeners();
  }

  bool contains(String x) {
    return favorite.contains(x);
  }

  bool syncOnline(String userId) {
    return true;
    List<dynamic> mylist = favorite.toList();
    try {
      Firestore.instance
          .collection('CSEL_users')
          .document(userId)
          .updateData({'favLinks': mylist});
      return true;
    } catch (err) {
      print('err');
      return false;
    }
  }
}
