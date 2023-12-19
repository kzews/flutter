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

  const CustomAppBar({Key? key, required this.userDto}) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('Flutter Database App'),
      leading: Builder(
        builder: (BuildContext context) {
          return IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          );
        },
      ),
      actions: <Widget>[
        IconButton(
          icon: const Icon(Icons.home),
          onPressed: () {
            Navigator.of(context).pushReplacement(PageTransition(
              type: PageTransitionType.leftToRight,
              child: Home1Page(userDto: userDto),
            ));
          },
        ),
      ],
    );
  }
}

class AppDrawer extends StatelessWidget {
  final UserDto userDto;

  const AppDrawer({super.key, required this.userDto});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          const DrawerHeader(
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
            title: const Text('Главная'),
            onTap: () {
              Navigator.of(context).pushReplacement(PageTransition(
                type: PageTransitionType.leftToRight,
                child: Home1Page(userDto: userDto),
              ));
            },
          ),
          ListTile(
            title: const Text('Пользователи'),
            onTap: () {
              Navigator.of(context).pushReplacement(PageTransition(
                type: PageTransitionType.leftToRight,
                child: UsersPage(userDto: userDto),
              ));
            },
          ),
          ListTile(
            title: const Text('Добавить пользователя'),
            onTap: () {
              Navigator.of(context).pushReplacement(PageTransition(
                type: PageTransitionType.leftToRight,
                child: RegisterPage(userDto: userDto),
              ));
            },
          ),
          ListTile(
            title: const Text('Лицензии'),
            onTap: () {
              Navigator.of(context).pushReplacement(PageTransition(
                type: PageTransitionType.leftToRight,
                child: TablePage(userDto: userDto),
              ));
            },
          ),
          ListTile(
            title: const Text('Добавить лицензию'),
            onTap: () {
              Navigator.of(context).pushReplacement(PageTransition(
                type: PageTransitionType.leftToRight,
                child: HomePage(userDto: userDto),
              ));
            },
          ),
          ListTile(
            title: const Text('Данные о пользователе'),

            onTap: () {
              Navigator.of(context).pushReplacement(PageTransition(
                type: PageTransitionType.leftToRight,
                child: HomePage(userDto: userDto),
              ));
            },
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Логин: ${userDto.login}'),
                Text('Пароль: ${userDto.password}'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
