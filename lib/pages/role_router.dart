import 'package:flutter/material.dart';
import '../models/app_user.dart';
import 'admin/admin_home_page.dart';
import 'home_page.dart';

Widget homeForUser(AppUser user) {
  if (user.isAdmin) return const AdminHomePage();
  return const HomePage();
}