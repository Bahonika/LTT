import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart' hide MenuBar hide MenuStyle;
import 'package:flutter/services.dart';
import 'package:flutter_file_view/flutter_file_view.dart';
import 'package:menu_bar/menu_bar.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'We are on display',
      theme: ThemeData(
        primarySwatch: Colors.purple,
      ),
      debugShowCheckedModeBanner: false,
      home: const Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final TextEditingController controller = TextEditingController();
  final FocusNode focusNode = FocusNode();
  late FilePickerResult? result;
  File? file;

  String fileS = '';

  @override
  void initState() {
    super.initState();
    FlutterFileView.init();
  }

  void create() {
    controller.text = '';
    file = null;
  }

  Future<void> open() async {
    this.result = await FilePicker.platform.pickFiles();
    final result = this.result;

    if (result != null) {
      file = File(result.files.first.path ?? '');
      controller.text = file!.readAsStringSync();
    }
    print(file?.path);
  }

  Future<void> save() async {
    print(file?.path);
    file!.writeAsStringSync(controller.text);
  }

  Future<void> saveAs() async {
    print(this.file?.path);
    final file = this.file;
    final temp = await FilePicker.platform.saveFile(
      initialDirectory: file?.path,
      allowedExtensions: ['.txt'],
    );
    if (temp != null) {
      final tempFile = file?.copySync(temp) ?? File(temp);
      tempFile.writeAsStringSync(controller.text);
      this.file = tempFile;
    }
  }

  void breakApp() {
    exit(0);
  }

  Future<void> find({
    bool replace = false,
  }) async {
    final finder = TextEditingController();
    final replacer = TextEditingController();
    await showDialog(
        context: context,
        builder: (context) {
          return SimpleDialog(
            contentPadding: const EdgeInsets.all(8),
            insetPadding: const EdgeInsets.all(8),
            title: Column(
              children: [
                TextFormField(
                  maxLines: null,
                  controller: finder,
                  decoration: const InputDecoration(hintText: 'Что найти?'),
                ),
                if (replace)
                  TextFormField(
                    maxLines: null,
                    controller: replacer,
                    decoration:
                        const InputDecoration(hintText: 'На что заменить?'),
                  ),
              ],
            ),
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(replace ? 'Заменить' : 'Найти'),
              ),
            ],
          );
        });
    final text = controller.text.substring(controller.selection.end);
    int offset = text.indexOf(finder.text) + controller.selection.end;
    if (replace) {
      offset += (replacer.text.length);
    } else {
      offset += (finder.text.length);
    }
    if (text.contains(finder.text)) {
      if (replace) {
        controller.text =
            controller.text.substring(0, controller.selection.end) +
                text.replaceFirst(finder.text, replacer.text);
      }

      controller.selection = TextSelection.fromPosition(
        TextPosition(
          offset: offset,
        ),
      );
    }
    focusNode.requestFocus();
  }

  Future<void> insert() async {
    final offset = controller.selection.start;
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final inserted = data?.text ?? '';
    final split = controller.text.split('');
    split.insert(controller.selection.start, inserted);
    controller.text = split.join();
    controller.selection = TextSelection.fromPosition(
      TextPosition(
        offset: offset + inserted.length,
      ),
    );
    focusNode.requestFocus();
  }

  void copy() {
    focusNode.requestFocus();
    Clipboard.setData(
      ClipboardData(
        text: controller.text.substring(
          controller.selection.start,
          controller.selection.end,
        ),
      ),
    );
  }

  void cut() {
    copy();
    final start = controller.selection.start;
    final end = controller.selection.end;
    controller.text = controller.text.substring(0, start) +
        controller.text.substring(end, controller.text.length);
    controller.selection =
        TextSelection.fromPosition(TextPosition(offset: start));
    focusNode.requestFocus();
  }

  void select() {
    controller.selection =
        TextSelection(baseOffset: 0, extentOffset: controller.text.length);
    focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return MenuBar(
      menuStyle: const MenuStyle(
        backgroundColor: Colors.white,
      ),
      barStyle: const BarStyle(
        backgroundColor: Colors.white,
      ),
      barButtons: [
        BarButton(
          text: const Text('Файл'),
          submenu: SubMenu(
            menuItems: [
              MenuButton(
                onTap: () => create(),
                text: const Text('Новый'),
              ),
              MenuButton(
                onTap: () => open(),
                text: const Text('Открыть'),
              ),
              MenuButton(
                onTap: () => create(),
                text: const Text('Закрыть'),
              ),
              MenuButton(
                onTap: () {
                  print(file?.path);
                   if (file != null) {
                     save();
                   } else {
                     saveAs();
                   }
                },
                text: const Text('Сохранить'),
              ),
              MenuButton(
                onTap: () => saveAs(),
                text: const Text('Сохранить как'),
              ),
              MenuButton(
                onTap: () => breakApp(),
                text: const Text('Выход'),
              ),
            ],
          ),
        ),
        BarButton(
          text: const Text('Правка'),
          submenu: SubMenu(
            menuItems: [
              MenuButton(
                onTap: () => select(),
                text: const Text('Выделить все'),
              ),
              MenuButton(
                onTap: () => cut(),
                text: const Text('Вырезать'),
              ),
              MenuButton(
                onTap: () => copy(),
                text: const Text('Копировать'),
              ),
              MenuButton(
                onTap: () => insert(),
                text: const Text('Вставить'),
              ),
            ],
          ),
        ),
        BarButton(
          text: const Text('Вид'),
          submenu: SubMenu(
            menuItems: [
              MenuButton(
                onTap: () => open(),
                text: const Text('Шрифт'),
              ),
              MenuButton(
                onTap: () => open(),
                text: const Text('Тема оформления'),
              ),
            ],
          ),
        ),
        BarButton(
          text: const Text('Поиск'),
          submenu: SubMenu(
            menuItems: [
              MenuButton(
                onTap: () => find(),
                text: const Text('Найти'),
              ),
              MenuButton(
                onTap: () => find(replace: true),
                text: const Text('Заменить'),
              ),
            ],
          ),
        ),
        BarButton(
          text: const Text('Справка'),
          submenu: SubMenu(
            menuItems: [
              MenuButton(
                onTap: () => open(),
                text: const Text('Справка'),
              ),
              MenuButton(
                onTap: () => open(),
                text: const Text('О программе'),
              ),
            ],
          ),
        ),
      ],
      child: Scaffold(
        body: Container(
          margin: const EdgeInsets.all(20),
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: TextField(
            controller: controller,
            textInputAction: TextInputAction.none,
            maxLines: null,
            minLines: 1,
            decoration: const InputDecoration.collapsed(
              hintText: '',
            ),
            autofocus: true,
            showCursor: true,
            focusNode: focusNode,
          ),
        ),
      ),
    );
  }
}
