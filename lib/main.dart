import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';


void main() {
  runApp(
    ChangeNotifierProvider(create: (context) => UserState(), 
    child: const MyApp(),)
  );
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
                Padding(
                  padding:  const EdgeInsets.all(10.0),
                  child:  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      const Text(
                        'Statistics',
                        style: TextStyle(fontSize: 30),
                      ),
                      const SizedBox(height: 40),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const Expanded(
                            child: Text('Terpiez Found:'),
                          ),
                          // const Text('12', textAlign: TextAlign.center),
                          Consumer<UserState> (
                            builder: (context, userState, child){
                              return Text(
                                '${userState.terpiezCaught}',
                                textAlign: TextAlign.center,
                              );
                            },
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const Expanded(
                            child: Text('Days Active:'),
                          ),
                          // Text('3', textAlign: TextAlign.center),
                          Consumer<UserState> (
                            builder: (context, userState, child){
                              return Text(
                              '${userState.numOfDaysPlayed}',
                              textAlign: TextAlign.center,
                              );
                            },
                          ),
                        ],
                      ),
                      
                      Expanded(
                        child: Center(
                          child: Consumer<UserState> (
                        builder: (context, userState, child){
                          return Text(
                            'User: ${userState.userID}',
                            textAlign: TextAlign.center,
                          );
                        },
                      ) ,) ,)
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
                          return GestureDetector(
                            onTap: () {
                              Provider.of<UserState>(context, listen: false).incrementTerpiez();
                            },
                          child: Flex(
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
                          ),
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
                          leading: 
                          // const Icon(Icons.bug_report),
                           Hero(
                            tag: 'terpiez_bug_hero_trans',
                            child: const Icon(Icons.bug_report),
                            ),
                          title: const Text('Bug'),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const TerpiezDetailPage(
                                  icon: Icons.bug_report,
                                  name: 'Bug',
                                  //heroTag: 'terpiez_bug_hero_trans',
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
  // final String heroTag;

  const TerpiezDetailPage({
    Key? key,
    required this.icon,
    required this.name,
    // required this.heroTag,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(name),
      ),
      body: Stack(
        children: [
           BackgroundAnimation(), 
            Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Hero(
                  tag: 'terpiez_bug_hero_trans',
                  child:
                    Icon(
                      icon,
                      size: 150,
                      color: Colors.black,
                    ),
                ),
                const SizedBox(height: 10),
                Text(
                  name,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class UserState extends ChangeNotifier {
  int _terpiezCaught  = 0;
  final String _userID;
  DateTime _startDate;

  UserState() : _startDate = DateTime.now(), _userID = const Uuid().v4();

  int get terpiezCaught => _terpiezCaught;

  DateTime get startDate => _startDate;

  String get userID => _userID;

  void incrementTerpiez(){
    _terpiezCaught++;
    notifyListeners();
  }

  int get numOfDaysPlayed {
    final currentDate = DateTime.now();
    return currentDate.difference(_startDate).inDays;
  }







}


class BackgroundAnimation extends StatefulWidget{
  @override
  _BackgroundAnimationState createState() => _BackgroundAnimationState();

}

class _BackgroundAnimationState extends State<BackgroundAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat(reverse: true);

    
  }

  @override
  void dispose(){
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context)  {
    return SizedBox.expand( // Make sure it fills the available space
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _PaintBackground(_controller.value),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _PaintBackground extends CustomPainter {
  final double animationVal;

  _PaintBackground(this.animationVal);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
    ..color = Colors.redAccent.withOpacity(0.3)
    ..style = PaintingStyle.fill;

    double stripeWidth = size.width * 0.4;
    double offset = (animationVal * size.width) % (stripeWidth * 2);

    
    for (double x = -stripeWidth * 2; x < size.width + stripeWidth * 2; x += stripeWidth * 2) {
      Path path = Path();
      path.moveTo(x - offset, 0);
      path.lineTo(x + stripeWidth - offset, 0);
      path.lineTo(x + stripeWidth * 2 - offset, size.height);
      path.lineTo(x + stripeWidth - offset, size.height);
      path.close();

      canvas.drawPath(path, paint);
    }
  }

  @override
    bool shouldRepaint(covariant CustomPainter oldDelegate){
    return true;
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

