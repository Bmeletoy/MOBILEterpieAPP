import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Terpiez'),
            backgroundColor: Colors.brown,
            bottom: const TabBar(
              tabs: [
                Tab(icon: Icon(Icons.show_chart), text: 'Stats'),
                Tab(icon: Icon(Icons.search), text: 'Finder'),
                Tab(icon: Icon(Icons.list), text: 'List'),
              ],
            ),
          ),
          body: SafeArea(
            child: TabBarView(
              children: [
                const Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: 20),
                      Text(
                        'Statistics',
                        style: TextStyle(fontSize: 30),
                      ),
                      SizedBox(height: 40),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text('Terpiez Found:'),
                          ),
                          Text('12', textAlign: TextAlign.center),
                        ],
                      ),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text('Days Active:'),
                          ),
                          Text('3', textAlign: TextAlign.center),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center, // Change to center to reduce excess space
                  children: [
                    const SizedBox(height: 20),
                    const Text(
                      'Terpiez Finder',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 24),
                    ),
                    Flexible(
                      child: OrientationBuilder(
                        builder: (context, orientation) {
                          return Flex(
                            direction: orientation == Orientation.portrait
                                ? Axis.vertical
                                : Axis.horizontal,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              LayoutBuilder(
                                builder: (context,  constraints) {
                                  return Icon(
                                    Icons.map,
                                    size: constraints.biggest.shortestSide,
                                    color: Colors.black,
                                  );
                                }
                              ),
                              const SizedBox(height: 10), // Reduce height here to make it tighter
                              const Text(
                                'Closest Terpiez: 123.0m',
                                style: TextStyle(fontSize: 18),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
                ListView(
                  children: [
                    Builder(
                      builder: (context) {
                        return ListTile(
                          leading: const Icon(Icons.bug_report),
                          title: const Text('Bug'),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const TerpiezDetailPage(
                                  icon: Icons.bug_report,
                                  name: 'Bug',
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.airplanemode_active),
                      title: const Text('Plane'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TerpiezDetailPage(
                              icon: Icons.airplanemode_active,
                              name: 'Plane',
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TerpiezDetailPage extends StatelessWidget {
  final IconData icon;
  final String name;

  const TerpiezDetailPage({
    Key? key,
    required this.icon,
    required this.name,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(name),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Icon(
              icon,
              size: 150,
              color: Colors.black,
            ),
            const SizedBox(height: 10),
            Text(
              name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}





// class MyHomePage extends StatefulWidget {
//   const MyHomePage({super.key, required this.title});

//   // This widget is the home page of your application. It is stateful, meaning
//   // that it has a State object (defined below) that contains fields that affect
//   // how it looks.

//   // This class is the configuration for the state. It holds the values (in this
//   // case the title) provided by the parent (in this case the App widget) and
//   // used by the build method of the State. Fields in a Widget subclass are
//   // always marked "final".

//   final String title;

