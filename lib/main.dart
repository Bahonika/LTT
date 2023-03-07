import 'dart:convert';
import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:code_text_field/code_text_field.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart' hide MenuBar hide MenuStyle;
import 'package:flutter/services.dart';
import 'package:flutter_file_view/flutter_file_view.dart';
import 'package:flutter_highlight/themes/mono-blue.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:highlight/highlight.dart';
import 'package:highlight/languages/java.dart';
import 'package:highlight/languages/dart.dart';
import 'package:highlight/languages/python.dart';
import 'package:highlight/languages/ada.dart';
import 'package:menu_bar/menu_bar.dart';
import 'package:wrod/custom_theme.dart';
import 'package:wrod/font_provider.dart';
import 'package:wrod/theme_provider.dart';

import 'config.dart';
import 'generated/codegen_loader.g.dart';
import 'generated/locale_keys.g.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  runApp(
    EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('ru')],
        path: 'assets/translations',
        fallbackLocale: const Locale('ru'),
        assetLoader: const CodegenLoader(),
        child: const ProviderScope(child: MyApp())),
  );
  if (!Platform.isAndroid && !Platform.isLinux) {
    doWhenWindowReady(() {
      final win = appWindow;
      const initialSize = Size(1000, 700);
      win.minSize = initialSize;
      win.size = initialSize;
      win.alignment = Alignment.center;
      win.title = "Custom window with Flutter";
      win.show();
    });
  }
}

class WindowWrapper extends StatelessWidget {
  const WindowWrapper({
    Key? key,
    required this.child,
  }) : super(key: key);
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

ThemeData themeData = CustomTheme.lightTheme;

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    currentTheme.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'We are on display',
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: ref.watch(themeProvider),
      themeMode: currentTheme.currentTheme,
      debugShowCheckedModeBanner: false,
      home: Platform.isAndroid || Platform.isLinux
          ? const Home()
          : WindowTitleBarBox(child: const Home()),
    );
  }
}

class Home extends ConsumerStatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  ConsumerState<Home> createState() => _HomeState();
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

class _HomeState extends ConsumerState<Home> {
  final TextEditingController controller = TextEditingController();
  Mode mode = ada;
  int rowNumber = 0;

  void listen() {
    rowNumber = '\n'
            .allMatches(
              controller.text.substring(
                0,
                controller.selection.baseOffset >= 0
                    ? controller.selection.baseOffset
                    : 0,
              ),
            )
            .length +
        1;
    setState(() {});
  }

  void codeListen() {
    rowNumber = '\n'
            .allMatches(
              codeController.text.substring(
                0,
                codeController.selection.baseOffset >= 0
                    ? codeController.selection.baseOffset
                    : 0,
              ),
            )
            .length +
        1;
    setState(() {});
  }

  late final CodeController codeController;

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
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    controller.addListener(listen);
    codeController = CodeController(
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

    codeController.addListener(codeListen);

    FlutterFileView.init();
  }

  @override
  void dispose() {
    controller.removeListener(listen);
    super.dispose();
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
    if (Platform.isAndroid) {
      final list = utf8.encode(controller.text);
      final bytes = Uint8List.fromList(list);
      final file = this.file;
      final name = file!.path.substring(
        file.path.lastIndexOf('/') + 1,
      );
      final temp = await FileSaver.instance.saveAs(
        name,
        bytes,
        'txt',
        MimeType.TEXT,
      );
    } else {
      file!.writeAsStringSync(controller.text);
    }
  }

