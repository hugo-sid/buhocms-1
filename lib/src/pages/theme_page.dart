import 'dart:io';

import 'package:buhocms/src/utils/globals.dart';
import 'package:buhocms/src/utils/preferences.dart';
import 'package:buhocms/src/utils/program_installed.dart';
import 'package:buhocms/src/widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../i18n/l10n.dart';
import '../provider/navigation/navigation_provider.dart';
import '../ssg/hugo.dart';
import '../ssg/ssg.dart';
import '../ssg/themes.dart';
import '../utils/terminal_command.dart';

class ThemePage extends StatefulWidget {
  const ThemePage({super.key});

  @override
  State<ThemePage> createState() => _ThemePageState();
}

class _ThemePageState extends State<ThemePage> {
  TextStyle style = const TextStyle(fontSize: 20, fontWeight: FontWeight.bold);
  TextStyle smallerStyle = const TextStyle(fontSize: 16);

  int currentStep = 0;
  bool canContinue = false;
  bool? gitInstalled;
  String gitInstalledText = '';

  String themeName = '';
  bool themeNameError = false;

  bool isDownloading = false;

  void _download() async {
    final theme = themeName.split('/').last;
    final path = 'themes${Platform.pathSeparator}$theme';

    if (themeName.isEmpty) {
      setState(() => themeNameError = true);
      return;
    }
    if (Directory('${Preferences.getSitePath()}${Platform.pathSeparator}$path')
        .existsSync()) {
      showSnackbar(
        text:
            Localization.appLocalizations().error_ThemeAlreadyExists(themeName),
        seconds: 4,
      );
      return;
    }

    final validURL = Uri.tryParse(themeName)?.hasAbsolutePath ?? false;
    if (!validURL) {
      setState(() {
        themeNameError = true;
      });
      return;
    } else {
      setState(() {
        themeNameError = false;
      });
    }

    setState(() => isDownloading = true);
    const executable = 'git';
    final flags = 'clone $themeName $path --depth=1';

    await runTerminalCommand(
      context: context,
      workingDirectory: Preferences.getSitePath(),
      executable: executable,
      flags: flags.split(' '),
    );
    setState(() => isDownloading = false);

    await Hugo.setHugoTheme(theme);

    setState(() => currentStep++);

    if (mounted) {
      Provider.of<NavigationProvider>(context, listen: false)
          .notifyAllListeners();
    }
    //git clone https://github.com/adityatelange/hugo-PaperMod themes/PaperMod --depth=1
    //git submodule add --depth=1 https://github.com/adityatelange/hugo-PaperMod.git themes/PaperMod
    //git submodule add https://github.com/luizdepra/hugo-coder.git themes/hugo-coder
  }

  void checkGitExecutableInstalled() {
    checkProgramInstalled(
      context: context,
      executable: 'git',
      notFound: () {
        gitInstalled = false;
        if (mounted) {
          gitInstalledText =
              Localization.appLocalizations().executableNotFound('git', 'Git');
        }
        setState(() {});
      },
      found: (finalExecutable) {
        gitInstalled = true;
        if (mounted) {
          gitInstalledText = Localization.appLocalizations()
              .executableFoundIn('Git', finalExecutable);
        }
        setState(() {});
      },
      showErrorSnackbar: false,
      ssg: SSG.getSSGType(Preferences.getSSG()),
    );
  }

