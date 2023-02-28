import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:code_text_field/code_text_field.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart' hide MenuBar hide MenuStyle;
import 'package:flutter/services.dart';
import 'package:flutter_file_view/flutter_file_view.dart';
import 'package:flutter_highlight/themes/mono-blue.dart';
import 'package:highlight/highlight.dart';
import 'package:highlight/languages/java.dart';
import 'package:highlight/languages/dart.dart';
import 'package:highlight/languages/python.dart';
import 'package:highlight/languages/ada.dart';
import 'package:menu_bar/menu_bar.dart';

import 'generated/codegen_loader.g.dart';
import 'generated/locale_keys.g.dart';
import 'package:intl/intl.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  runApp(
    EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('ru')],
        path: 'assets/translations',
        fallbackLocale: const Locale('ru'),
        assetLoader: const CodegenLoader(),
        child: const MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'We are on display',
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
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

Mode langMapper(String lang) {
  switch (lang) {
    case 'dart':
      return dart;
    case 'java':
      return java;
    case 'python':
      return python;
    default:
      return dart;
  }
}

class _HomeState extends State<Home> {
  final TextEditingController controller = TextEditingController();
  Mode mode = ada;

  late final CodeController codeController = CodeController(
    language: mode,
    patternMap: {
      r"\B#[a-zA-Z0-9]+\b": const TextStyle(color: Colors.red),
      r"\B@[a-zA-Z0-9]+\b": const TextStyle(
        fontWeight: FontWeight.w800,
        color: Colors.green,
      ),
      r"\B![a-zA-Z0-9]+\b":
          const TextStyle(color: Colors.yellow, fontStyle: FontStyle.italic),
    },
    stringMap: monoBlueTheme,
    text: controller.text,
  );

  final FocusNode focusNode = FocusNode();
  late FilePickerResult? result;
  File? file;

  bool highlight = false;
  String fileS = '';

