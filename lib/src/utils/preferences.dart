import 'dart:convert';

import 'package:buhocms/src/utils/globals.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../ssg/hugo.dart';
import '../widgets/file_navigation/buttons/sort_button.dart';

class Preferences {
  static Map<String, dynamic> defaultPreferences() {
    return Map.fromEntries([
      const MapEntry(prefLanguage, ''),
      MapEntry(prefThemeMode, ThemeMode.system.name),
      const MapEntry(prefColorScheme, 14),
      const MapEntry(prefPageIndex, 0),
      const MapEntry(prefCurrentFileIndex, -1),
      const MapEntry(prefNavigationSize, 64.0),
      const MapEntry(prefFileNavigationSize, 64.0),
      const MapEntry(prefOnboardingCompleted, false),
      const MapEntry(prefSitePath, null),
      const MapEntry(prefCurrentPath, ''),
      const MapEntry(prefCurrentFile, null),
      const MapEntry(prefIsGUIMode, true),
      MapEntry(prefSortMode, SortMode.name.name),
      MapEntry(
          prefFrontMatterAddList, json.encode(defaultFrontMatterAddList())),
      const MapEntry(prefDraggableMode, false),
      const MapEntry(prefTabs, null),
      const MapEntry(prefHugoTheme, ''),
    ]);
  }

  static Future clearPreferences() => _preferences!.clear();

  static String getAllPreferences() {
    //https://gist.github.com/kasperpeulen/d61029fc0bc6cd104602
    var object = json.decode(_preferences!.getString(prefPreferences) ?? '');
    return const JsonEncoder.withIndent('  ').convert(object);
  }

  static Future setAllPreferences(String preferences) async {
    await _preferences!.setString(prefPreferences, preferences);
  }

  static Future setPreferences(String key, dynamic value) async {
    final preferences = getPreferences();
    preferences[key] = value;

    String fromJson = json.encode(preferences);
    await _preferences!.setString(prefPreferences, fromJson);
  }

  static Map<String, dynamic> getPreferences() {
    final defaultPrefs = defaultPreferences();

    final Map prefs = json.decode(
        _preferences!.getString(prefPreferences) ?? json.encode(defaultPrefs));

    final Map<String, dynamic> allPrefs = {};
    allPrefs.addEntries(prefs.entries.map((e) => MapEntry(e.key, e.value)));

    return allPrefs;
  }

  static SharedPreferences? _preferences;

  static Future init() async =>
      _preferences = await SharedPreferences.getInstance();

  //Language
  static Future setLanguage(String locale) async =>
      await setPreferences(prefLanguage, locale);
  static String getLanguage() => getPreferences()[prefLanguage];

  //Theme Mode
  static Future setThemeMode(String theme) async =>
      await setPreferences(prefThemeMode, theme);
  static String getThemeMode() => getPreferences()[prefThemeMode];

  //Color Scheme Index
  static Future setColorSchemeIndex(int index) async =>
      await setPreferences(prefColorScheme, index);
  static int getColorSchemeIndex() => getPreferences()[prefColorScheme];

  //Page Index
  static Future setPageIndex(int index) async =>
      await setPreferences(prefPageIndex, index);
  static int getPageIndex() => getPreferences()[prefPageIndex];

  //File Index
  static Future setFileIndex(int index) async =>
      await setPreferences(prefCurrentFileIndex, index);
  static int getFileIndex() => getPreferences()[prefCurrentFileIndex];

  //Navigation Panel Size
  static Future setNavigationSize(double index) async =>
      await setPreferences(prefNavigationSize, index);
  static double getNavigationSize() => getPreferences()[prefNavigationSize];

  //File Navigation Panel Size
  static Future setFileNavigationSize(double index) async =>
      await setPreferences(prefFileNavigationSize, index);
  static double getFileNavigationSize() =>
      getPreferences()[prefFileNavigationSize];

  //Onboarding
  static Future setOnBoardingComplete(bool complete) async =>
      await setPreferences(prefOnboardingCompleted, complete);
  static bool getOnBoardingComplete() =>
      getPreferences()[prefOnboardingCompleted];

  //Site Path
  static Future setSitePath(String path) async =>
      await setPreferences(prefSitePath, path);
  static String? getSitePath() => getPreferences()[prefSitePath];

  //Save Path
  static Future setCurrentPath(String path) async =>
      await setPreferences(prefCurrentPath, path);
  static String getCurrentPath() => getPreferences()[prefCurrentPath];

  //Current File
  static Future<void> setCurrentFile(String path) async =>
      await setPreferences(prefCurrentFile, path);
  static String? getCurrentFile() => getPreferences()[prefCurrentFile];

  //GUI Mode
  static Future setIsGUIMode(bool isGUIMode) async =>
      await setPreferences(prefIsGUIMode, isGUIMode);
  static bool getIsGUIMode() => getPreferences()[prefIsGUIMode];

  //Sort Mode
  static Future setSortMode(SortMode sortMode) async =>
      await setPreferences(prefSortMode, sortMode.name);
  static String getSortMode() => getPreferences()[prefSortMode];

  //Front Matter Add list
  static Future setFrontMatterAddList(
      Map<String, HugoType> frontMatterAddList) async {
    Map<String, String> addListWithTypesStrings = {};
    addListWithTypesStrings.addEntries(
        frontMatterAddList.entries.map((e) => MapEntry(e.key, e.value.name)));

    String mapToStr = json.encode(addListWithTypesStrings);
    await setPreferences(prefFrontMatterAddList, mapToStr);
  }

  static Map<String, String> defaultFrontMatterAddList() {
    Map<String, String> defaultStringsAndTypes = {
      'title': HugoType.typeString.name,
      'date': HugoType.typeDate.name,
      'draft': HugoType.typeBool.name,
      'tags': HugoType.typeList.name,
    };
    return defaultStringsAndTypes;
  }

  static Map<String, HugoType> getFrontMatterAddList() {
    Map<String, String> defaultStringsAndTypesStrings = {};
    defaultStringsAndTypesStrings.addEntries(defaultFrontMatterAddList()
        .entries
        .map((e) => MapEntry(e.key, e.value)));

    Map strToMap = json.decode(getPreferences()[prefFrontMatterAddList] ??
        json.encode(defaultStringsAndTypesStrings));

    Map<String, HugoType> fromStringsToType = {};
    fromStringsToType.addEntries(strToMap.entries
        .map((e) => MapEntry(e.key, HugoType.values.byName(e.value))));

    return fromStringsToType;
  }

  //Tabs
  static Future setTabs(List<MapEntry<String, int>> tabs) async {
    Map<String, int> tabsMap = {};
    tabsMap.addEntries(tabs.map((e) => e));

    String mapToStr = json.encode(tabsMap);
    await setPreferences(prefTabs, mapToStr);
  }

  static List<MapEntry<String, int>> getTabs() {
    Map<String, int> tabsMap = {};

    Map strToMap =
        json.decode(getPreferences()[prefTabs] ?? json.encode(tabsMap));

    Map<String, int> fromStringsToType = {};
    fromStringsToType
        .addEntries(strToMap.entries.map((e) => MapEntry(e.key, e.value)));

    return fromStringsToType.entries.map((e) => e).toList();
  }

  //Hugo Theme
  static Future setHugoTheme(String theme) async =>
      await setPreferences(prefHugoTheme, theme);
  static String getHugoTheme() => getPreferences()[prefHugoTheme];
}
