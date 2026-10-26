import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mobizapp/DashBoardScreen.dart';
import 'package:mobizapp/Pages/store/StorePage.dart';
import 'package:shimmer/shimmer.dart';

import '../Models/appstate.dart';
import '../confg/appconfig.dart';
import 'homepage.dart';
import 'homepage_Driver.dart';

class ErrorHandlingScreen extends StatefulWidget {
  static const routeName = "/ErrorHandlingScreen";

  const ErrorHandlingScreen({super.key});

  @override
  State<ErrorHandlingScreen> createState() => _ErrorHandlingScreenState();
}

class _ErrorHandlingScreenState extends State<ErrorHandlingScreen> {
  late Future<void> _loadRole;

  @override
  void initState() {
    super.initState();
  //  AppState().rolId = 7;
    print("Role : ${AppState().rolId}");
    print("Login : ${AppState().loginState}");
    _loadRole = _getRoleId();
  }

  Future<void> _getRoleId() async {
    await Future.delayed(Duration(seconds: 3)); // Simulate loading delay
    while (AppState().rolId == null) {
      await Future.delayed(Duration(milliseconds: 100));
    }
  }

  void _navigateBasedOnRole() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (AppState().rolId == 2 ||
          AppState().rolId == 5 ||
          AppState().rolId == 29) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
        }
      } else if (AppState().rolId == 3) {
        if (mounted) {
          Navigator.of(context)
              .pushReplacementNamed(TransferOptionsPage.routeName);
        }
      } else if (AppState().rolId == 4) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(HomepageDriver.routeName);
        }
      } else if (AppState().rolId == 7) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(DashboardScreen.routeName);
        }
      } else {
        print("Unhandled Role: ${AppState().rolId}");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FutureBuilder<void>(
          future: _loadRole,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingScreen();
            } else {
              _navigateBasedOnRole();
              return Container(); // Empty container as the screen will navigate away
            }
          },
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          children: [
            // ─────────────────────────────────────
            // TOP HEADER SKELETON
            // ─────────────────────────────────────
            Container(
              width: double.infinity,
              height: 90,
              color: Colors.white,
            ),

            const SizedBox(height: 22),

            // ─────────────────────────────────────
            // SMALL SUMMARY CARD SKELETON
            // ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Container(
                height: 70,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ─────────────────────────────────────
            // 4 COLUMN MENU SKELETON
            // ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 12,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.90,
                ),
                itemBuilder: (_, __) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