  void toggle(Mode val) {
    if (mode == val) {
      highlight = false;
      mode = ada;
    } else {
      highlight = true;
      mode = val;
    }
    codeController.language = mode;
    // codeController.stringMap?.addAll({
    //   "void": TextStyle(color: Colors.red)
    // });
    setState(() {});
  }

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
  }

  Future<void> save() async {
    file!.writeAsStringSync(controller.text);
  }

  Future<void> saveAs() async {
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
                  decoration:
                      InputDecoration(hintText: LocaleKeys.what_to_find.tr()),
                ),
                if (replace)
                  TextFormField(
                    maxLines: null,
                    controller: replacer,
                    decoration: InputDecoration(
                        hintText: LocaleKeys.what_to_replace.tr()),
                  ),
              ],
            ),
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                    replace ? LocaleKeys.replace.tr() : LocaleKeys.find.tr()),
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
          text: Text(LocaleKeys.file.tr()),
          submenu: SubMenu(
            menuItems: [
              MenuButton(
                onTap: () => create(),
                text: Text(LocaleKeys.new_1.tr()),
              ),
              MenuButton(
                onTap: () => open(),
                text: Text(LocaleKeys.open.tr()),
              ),
              MenuButton(
                onTap: () => create(),
                text: Text(LocaleKeys.close.tr()),
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
                text: Text(LocaleKeys.save.tr()),
              ),
              MenuButton(
                onTap: () => saveAs(),
                text: Text(LocaleKeys.save_as.tr()),
              ),
              MenuButton(
                onTap: () => breakApp(),
                text: Text(LocaleKeys.exit.tr()),
              ),
            ],
          ),
        ),
        BarButton(
          text: Text(LocaleKeys.edit.tr()),
          submenu: SubMenu(
            menuItems: [
              MenuButton(
                onTap: () => select(),
                text: Text(LocaleKeys.select_all.tr()),
              ),
              MenuButton(
                onTap: () => cut(),
                text: Text(LocaleKeys.cut.tr()),
              ),
              MenuButton(
                onTap: () => copy(),
                text: Text(LocaleKeys.copy.tr()),
              ),
              MenuButton(
                onTap: () => insert(),
                text: Text(LocaleKeys.paste.tr()),
              ),
            ],
          ),
        ),
        BarButton(
          text: Text(LocaleKeys.view.tr()),
          submenu: SubMenu(
            menuItems: [
              MenuButton(
                onTap: () => open(),
                text: Text(LocaleKeys.font.tr()),
              ),
              MenuButton(
                  onTap: () => open(),
                  text: Text(LocaleKeys.design_theme.tr()),
                  submenu: SubMenu(
                    menuItems: [
                      MenuButton(
                        onTap: () => open(),
                        text: const Text('Шрифт'),
                      ),
                    ],
                  )),
            ],
          ),
        ),
        BarButton(
          text: Text(LocaleKeys.search.tr()),
          submenu: SubMenu(
            menuItems: [
              MenuButton(
                onTap: () => find(),
                text: Text(LocaleKeys.find.tr()),
              ),
              MenuButton(
                onTap: () => find(replace: true),
                text: Text(LocaleKeys.replace.tr()),
              ),
            ],
          ),
        ),
        BarButton(
          text: Text(LocaleKeys.help.tr()),
          submenu: SubMenu(
            menuItems: [
              MenuButton(
                onTap: () => open(),
                text: Text(LocaleKeys.reference.tr()),
              ),
              MenuButton(
                onTap: () => open(),
                text: Text(LocaleKeys.about_program.tr()),
              ),
            ],
          ),
        ),
        BarButton(
          text: const Text('Подсветка кода'),
          submenu: SubMenu(
            menuItems: [
              MenuButton(
                onTap: () => toggle(dart),
                text: Text(
                  'dart',
                  style: TextStyle(
                    fontWeight:
                        mode == dart ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              MenuButton(
                onTap: () => toggle(java),
                text: Text(
                  'java',
                  style: TextStyle(
                    fontWeight:
                        mode == java ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              MenuButton(
                onTap: () => toggle(python),
                text: Text(
                  'python',
                  style: TextStyle(
                    fontWeight:
                        mode == python ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
      child: Scaffold(
        body: Stack(
          children: [
            highlight
                ? SingleChildScrollView(
                    child: CodeTheme(
                      data: const CodeThemeData(styles: monoBlueTheme),
                      child: CodeField(
                        controller: codeController,
                        focusNode: focusNode,
                        maxLines: null,
                        minLines: 1,
                        horizontalScroll: true,
                        isDense: true,
                        textStyle: const TextStyle(fontFamily: 'SourceCode'),
                        onChanged: (str) {
                          controller.text = codeController.text;
                        },
                        background: Colors.white24,
                      ),
                    ),
                  )
                : Container(
                    margin: const EdgeInsets.all(20),
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    child: SingleChildScrollView(
                      child: TextField(
                        controller: controller,
                        textInputAction: TextInputAction.none,
                        maxLines: null,
                        maxLength: null,
                        onChanged: (str) {
                          codeController.text = controller.text;
                        },
                        decoration: const InputDecoration.collapsed(
                          hintText: '',
                        ),
                        autofocus: true,
                        showCursor: true,
                        focusNode: focusNode,
                      ),
                    ),
                  ),
            Align(
                alignment: Alignment.bottomLeft,
                child: ClockWidget(),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: TextButton(
                child: Text(context.locale == Locale('ru') ? 'ru' : 'en'),
                onPressed: () {
                  if (context.locale == Locale('ru')) {
                    context.setLocale(Locale('en'));
                  } else {
                    context.setLocale(Locale('ru'));
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class ClockWidget extends StatelessWidget {
  const ClockWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Stream.periodic(const Duration(seconds: 1)),
      builder: (context, snapshot) {
        return Text(DateFormat('HH:mm:ss').format(DateTime.now()));
      },
    );
  }
}