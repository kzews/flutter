import 'package:flutter/material.dart';
import 'package:fluttersrc/screens/add_license.dart';
import 'package:fluttersrc/screens/registration.dart';
import 'package:fluttersrc/screens/table.dart';
import 'package:fluttersrc/screens/test_page.dart';
import 'package:fluttersrc/screens/users_table.dart';
import 'package:page_transition/page_transition.dart';

import 'objects/userDto.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final UserDto userDto;

  CustomAppBar({Key? key, required this.userDto}) : super(key: key);

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('Flutter Database App'),
      leading: Builder(
        builder: (BuildContext context) {
          return IconButton(
            icon: Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          );
        },
      ),
      actions: <Widget>[
        IconButton(
          icon: Icon(Icons.home),
          onPressed: () {
            Navigator.of(context).pushReplacement(PageTransition(
              type: PageTransitionType.leftToRight,
              child: Home1Page(userDto: userDto),
            ));
          },
        ),
        // Добавьте другие иконки действий, если необходимо
      ],
    );
  }
}

class AppDrawer extends StatelessWidget {
  final UserDto userDto;

  AppDrawer({required this.userDto});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.black,
            ),
            child: Text(
              'Меню',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            title: Text('Главная'),
            onTap: () {
              Navigator.of(context).pushReplacement(PageTransition(
                type: PageTransitionType.leftToRight,
                child: Home1Page(userDto: userDto),
              ));
            },
          ),
          ListTile(
            title: Text('Пользователи'),
            onTap: () {
              Navigator.of(context).pushReplacement(PageTransition(
                type: PageTransitionType.leftToRight,
                child: UsersPage(userDto: userDto),
              ));
            },
          ),
          ListTile(
            title: Text('Добавить пользователя'),
            onTap: () {
              Navigator.of(context).pushReplacement(PageTransition(
                type: PageTransitionType.leftToRight,
                child: RegisterPage(userDto: userDto),
              ));
            },
          ),
          ListTile(
            title: Text('Лицензии'),
            onTap: () {
              Navigator.of(context).pushReplacement(PageTransition(
                type: PageTransitionType.leftToRight,
                child: TablePage(userDto: userDto),
              ));
            },
          ),
          ListTile(
            title: Text('Добавить лицензию'),
            onTap: () {
              Navigator.of(context).pushReplacement(PageTransition(
                type: PageTransitionType.leftToRight,
                child: HomePage(userDto: userDto),
              ));
            },
          ),
        ],
      ),
    );
  }
}
