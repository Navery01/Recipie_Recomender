import 'dart:io';

import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'recipes.dart';
import 'dart:convert';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) {
        var appState = MyAppState();
        appState.readFile(); // Call readFile to populate Ilist
        return appState;
      },
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Namer App',
        theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
            scaffoldBackgroundColor: const Color.fromRGBO(255, 255, 255, 0)),
        home: MyHomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var current = WordPair.random();

  void getNext() {
    current = WordPair.random();
    notifyListeners();
  }

  //ignore     V
  var favorites = <WordPair>[];
  var Ilist = <String>[];
  //end-ignore ^

  List inventoryList = <Ingredient>[];
  Map<String, dynamic> recipeLibrary =
      {}; //access with AppState.recipeLibrary["id"].attribute

  Future<void> writeToFile(String name, DateTime date) async {
    final file = File("lib/Ingredients.txt");
    await file.writeAsString('$name,${date.toString()}\n',
        mode: FileMode.append);
    notifyListeners();
  }

  void deleteFromFile(int index) async {
    final file = File("lib/Ingredients.txt");
    List<String> lines = await file.readAsLines();

    if (index >= 0 && index < lines.length) {
      lines.removeAt(index);
      await file.writeAsString(lines.join('\n'));
      print('Line deleted successfully.');
    } else {
      print('Invalid line index.');
    }
  }

  void readFile() async {
    try {
      final file = File("lib/ingredients.txt");
      if (await file.exists()) {
        var contents = await file.readAsLines();
        if (contents.isNotEmpty) {
          inventoryList = contents.map((ingredientName) {
            var ingredient = Ingredient();
            var ingredientData = ingredientName.split(",");
            ingredient.name = ingredientData[0];
            ingredient.date = DateTime.parse(ingredientData[1]);
            return ingredient;
          }).toList();
        }
      }
    } catch (e) {
      print("Error reading file: $e");
    }
    notifyListeners();
  }

  void readRecipes() async {
    //fills a map (recipeLibrary) with recipes from the JSON database
    try {
      var file = File("jsonfile/db-recipes.json");
      if (await file.exists()) {
        String parseJSON = await file.readAsString();
        Map<String, dynamic> jsonMap = jsonDecode(parseJSON);

        jsonMap.keys.forEach((key) {
          recipes recipe = recipes.fromJSON(jsonMap[key]);
          recipeLibrary[key] = recipe;
        });
      }
    } catch (e) {
      print("error reading JSON file");
    }
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = GeneratorPage();
        break;
      case 1:
        page = RecipesPage();
        break;
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        body: Row(
          children: [
            SafeArea(
              child: NavigationRail(
                extended: constraints.maxWidth >= 600,
                destinations: [
                  NavigationRailDestination(
                    icon: Icon(Icons.home),
                    label: Text('Home'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.favorite),
                    label: Text('Recipe List'),
                  ),
                ],
                selectedIndex: selectedIndex,
                onDestinationSelected: (value) {
                  setState(() {
                    selectedIndex = value;
                  });
                },
              ),
            ),
            Expanded(
              child: Container(
                child: page,
              ),
            ),
          ],
        ),
      );
    });
  }
}

class GeneratorPage extends StatefulWidget {
  @override
  State<GeneratorPage> createState() => _GeneratorPageState();
}

class _GeneratorPageState extends State<GeneratorPage> {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(0.0),
            child: IngredientInputBox(),
          ),
          SizedBox(height: 10),
          SizedBox(
            child: IngredientShowcase(appState),
            height: 600,
          ),

          // ElevatedButton.icon(
          //   onPressed: () {
          //     // appState.toggleFavorite();
          //   },
          //   icon: Icon(icon),
          //   label: Text('Like'),
          // ),
          // SizedBox(width: 10),
          // ElevatedButton(
          //   onPressed: () {
          //     appState.getNext();
          //   },
          //   child: Text('Next'),
          // ),
        ],
      ),
    );
  }

  Widget IngredientShowcase(MyAppState appState) {
    appState.readFile();
    if (appState.inventoryList.isEmpty) {
      return Center(
        child: Text(
          "You have no ingredients",
          style: TextStyle(color: Colors.white),
        ),
      );
    } else {
      setState(() {});
      DateTime today = DateTime.now();
      List<Widget> ingredientListTiles = [];

      for (var ingredient in appState.inventoryList) {
        DateTime expirationDate = ingredient.date;
        Duration difference = expirationDate.difference(today);
        int expireDays = difference.inDays;
        bool isExpired = expirationDate.isBefore(DateTime.now());
        String expirationText =
            isExpired ? 'Expired' : 'Expires on ${expirationDate.toString()}';

        Widget ingredientTile = GestureDetector(
          onTap: () async {
            await showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text(
                      "Delete ingredient?",
                      style: TextStyle(color: Colors.black),
                    ),
                    content: ElevatedButton(
                      child: Text("DELETE"),
                      onPressed: () async {
                        String delete = ingredient.name;
                        appState.deleteFromFile(appState.inventoryList
                            .indexWhere(
                                (ingredient) => ingredient.name == delete));
                        Navigator.pop(context);
                      },
                    ),
                  );
                });
            print("tap");
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListTile(
              visualDensity: VisualDensity(horizontal: .5),
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  color: getColor(expireDays),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              textColor: Color.fromRGBO(255, 255, 255, 1),
              leading: Icon(Icons.favorite),
              title: Text(ingredient.name),
              subtitle: Text(expirationText),
            ),
          ),
        );
        ingredientListTiles.add(ingredientTile);
      }

      return Container(
        height: 600,
        child: SingleChildScrollView(
          child: Column(
            children: ingredientListTiles,
          ),
        ),
      );
    }
  }

  Color getColor(int number) {
    if (number < 2) {
      return Colors.red;
    } else if (number < 7) {
      return Colors.yellow;
    } else {
      return Colors.green;
    }
  }
}

