
import 'package:flutter/material.dart';
import 'package:fluttersrc/screens/add_license.dart';
import 'package:fluttersrc/screens/login_page.dart';
import 'package:fluttersrc/screens/registration.dart';
import 'package:fluttersrc/screens/table.dart';
import 'package:fluttersrc/screens/routes_page.dart';
import 'package:fluttersrc/screens/table2.dart';
import 'package:fluttersrc/screens/users_table.dart';
import 'package:fluttersrc/services/changeUser.dart';
import 'package:fluttersrc/services/login.dart';
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
            color: Colors.white,
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          );
        },
      ),
      actions: <Widget>[
        IconButton(
          color: Colors.white,
          icon: const Icon(Icons.home),
          onPressed: () {
            Navigator.of(context).pushReplacement(PageTransition(
              type: PageTransitionType.leftToRight,
              child: Home1Page(userDto: userDto),
            ));
          },
        ),
        IconButton(
          color: Colors.white,
          icon: const Icon(Icons.exit_to_app),
          onPressed: () async {
            // Удаление токена из хранилища
            await storage.delete(key: 'token');

            // Переход на страницу входа
            Navigator.of(context).pushReplacement(PageTransition(
              type: PageTransitionType.leftToRight,
              child: const LoginPage(),
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

  void _showUserDetailsDialog(BuildContext context, UserDto userDto) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          scrollable: true,
          // insetPadding: EdgeInsets.all(400),
          title: const Text('Данные о пользователе'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Логин: ${userDto.login}'),
              Text('Роль: ${userDto.role}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showEditDialog(context);
              },
              child: const Text('Изменить'),
            ),
          ],
        );
      },
    );
  }

  void
  _showEditDialog(BuildContext context) {
    String newLogin = '';
    String newPassword = '';
    // String confirmPassword = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          insetPadding: const EdgeInsets.all(350),
          title: const Text('Изменить данные'),
          content: Column(
            children: [
              TextField(
                onChanged: (value) {
                  newLogin = value;
                },
                decoration: const InputDecoration(labelText: 'Новый логин'),
              ),
              TextField(
                onChanged: (value) {
                  newPassword = value;
                },
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Новый пароль'),
              ),
              //TODO: проверка правильного ввода нового пароля
              // TextField(
              //   onChanged: (value) {
              //     confirmPassword = value;
              //   },
              //   obscureText: true,
              //   decoration: InputDecoration(labelText: 'Подтвердите новый пароль'),
              // ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                changeUser(userDto.id, newLogin, newPassword);
                print('changed user');
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  PageTransition(
                    type: PageTransitionType.leftToRight,
                    child: const LoginPage(),
                  ),
                );
              },
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isAdmin = userDto.role == "admin";
    bool isUserOrAdmin = userDto.role == "user" || isAdmin;
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
          isUserOrAdmin ? ListTile(
            title: const Text('Главная'),
            onTap: () {
              Navigator.of(context).pushReplacement(PageTransition(
                type: PageTransitionType.leftToRight,
                child: Home1Page(userDto: userDto),
              ));
            },
          ): Container(),
          isAdmin ? ListTile(
            title: const Text('Пользователи'),
            onTap: () {
              Navigator.of(context).pushReplacement(PageTransition(
                type: PageTransitionType.leftToRight,
                child: UsersPage(userDto: userDto),
              ));
            },
          ): Container(),
          isAdmin ? ListTile(
            title: const Text('Добавить пользователя'),
            onTap: () {
              Navigator.of(context).pushReplacement(PageTransition(
                type: PageTransitionType.leftToRight,
                child: RegisterPage(userDto: userDto),
              ));
            },
          ): Container(),
          ListTile(
            title: const Text('Лицензии'),
            onTap: () {
              Navigator.of(context).pushReplacement(PageTransition(
                type: PageTransitionType.leftToRight,
                child: TablePage(userDto: userDto),
              ));
            },
          ),
          isUserOrAdmin ? ListTile(
            title: const Text('Добавить лицензию'),
            onTap: () {
              Navigator.of(context).pushReplacement(PageTransition(
                type: PageTransitionType.leftToRight,
                child: HomePage(userDto: userDto),
              ));
            },
          ): Container(),
          ListTile(
            title: const Text('Данные о пользователе'),
            onTap: () {
              _showUserDetailsDialog(context, userDto);
            },
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Логин: ${userDto.login}'),
                Text('Роль: ${userDto.role}'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
