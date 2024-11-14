import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'dart:ui' as ui show Path;


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
                const FinderView(),

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

class FinderView extends StatefulWidget {

  static bool _hasAskedPermission = false;
  const FinderView({super.key});

  @override
  State<FinderView> createState()=> _FinderViewState();
}

class _FinderViewState extends State<FinderView> {
  final MapController mapController = MapController();
  final LatLng location = LatLng(38.9894, -76.9365);
  StreamSubscription<Position>? _positionStreamSubscription;

  @override
  void initState() {
    super.initState();
    
    if (!FinderView._hasAskedPermission) {
      _initLocationTracking();
    }
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initLocationTracking() async {
    // Set flag to true as we're about to ask for permission
    FinderView._hasAskedPermission = true;
    
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      
      if (permission == LocationPermission.denied || 
          permission == LocationPermission.deniedForever) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are needed to find Terpiez')),
          );
        }
        return;
      }

    
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enable location services')),
          );
        }
        return;
      }

     
      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).listen(
        (Position position) {
          if (mounted) {
            Provider.of<UserState>(context, listen: false).updateLocation(position);
            mapController.move(
              LatLng(position.latitude, position.longitude),
              mapController.camera.zoom,
            );
          }
        },
        onError: (error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Location error: $error')),
            );
          }
        },
      );

      
      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        Provider.of<UserState>(context, listen: false).updateLocation(position);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }


@override
Widget build(BuildContext context) {
  // Get the current orientation
  final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
  
  // Create the map widget
  final mapWidget = Expanded(
    child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Consumer<UserState>(
          builder: (context, userState, child) {
            final currentLocation = userState.currentLocation;
            return FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: currentLocation != null 
                  ? LatLng(currentLocation.latitude, currentLocation.longitude)
                  : location,
                initialZoom: 19.5,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.terpiez',
                ),
                
                if (currentLocation != null) 
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: LatLng(currentLocation.latitude, currentLocation.longitude),
                        radius: 8,
                        color: Colors.blue.withOpacity(0.7),
                        borderColor: Colors.white,
                        borderStrokeWidth: 2,
                      ),
                      CircleMarker(
                        point: LatLng(currentLocation.latitude, currentLocation.longitude),
                        radius: 30,
                        color: Colors.blue.withOpacity(0.1),
                        borderColor: Colors.blue.withOpacity(0.3),
                        borderStrokeWidth: 2,
                      ),
                    ],
                  ),
                // Terpiez markers
                // MarkerLayer(
                //   markers: userState.getTerpiez.map((terpiez) {
                //     return Marker(
                //       point: terpiez.location,
                //       width: 40,
                //       height: 40,
                //       child: Icon(
                //         terpiez.icon,
                //         color: Colors.red,
                //         size: 40,
                //       ),
                //     );
                //   }).toList(),
                // ),
              ],
            );
          },
        ),
      ),
    ),
  );

  // Create the info widget
  final infoWidget = Consumer<UserState>(
    builder: (context, userState, child) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Closest Terpiez: ${userState.nearestDistance?.toStringAsFixed(1) ?? "undefined"} m',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: userState.isInCatchRange ? () => userState.incrementTerpiez() : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink.shade100,
                foregroundColor: Colors.pink.shade900,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Catch it!'),
            ),
          ],
        ),
      );
    },
  );

  return Column(
    children: [
      const SizedBox(height: 20),
      const Text(
        'Terpiez Finder',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 24),
      ),
      Expanded(
        child: isLandscape
            // Landscape layout
            ? Row(
                children: [
                  // Map on the left
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.6, // 60% of width
                    child: mapWidget,
                  ),
                  // Info on the right
                  Expanded(
                    child: Center(child: infoWidget),
                  ),
                ],
              )
            // Portrait layout
            : Column(
                children: [
                  mapWidget,
                  infoWidget,
                ],
              ),
      ),
    ],
  );
}
}


class Terpiez {
  final String name;
  final IconData icon;
  final LatLng location;
  bool caught;  

  Terpiez({
    required this.name,
    required this.icon,
    required this.location,
    this.caught = false,  
  });
}


class UserState extends ChangeNotifier {
  int _terpiezCaught = 0;
  final String _userID;
  DateTime _startDate;
  Position? _currentLocation;
  double? _nearestDistance;  
  //Terpiez? _nearestTerpiez;  

  final List<Terpiez> terpiez = [
    Terpiez(
      name: 'Bug',
      icon: Icons.bug_report,
      location: LatLng(38.9894, -76.9363),  
    ),
    Terpiez(
      name: 'Plane',
      icon: Icons.airplanemode_active,
      location: LatLng(38.9893, -76.9366),  
    ),
  ];

  UserState() : _startDate = DateTime.now(), _userID = const Uuid().v4();

  // Keep existing getters
  Position? get currentLocation => _currentLocation;
  List<Terpiez> get getTerpiez => terpiez;
  int get terpiezCaught => _terpiezCaught;
  DateTime get startDate => _startDate;
  String get userID => _userID;
  double? get nearestDistance => _nearestDistance; 
  bool get isInCatchRange => _nearestDistance != null && _nearestDistance! <= 10;  


  int get numOfDaysPlayed {
    final currentDate = DateTime.now();
    return currentDate.difference(_startDate).inDays;
  }

  void updateLocation(Position position) {
    _currentLocation = position;
    _updateNearestTerpiez(); 
    notifyListeners();
  }

  
  void _updateNearestTerpiez() {
    if (_currentLocation == null) return;

    double minDistance = double.infinity;

    for (var terp in terpiez) {
      if (!terp.caught) {  // Only consider uncaught Terpiez
        final distance = Geolocator.distanceBetween(
          _currentLocation!.latitude,
          _currentLocation!.longitude,
          terp.location.latitude,
          terp.location.longitude,
        );

        if (distance < minDistance) {
          minDistance = distance;
        }
      }
    }

    // If all Terpiez are caught, set distance to null
    _nearestDistance = minDistance == double.infinity ? null : minDistance;
    notifyListeners();
  }

  void incrementTerpiez() {
    if (!isInCatchRange) return;

    // Find the closest uncaught Terpiez
    Terpiez? closestUncaught;
    double minDistance = double.infinity;

    for (var terp in terpiez) {
      if (!terp.caught) {
        final distance = Geolocator.distanceBetween(
          _currentLocation!.latitude,
          _currentLocation!.longitude,
          terp.location.latitude,
          terp.location.longitude,
        );

        if (distance < minDistance) {
          minDistance = distance;
          closestUncaught = terp;
        }
      }
    }

    // If we found an uncaught Terpiez in range
    if (closestUncaught != null && minDistance <= 10) {
      closestUncaught.caught = true;
      _terpiezCaught++;
      _updateNearestTerpiez();  // Update distances after catching
      notifyListeners();
    }

 
  // void incrementTerpiez() {
  //   if (isInCatchRange) {  // Only increment if in range
  //     _terpiezCaught++;
  //     notifyListeners();
  //   }
  // }

  







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
      ui.Path path = ui.Path();
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

