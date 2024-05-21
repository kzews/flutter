import 'package:flutter/material.dart';
import 'package:fluttersrc/screens/login_page.dart';
import 'package:fluttersrc/screens/registration.dart';
import 'package:fluttersrc/screens/table.dart';
import 'package:fluttersrc/screens/table2.dart';

import 'package:fluttersrc/screens/users_table.dart';
import 'package:page_transition/page_transition.dart';

import '../appBar.dart';
import '../objects/userDto.dart';
import '../services/backButton.dart';
import '../services/login.dart';
import '_myDataGridState.dart';
import 'add_license.dart';

class Home1Page extends StatefulWidget {
  const Home1Page({Key? key, required this.userDto}) : super(key: key);
  final UserDto userDto;

  @override
  _Home1PageState createState() => _Home1PageState();
}

class _Home1PageState extends State<Home1Page> {
  late bool isHovered; // Инициализация переменной в состоянии
  DateTime? currentBackPressTime;

  @override
  void initState() {
    super.initState();
    isHovered =
        false; // Устанавливаем начальное значение при инициализации состояния
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double buttonRadius = screenHeight * 0.1; // 5% ширины экрана
    double bottomPadding =
        MediaQuery.of(context).size.height * 0.05; // 5% высоты экрана
    bool isAdmin = widget.userDto.role == "admin";
    bool isUserOrAdmin = widget.userDto.role == "user" || isAdmin;

    return WillPopScope(
      
      onWillPop: () async {
        return backButton(context);
      },
      child: Scaffold(
        appBar: CustomAppBar(userDto: widget.userDto),
        drawer: AppDrawer(userDto: widget.userDto),
        body: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      isAdmin ? HoverButton(context, Colors.red, Icons.groups_outlined,
                          () {
                        _navigateToPage(context, Colors.red);
                      }): Container(),
                      SizedBox(width: screenWidth * 0.07),
                      isUserOrAdmin ? HoverButton(context, Colors.lightGreen, Icons.add_card,
                          () {
                        _navigateToPage(context, Colors.lightGreen);
                      }): Container(),
                    ],
                  ),
                  SizedBox(height: screenWidth * 0.07),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      HoverButton(context, Colors.blue, Icons.table_chart_sharp,
                          () {
                        _navigateToPage(context, Colors.blue);
                      }),
                      SizedBox(width: screenWidth * 0.07),
                      isAdmin ? HoverButton(
                          context, Colors.yellow, Icons.person_add_alt_rounded,

                          () {
                        _navigateToPage(context, Colors.yellow);
                      }): Container(),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: bottomPadding,
              right: bottomPadding,
              child: HoverButton(context, Colors.orange, Icons.exit_to_app, () {
                _navigateToPage(context, Colors.orange);
              }, buttonRadius),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToPage(BuildContext context, Color color) async {
    if (color == Colors.orange) {
      // Выполнение дополнительной операции при нажатии на кнопку с иконкой выхода
      await storage.delete(key: 'token');
    }
    Widget page = Container();
    if (color == Colors.red) {
      page = UsersPage(userDto: widget.userDto);
    } else if (color == Colors.lightGreen) {
      page = HomePage(userDto: widget.userDto);
    } else if (color == Colors.blue) {
      page = TablePage(userDto: widget.userDto);
    } else if (color == Colors.yellow) {
      page = RegisterPage(userDto: widget.userDto);
    } else if (color == Colors.orange) {
      page = const LoginPage();
    }

    Navigator.of(context).pushReplacement(PageTransition(
      type: PageTransitionType.fade,
      child: page,
    ));
  }
}

class HoverButton extends StatefulWidget {
  final BuildContext context;
  final Color color;
  final IconData icon;
  final VoidCallback onPressed;
  final double? customRadius;

  const HoverButton(this.context, this.color, this.icon, this.onPressed,
      [this.customRadius]);

  @override
  _HoverButtonState createState() => _HoverButtonState();
}

class _HoverButtonState extends State<HoverButton> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    double buttonRadius = widget.customRadius ??
        (MediaQuery.of(widget.context).size.height * 0.2);
    double hoveredRadius = buttonRadius * 1.1;

    return MouseRegion(
      onEnter: (_) {
        setState(() {
          isHovered = true;
        });
      },
      onExit: (_) {
        setState(() {
          isHovered = false;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: isHovered ? hoveredRadius : buttonRadius,
        height: isHovered ? hoveredRadius : buttonRadius,
        decoration: ShapeDecoration(
          color: widget.color,
          shape: const CircleBorder(),
        ),
        child: IconButton(
          icon: Icon(widget.icon),
          color: Colors.white,
          iconSize: buttonRadius * 0.5,
          onPressed: widget.onPressed,
        ),
      ),
    );
  }
}