  Future<void> saveAs() async {
    if (Platform.isAndroid) {
      final list = utf8.encode(controller.text);
      final bytes = Uint8List.fromList(list);
      final temp = await FileSaver.instance.saveAs(
        DateTime.now().toString(),
        bytes,
        'txt',
        MimeType.TEXT,
      );
    } else {
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
  }

  void breakApp() {
    exit(0);
  }

  void openHelp() {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => const SecondScreen()));
  }

  void openAbout() {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => const ThirdScreen()));
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
    return Column(
      children: [
        if (Platform.isAndroid || Platform.isLinux)
          Platform.isAndroid
              ? AppBar(
                  backgroundColor: Theme.of(context).primaryColor,
                  title: const Text('We are on display'),
                )
              : Platform.isLinux
                  ? SizedBox()
                  : Container(
                      color: Theme.of(context).primaryColor,
                      height: 30,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                              child: MoveWindow(
                            child: Material(
                              color: Colors.transparent,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const SizedBox(width: 5),
                                  Icon(
                                    Icons.edit_note_rounded,
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.color,
                                  ),
                                  const Text(
                                    'We Are On Display',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )),
                          MinimizeWindowButton(
                            colors: WindowButtonColors(
                              mouseDown: Colors.black26,
                              mouseOver: Colors.black12,
                            ),
                          ),
                          MaximizeWindowButton(
                            colors: WindowButtonColors(
                              mouseDown: Colors.black26,
                              mouseOver: Colors.black12,
                            ),
                          ),
                          CloseWindowButton(
                            colors: WindowButtonColors(
                              mouseDown: Colors.red.withOpacity(0.7),
                              mouseOver: Colors.red.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
        Expanded(
          child: MenuBar(
            menuStyle: MenuStyle(
              backgroundColor: Theme.of(context).primaryColor,
            ),
            barStyle: BarStyle(
              backgroundColor: Theme.of(context).primaryColor,
            ),
            barButtonStyle: BarButtonStyle(
              backgroundColor: Theme.of(context).primaryColor,
            ),
            menuButtonStyle: MenuButtonStyle(
              backgroundColor: Theme.of(context).primaryColor,
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
                      onTap: () => null,
                      text: Text(LocaleKeys.font.tr()),
                      submenu: SubMenu(
                        menuItems: [
                          MenuButton(
                              onTap: () {
                                ref
                                    .read(fontProvider.notifier)
                                    .setNew('Montserrat');
                              },
                              text: const Text('montserrat')),
                          MenuButton(
                              onTap: () {
                                ref
                                    .read(fontProvider.notifier)
                                    .setNew('Raleway');
                              },
                              text: const Text('raleway')),
                          MenuButton(
                              onTap: () {
                                ref
                                    .read(fontProvider.notifier)
                                    .setNew('RobotoMono');
                              },
                              text: const Text('roboto_mono')),
                          MenuButton(
                              onTap: () {
                                ref
                                    .read(fontProvider.notifier)
                                    .setNew('TimesNewRoman');
                              },
                              text: const Text('times_new_roman')),
                        ],
                      ),
                    ),
                    MenuButton(
                        onTap: () => null,
                        text: Text(LocaleKeys.design_theme.tr()),
                        submenu: SubMenu(
                          menuItems: [
                            MenuButton(
                                onTap: () {
                                  ref.read(themeProvider.notifier).setLight();
                                },
                                text: Text(LocaleKeys.light_theme.tr())),
                            MenuButton(
                                onTap: () {
                                  ref.read(themeProvider.notifier).setDark();
                                },
                                text: Text(LocaleKeys.dark_theme.tr())),
                            MenuButton(
                                onTap: () {
                                  ref.read(themeProvider.notifier).setWarm();
                                },
                                text: Text(LocaleKeys.warm_theme.tr())),
                          ],
                        ))
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
                      onTap: () => openHelp(),
                      text: Text(LocaleKeys.reference.tr()),
                    ),
                    MenuButton(
                      onTap: () => openAbout(),
                      text: Text(LocaleKeys.about_program.tr()),
                    ),
                  ],
                ),
              ),
              BarButton(
                text: Text(LocaleKeys.syntax_highlighter.tr()),
                submenu: SubMenu(
                  menuItems: [
                    MenuButton(
                      onTap: () => toggle(dart),
                      text: Text(
                        'dart',
                        style: TextStyle(
                          fontWeight: mode == dart
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    MenuButton(
                      onTap: () => toggle(java),
                      text: Text(
                        'java',
                        style: TextStyle(
                          fontWeight: mode == java
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    MenuButton(
                      onTap: () => toggle(python),
                      text: Text(
                        'python',
                        style: TextStyle(
                          fontWeight: mode == python
                              ? FontWeight.bold
                              : FontWeight.normal,
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
                              textStyle: TextStyle(
                                fontFamily: ref.watch(fontProvider),
                              ),
                              isDense: true,
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
                              style: TextStyle(
                                fontFamily: ref.watch(fontProvider),
                              ),
                              onChanged: (str) {
                                codeController.text = controller.text;
                              },
                              decoration: InputDecoration.collapsed(
                                hintText: '',
                                fillColor:
                                    Theme.of(context).scaffoldBackgroundColor,
                              ),
                              autofocus: true,
                              showCursor: true,
                              focusNode: focusNode,
                            ),
                          ),
                        ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(LocaleKeys.current_row.tr()),
                        Text(
                          '$rowNumber',
                        ),
                        const SizedBox(
                          width: 20,
                        ),
                        const ClockWidget(),
                        TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor:
                                Theme.of(context).primaryColor, // Text Color
                          ),
                          child: Text(context.locale == const Locale('ru')
                              ? 'ru'
                              : 'en'),
                          onPressed: () {
                            if (context.locale == const Locale('ru')) {
                              context.setLocale(const Locale('en'));
                            } else {
                              context.setLocale(const Locale('ru'));
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
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

class SecondScreen extends StatelessWidget {
  const SecondScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(LocaleKeys.reference.tr())),
      body: Center(child: Text(LocaleKeys.reference_text.tr())),
    );
  }
}

class ThirdScreen extends StatelessWidget {
  const ThirdScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(LocaleKeys.about_program.tr())),
      body: Center(child: Text(LocaleKeys.about_program_text.tr())),
    );
  }
}