class IngredientInputBox extends StatefulWidget {
  const IngredientInputBox({
    super.key,
  });

  @override
  State<IngredientInputBox> createState() => _IngredientInputBoxState();
}

class _IngredientInputBoxState extends State<IngredientInputBox> {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    DateTime? selectedDate;
    return Container(
      color: Colors.black,
      width: 260,
      child: TextField(
        style: TextStyle(
          color: Color.fromRGBO(255, 255, 255, 1),
        ),
        autocorrect: true,
        decoration: InputDecoration(
            border: OutlineInputBorder(), labelText: "Enter Ingredients"),
        onSubmitted: (String ingredientName) async {
          await showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('When does the ${ingredientName} expire?'),
                  content: ElevatedButton(
                    child: Text('Select expiration date'),
                    onPressed: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );

                      if (pickedDate != null) {
                        setState(() {
                          selectedDate = pickedDate;
                        });
                        DateTime expirationDate = pickedDate;
                        appState.writeToFile(ingredientName, expirationDate);
                      }

                      Navigator.of(context).pop();
                    },
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        appState.writeToFile(ingredientName, DateTime(2200));
                      },
                      child: const Text('No expiration'),
                    ),
                  ],
                );
              });
        },
      ),
    );
  }
} //Ingredientinput box

class RecipesPage extends StatefulWidget {
  @override
  State<RecipesPage> createState() => _RecipesPageState();
}

class _RecipesPageState extends State<RecipesPage> {
  String? selectedOption; // Update to use nullable String

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    appState.readFile();
    appState.readRecipes();

    if (appState.recipeLibrary.isEmpty) {
      return Center(
        child: Text(
          "You have no recipes",
          style: TextStyle(color: Colors.white),
        ),
      );
    } else {
      List<Widget> recipeListTiles = [];

      appState.recipeLibrary.forEach((key, value) {
        var recipeTiles = Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListTile(
            visualDensity: VisualDensity(horizontal: .5),
            shape: RoundedRectangleBorder(
              side: BorderSide(
                width: 2,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            textColor: Color.fromRGBO(255, 255, 255, 1),
            leading: Icon(Icons.favorite),
            title: Text(value.name),
          ),
        );
        recipeListTiles.add(recipeTiles);
      });

      List<DropdownMenuItem<String>> dropdownItems = [
        DropdownMenuItem(
            child: Text(
              "Lactose Intolerant",
              style: TextStyle(color: Colors.white),
            ),
            value: "LI"),
        DropdownMenuItem(
            child: Text("Gluten Free", style: TextStyle(color: Colors.white)),
            value: "GF"),
        DropdownMenuItem(
            child: Text("Vegetarian", style: TextStyle(color: Colors.white)),
            value: "v"),
        DropdownMenuItem(
            child: Text("Vegan", style: TextStyle(color: Colors.white)),
            value: "V"),
      ];

      return Column(
        children: [
          Center(
            child: DropdownButton<String>(
              dropdownColor: Colors.black,
              items: dropdownItems,
              onChanged: (value) {
                setState(() {
                  selectedOption = value;
                });
              },
              value: selectedOption,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: recipeListTiles,
              ),
            ),
          ),
        ],
      );
    }
  }
}

class Ingredient {
  String _name = "";

  String get name => _name;

  set name(String value) {
    _name = value;
  }

  DateTime _date = DateTime.now();

  DateTime get date => _date;

  set date(DateTime value) {
    _date = value;
  }

  int _quantity = 0;

  int get quantity => _quantity;

  set quantity(int value) {
    _quantity = value;
  }
}