  Widget _selectTheme() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Text(Localization.appLocalizations().selectATheme, style: style),
          const SizedBox(height: 32),
          SelectableText(Localization.appLocalizations().rememberToVisitDocs,
              style: smallerStyle),
          const SizedBox(height: 32),
          FutureBuilder(
            future: HugoThemes.findAllThemes(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }

              var value = Hugo.getHugoTheme();
              var buttonList = <DropdownMenuItem<String>>[];
              buttonList.add(DropdownMenuItem(
                  value: '',
                  child: Text(Localization.appLocalizations().none)));
              if (snapshot.hasData) {
                if (snapshot.data!.isNotEmpty) {
                  buttonList.addAll(snapshot.data!.map((element) {
                    return DropdownMenuItem(
                      value: element.path.split(Platform.pathSeparator).last,
                      child:
                          Text(element.path.split(Platform.pathSeparator).last),
                    );
                  }).toList());
                } else {
                  value = '';
                  Hugo.setHugoTheme('');
                }
              }
              var themeExists = false;
              for (var i = 0; i < buttonList.length; i++) {
                if (buttonList[i].value == value) themeExists = true;
              }
              if (themeExists == false) {
                value = '';
                Hugo.setHugoTheme('');
              }

              return DropdownButton(
                value: value,
                items: buttonList,
                onChanged: (option) async {
                  await Hugo.setHugoTheme(option ?? themeName);
                  setState(() {});
                  if (mounted) {
                    Provider.of<NavigationProvider>(context, listen: false)
                        .notifyAllListeners();
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _downloadTheme() {
    return Column(
      children: [
        Text(Localization.appLocalizations().downloadTheme, style: style),
        const SizedBox(height: 32),
        Stepper(
          currentStep: currentStep,
          onStepContinue: () async {
            if (currentStep < 2) {
              setState(() => currentStep++);
            } else {
              setState(() => currentStep = 1);
            }
          },
          onStepCancel: () {
            if (currentStep > 0) {
              setState(() {
                currentStep--;
              });
            }
          },
          controlsBuilder: (context, details) {
            canContinue = gitInstalled == true &&
                (details.stepIndex == 1 ? !themeNameError : true);

            return Padding(
              padding: const EdgeInsets.only(top: 32),
              child: Row(
                children: <Widget>[
                  if (details.stepIndex == 0)
                    ElevatedButton(
                      onPressed: canContinue ? details.onStepContinue : null,
                      child: Text(Localization.appLocalizations().continue2),
                    ),
                  if (details.stepIndex == 1)
                    ElevatedButton(
                      onPressed: themeNameError || isDownloading
                          ? null
                          : () => _download(),
                      child: Text(Localization.appLocalizations()
                          .download
                          .toUpperCase()),
                    ),
                  if (details.stepIndex == 2)
                    ElevatedButton(
                      onPressed: canContinue ? details.onStepContinue : null,
                      child: Text(Localization.appLocalizations()
                          .startOver
                          .toUpperCase()),
                    ),
                  const SizedBox(width: 8),
                  if (details.stepIndex < 2)
                    TextButton(
                      onPressed: details.stepIndex > 0 && !isDownloading
                          ? details.onStepCancel
                          : null,
                      child: Text(Localization.appLocalizations().back),
                    ),
                ],
              ),
            );
          },
          steps: [
            Step(
              isActive: currentStep >= 0,
              title: Text(Localization.appLocalizations().checkGitInstalled),
              content: Column(
                children: [
                  Icon(
                    gitInstalled == null
                        ? Icons.question_mark
                        : gitInstalled == true
                            ? Icons.check
                            : Icons.close,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => checkGitExecutableInstalled(),
                    child:
                        Text(Localization.appLocalizations().checkGitInstalled),
                  ),
                  const SizedBox(height: 16),
                  Text(gitInstalledText),
                ],
              ),
            ),
            Step(
              isActive: currentStep >= 1,
              title: Text(Localization.appLocalizations().downloadTheme),
              content: Column(
                children: [
                  const SizedBox(height: 16),
                  Tooltip(
                    message: 'https://themes.gohugo.io',
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final url =
                            Uri(scheme: 'https', path: 'themes.gohugo.io');
                        if (await canLaunchUrl(url) || Platform.isLinux) {
                          await launchUrl(url);
                        }
                      },
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('https://themes.gohugo.io'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 16.0,
                    runSpacing: 16.0,
                    children: [
                      if (isDownloading) const CircularProgressIndicator(),
                      SizedBox(
                        width: 400,
                        child: TextField(
                          onChanged: (value) {
                            themeName = value;
                            themeNameError = false;
                            setState(() {});
                          },
                          style: TextStyle(
                              color: Colors.grey[600], fontSize: 17.0),
                          decoration: InputDecoration(
                            errorText: themeNameError
                                ? Localization.appLocalizations()
                                    .repositoryInvalidURL
                                : null,
                            labelText:
                                Localization.appLocalizations().themeRepository,
                            hintText: 'https://github.com/user/hugo-theme',
                            hintStyle: TextStyle(
                              color: Colors.grey[500],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Step(
              isActive: currentStep >= 2,
              title: Text(Localization.appLocalizations().finish),
              content: Column(
                children: [
                  SelectableText.rich(TextSpan(
                      text: Localization.appLocalizations()
                          .successfullyDownloadedHugoTheme,
                      style: const TextStyle(fontSize: 20),
                      children: <TextSpan>[
                        TextSpan(
                          text: themeName,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        TextSpan(
                          text: Localization.appLocalizations().nowSelectTheme(
                              '"${themeName.split(Platform.pathSeparator).last}"'),
                        ),
                      ])),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Localization.appLocalizations().websiteThemes),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 64.0),
          child: MediaQuery.of(context).size.width > mobileWidth
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _selectTheme()),
                    Expanded(child: _downloadTheme()),
                  ],
                )
              : Column(
                  children: [
                    _selectTheme(),
                    const SizedBox(height: 32.0),
                    const Divider(),
                    const SizedBox(height: 32.0),
                    _downloadTheme(),
                  ],
                ),
        ),
      ),
    );
  }
}
