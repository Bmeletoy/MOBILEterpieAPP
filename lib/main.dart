import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart' hide Consumer;
import 'package:provider/provider.dart' as provider show Consumer;
import 'package:uuid/uuid.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'dart:ui' as ui show Path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:redis/redis.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:math' show sqrt;
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:audioplayers/audioplayers.dart'; 




final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> navigatorKey2 = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> navigatorKey3 = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
   await TerpiezBackgroundService.initialize();
 

  final launchDetails = await TerpiezBackgroundService._notifications.getNotificationAppLaunchDetails();
  final startingTab = (launchDetails?.didNotificationLaunchApp ?? false) && 
                     launchDetails?.notificationResponse?.payload == 'finder' ? 1 : 0;

   final hasLoggedIn = await ManageCredentials.hasLoggedIn();



  void runWithMessenger(Widget app, {int initialTab = 0}) {
  runApp(MaterialApp(
    home: ScaffoldMessenger(
      key: GlobalKey<ScaffoldMessengerState>(),
      child: DefaultTabController(
        length: 3,
        initialIndex: initialTab,
        child: app,
      ),
    ),
  ));
}

 
  if (!hasLoggedIn) {
    runWithMessenger(
      ScaffoldMessenger(
        key: GlobalKey<ScaffoldMessengerState>(),
        child: MaterialApp(
        navigatorKey: navigatorKey,
        home: Builder(
          builder: (context) {
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              bool? loginSuccess = await showDialog<bool>(
                barrierDismissible: false,
                context: context,
                builder: (_) => const LoginDialog(),
              );

              if (loginSuccess == true) {
                final credentials = await ManageCredentials.getCredentials();
                if (credentials['username'] != null && credentials['password'] != null) {
                  final redisService = RedisService(
                    username: credentials['username']!,
                    password: credentials['password']!,
                  );
                  final userState = UserState();
                  await userState.initialize(redisService);

                  if (navigatorKey.currentContext != null) {
                    Navigator.pushReplacement(
                      navigatorKey.currentContext!,
                      MaterialPageRoute(
                        builder: (_) => ChangeNotifierProvider.value(
                          value: userState,
                          child: const MyApp(),
                        ),
                      ),
                    );
                  }
                }
              }
            });
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          },
        ),
      ),
      ),

    );
  } else {
    final credentials = await ManageCredentials.getCredentials();
    if (credentials['username'] != null && credentials['password'] != null) {
      final redisService = RedisService(
        username: credentials['username']!,
        password: credentials['password']!,
      );
      final userState = UserState();
      await userState.initialize(redisService);
      userState.clearCaughtLocations();

      runWithMessenger(
  ChangeNotifierProvider.value(
    value: userState,
    child: const MyApp(),
  ),
  initialTab: 0
);
    }
  }

}


class MyApp extends StatelessWidget {
  final int? initialIndex;
  const MyApp({super.key, this.initialIndex  = 0});

  @override
  Widget build(BuildContext context) {
    final userState = Provider.of<UserState>(context);
    return MaterialApp(
      navigatorKey: navigatorKey2,
      scaffoldMessengerKey: userState.scaffoldKey,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home:ChangeNotifierProvider.value(
        value: userState,
        child: DefaultTabController(
          length: 3,
       
        initialIndex: initialIndex ?? 0,
        child: Scaffold(
          drawer: provider.Consumer<UserState>(
            builder: (context, userState, child) => Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const DrawerHeader(
                    decoration: BoxDecoration(color: Colors.brown),
                    child: Text('Preferences', 
                      style: TextStyle(color: Colors.white, fontSize: 24)),
                  ),
                  ListTile(
                    leading: const Icon(Icons.volume_up),
                    title: SwitchListTile(
                      title: const Text('Sound Effects'),
                      value: SoundService().isSoundEnabled,
                      onChanged: (value) async {
                        await SoundService().setSoundEnabled(value);
                        userState.notifyListeners();
                      },
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete_forever),
                    title: const Text('Reset All Data'),
                    onTap: () => showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Reset All Data'),
                        content: const Text('This will delete all your progress. Are you sure?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              userState.resetAllData();
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('All data has been reset')),
                              );
                            },
                            child: const Text('Reset', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
                // Stats Tab
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      const Text('Statistics', style: TextStyle(fontSize: 30)),
                      const SizedBox(height: 40),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const Expanded(child: Text('Terpiez Found:')),
                          provider.Consumer<UserState>(
                            builder: (context, userState, child) {
                              return Text('${userState.terpiezCaught}',
                                textAlign: TextAlign.center);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const Expanded(child: Text('Days Active:')),
                          provider.Consumer<UserState>(
                            builder: (context, userState, child) {
                              return Text('${userState.numOfDaysPlayed}',
                                textAlign: TextAlign.center);
                            },
                          ),
                        ],
                      ),
                      Expanded(
                        child: Center(
                          child: provider.Consumer<UserState>(
                            builder: (context, userState, child) {
                              return Text('User: ${userState.userID}',
                                textAlign: TextAlign.center);
                            },
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                // Finder Tab
                const FinderView(),
                // List Tab
                provider.Consumer<UserState>(
                  builder: (context, userState, child) {
                    final uniqueCaughtTerpiez = userState.getTerpiez
                        .where((terp) => terp.caught)
                        .toSet()
                        .toList();

                    return ListView.builder(
                      itemCount: uniqueCaughtTerpiez.length,
                      itemBuilder: (context, index) {
                        final terp = uniqueCaughtTerpiez[index];
                        return ListTile(
                          leading: terp.thumbnailPath != null
                              ? Image.file(File(terp.thumbnailPath!),
                                  width: 40, height: 40)
                              : const Icon(Icons.catching_pokemon, size: 40),
                          title: Text(terp.name),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TerpiezDetailPage(terp: terp),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}

class TerpiezDetailPage extends StatelessWidget {
  // final IconData icon;
  // final String name;
  final Terpiez terp;
  // final String heroTag;

  const TerpiezDetailPage({
    Key? key,
    required this.terp,
    // required this.icon,
    // required this.name,
    // required this.heroTag,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(terp.name), // Use terp.name for the title
      ),
      body: Stack(
       children: [
         BackgroundAnimation(), // Keep background animation
         SingleChildScrollView(
           child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               const SizedBox(height: 20),
               Center(
                 child: SizedBox(
                   height: 200,
                   child: terp.fullImagePath != null
                     ? Image.file(
                         File(terp.fullImagePath!),
                         fit: BoxFit.contain,
                       )
                     : const Icon(Icons.image_not_supported, size: 150),
                 ),
               ),
               Center(
                 child: Text(
                   terp.name,
                   style: const TextStyle(
                     fontSize: 24,
                     fontWeight: FontWeight.bold,
                   ),
                 ),
               ),
               Padding(
                 padding: const EdgeInsets.all(16.0),
                 child: Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text('Avuncularity: ${terp.stats["Avuncularity"]}'),
                         Text('Destructivity: ${terp.stats["Destructivity"]}'),
                         Text('Panache: ${terp.stats["Panache"]}'),
                         Text('Spiciness: ${terp.stats["Spiciness"]}'),
                       ],
                     ),
                     SizedBox(
                       width: 150,
                       height: 150,
                       child: FlutterMap(
                         options: MapOptions(
                           initialCenter: terp.location,
                           initialZoom: 16,
                         ),
                         children: [
                           TileLayer(
                             urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                           ),
                           MarkerLayer(
                             markers: [
                              for (var location in terp.caughtLocations)
                                Marker(
                                  point: location,
                                  width: 30,
                                  height: 30,
                                  child: const Icon(Icons.location_on, color: Colors.red),
                                ),
                            ],
                           ),
                         ],
                       ),
                     ),
                   ],
                 ),
               ),
               Padding(
                 padding: const EdgeInsets.all(16.0),
                 child: Text(
                   terp.description,
                   style: const TextStyle(fontSize: 16),
                 ),
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
  const FinderView({super.key});

  @override
  State<FinderView> createState()=> _FinderViewState();
}

class _FinderViewState extends State<FinderView> {
  final MapController mapController = MapController();
  final LatLng defaultLocation = LatLng(38.9894, -76.9365);
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _hasRequestedPermission = false;

  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  DateTime? _lastShake;
  static const double _shakeThreshold = 10.0;
  static const Duration _cooldown = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _initAccelerometer();
    if (!_hasRequestedPermission) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initLocationTracking();
      });
    }
  }

  void _initAccelerometer() {
  _accelerometerSubscription = accelerometerEventStream().listen((event) {
    final acceleration = sqrt(
      event.x * event.x + 
      event.y * event.y + 
      event.z * event.z
    );
   
    if (acceleration > _shakeThreshold) {
      final now = DateTime.now();
      if (_lastShake == null || now.difference(_lastShake!) > _cooldown) {
        _lastShake = now;
          debugPrint('Shake passed cooldown. Triggering _handleShake');
        _handleShake();
      }
    }
  });
}

Future<void> _handleShake() async {
  final userState = Provider.of<UserState>(context, listen: false);

  
  
  // Visual feedback
  if (mounted) {
    debugPrint("Trying to catch");
    ScaffoldMessenger.of(context).clearSnackBars();  // Clear any existing snackbars
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          !userState.isConnected 
            ? 'Cannot catch while disconnected' 
            : !userState.isInCatchRange 
              ? 'No Terpiez in range' 
              : 'Attempting to catch...'
        ),
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

   debugPrint('Connected: ${userState.isConnected}, In Catch Range: ${userState.isInCatchRange}');

  // Early return if conditions aren't met
  if (!userState.isConnected) {
    debugPrint('Cannot catch: Not connected to Redis');
    return;
  }
  
  if (!userState.isInCatchRange) {
    debugPrint('Cannot catch: No Terpiez in range');
    return;
  }

  try {
    final credentials = await ManageCredentials.getCredentials();
    if (credentials['username'] != null && credentials['password'] != null) {
      final redisService = RedisService(
        username: credentials['username']!,
        password: credentials['password']!,
      );
      
      // Attempt to catch
      final caughtTerpiez = await userState.incrementTerpiez(redisService);
      
      
      // Show catch dialog if successful
      if (caughtTerpiez != null && mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,  // Force user to use dismiss button
          builder: (context) => CatchDialog(terpiez: caughtTerpiez),
        );

         await SoundService().playCatchSound();
      }

     //await SoundService().playCatchSound();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Redis credentials not found. Please log in again.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
    
  } catch (e) {
    debugPrint('Error in _handleShake: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error catching Terpiez: ${e.toString()}'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

@override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _accelerometerSubscription?.cancel();
    super.dispose();
  }


  Future<void> _initLocationTracking() async {
    if (_hasRequestedPermission) return;
    _hasRequestedPermission = true;
    
    try {
      // First check current permission status
      LocationPermission permission = await Geolocator.checkPermission();
      
      // If permission is denied, request it
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        
        if (permission == LocationPermission.denied || 
            permission == LocationPermission.deniedForever) {
          if (context.mounted) {
            //ScaffoldMessenger.of(context).clearSnackBars();
            //ScaffoldMessenger.of(context).showSnackBar(
            final userState = Provider.of<UserState>(context, listen: false);
            final credentials = await ManageCredentials.getCredentials();
              if (credentials['username'] != null && credentials['password'] != null) {
                 final redisService = RedisService(
                    username: credentials['username']!,
                    password: credentials['password']!,
                  );
                 await userState.fetchTerpiezFromRedis(redisService);
              }
          }
        }
      }

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (context.mounted) {
            ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enable location services'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // Start listening to location updates
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

      // Get initial position
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


  Widget _buildCatchIndicator() {
  return provider.Consumer<UserState>(
    builder: (context, userState, child) {
      final bool inRange = userState.isInCatchRange;
      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: inRange ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.1),
          border: Border.all(
            color: inRange ? Colors.green : Colors.red,
            width: 2,
          ),
        ),
        child: Center(
          child: Icon(
            Icons.catching_pokemon,
            color: inRange ? Colors.green : Colors.red,
            size: 40,
          ),
        ),
      );
    },
  );
}


@override
Widget build(BuildContext context) {

  final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
  
  final mapWidget = Expanded(
    child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: provider.Consumer<UserState>(
          builder: (context, userState, child) {
            final currentLocation = userState.currentLocation;
            return FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: currentLocation != null 
                  ? LatLng(currentLocation.latitude, currentLocation.longitude)
                  : defaultLocation,
                initialZoom: 19.5,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.terpiez',
                ),
                MarkerLayer(
                 markers: currentLocation != null 
                  ? [
                      ...userState.getTerpiez
                        .where((terp) => !terp.caught)
                        .map((terp) {
                          final distance = Geolocator.distanceBetween(
                            currentLocation.latitude,
                            currentLocation.longitude,
                            terp.location.latitude,
                            terp.location.longitude,
                          );
                          return distance <= 10 ? Marker(
                            point: terp.location,
                            width: 30,
                            height: 30,
                            child: const Icon(Icons.place, color: Colors.black, size: 30),
                          ) : null;
                        })
                        .where((marker) => marker != null)
                        .cast<Marker>()
                        .take(1),
                    ]
                  : [],
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
                
              ],
            );
          },
        ),
      ),
    ),
  );

  // Create the info widget
  final infoWidget = provider.Consumer<UserState>(
    builder: (context, userState, child) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Closest Terpiez: ${userState.nearestDistance == null ? "undefined" : "${userState.nearestDistance!.toStringAsFixed(1)}m"}',
              style: TextStyle(
                fontSize: 18,
                color: userState.isInCatchRange ? Colors.green : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            _buildCatchIndicator(),
            if (userState.isInCatchRange)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text(
                  'Shake to catch!',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.green,
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );

final mapArea = Padding(
  padding: const EdgeInsets.all(8.0),
  child: ClipRRect(
    borderRadius: BorderRadius.circular(8.0),
    child: provider.Consumer<UserState>(
      builder: (context, userState, child) {
        final currentLocation = userState.currentLocation;
        return FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: currentLocation != null 
              ? LatLng(currentLocation.latitude, currentLocation.longitude)
              : defaultLocation,
            initialZoom: 19.5,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.terpiez',
            ),
            MarkerLayer(
              markers: currentLocation != null 
                ? [
                    ...userState.getTerpiez
                      .where((terp) => !terp.caught)
                      .map((terp) {
                        final distance = Geolocator.distanceBetween(
                          currentLocation.latitude,
                          currentLocation.longitude,
                          terp.location.latitude,
                          terp.location.longitude,
                        );
                        return distance <= 10 ? Marker(
                          point: terp.location,
                          width: 30,
                          height: 30,
                          child: const Icon(Icons.place, color: Colors.black, size: 30),
                        ) : null;
                      })
                      .where((marker) => marker != null)
                      .cast<Marker>()
                      .take(1),
                  ]
                : [],
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
          ],
        );
      },
    ),
  ),
);

  return LayoutBuilder(
  builder: (context, constraints) => Column(
    children: [
      Text('Terpiez Finder', style: TextStyle(fontSize: 18)),
      Expanded(
        child: isLandscape
          ? Row(
              children: [
                Flexible(flex: 3, child: mapArea),
                Flexible(flex: 2, child: FittedBox(child: infoWidget)),
              ],
            )
          : Column(children: [
              Expanded(child: mapArea),
              infoWidget
            ]),
      ),
    ],
  ),
);
}
}


class Terpiez {
  final String name;
  final IconData icon;
  final LatLng location;
  final String terpiezId;
  bool caught;  
  String? thumbnailPath;
  String? fullImagePath;
  String? imageKey;
  String? thumbnailKey;
  Map<String, dynamic> stats;
  String description;
  List<LatLng> caughtLocations;

  Terpiez({
    required this.name,
    required this.icon,
    required this.location,
    required this.terpiezId,
    this.caught = false,  
    this.thumbnailPath,
    this.fullImagePath,
    this.imageKey,
    this. thumbnailKey,
    this.stats = const {},
    this.description = 'No description available',
    List<LatLng>? caughtLocations,
  }) : caughtLocations = caughtLocations ?? [location];

  @override
  bool operator == (Object other) {
    if (identical(this, other)) return true;
    return other is Terpiez && other.name == name;
  }

  @override
  int get hashCode => name.hashCode;
}

class CatchDialog extends StatelessWidget {
  final Terpiez terpiez;

  const CatchDialog({super.key, required this.terpiez});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(6.6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'You caught a Terpiez!',
              style: TextStyle(fontSize: 15),
            ),
            // const SizedBox(height: 20),
            if (terpiez.fullImagePath != null)
              Image.file(
                File(terpiez.fullImagePath!),
                height: 200,
                width: 200,
                fit: BoxFit.contain,
              ),
            Text(
              terpiez.name,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink[50],
                foregroundColor: Colors.pink[900],
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Great!'),
            ),
          ],
        ),
      ),
    );
  }
}



class UserState extends ChangeNotifier {
  int _terpiezCaught = 0;
  String _userID;
  DateTime _startDate;
  Position? _currentLocation;
  double? _nearestDistance; 
   bool _canCatch = true; 

   bool get canCatch => _canCatch;
  //Terpiez? _nearestTerpiez;  

  List<Terpiez> terpiez = [];

  bool _isConnected = false;
  RedisService? _redisService;
  final GlobalKey<ScaffoldMessengerState> scaffoldKey = GlobalKey<ScaffoldMessengerState>();
  
  bool get isConnected => _isConnected;

  UserState() : _startDate = DateTime.now(), _userID = const Uuid().v4(){
    debugPrint('Initializing UserState with UUID: $_userID');
  }

  

  // Keep existing getters
  Position? get currentLocation => _currentLocation;
  List<Terpiez> get getTerpiez {
    debugPrint('Getting terpiez list. Count: ${terpiez.length}');
  // for (var terp in terpiez) {
  //   debugPrint('Terpiez: ${terp.name}, Thumbnail: ${terp.thumbnailPath}');
  // }
  
    return terpiez;
  }

  void _handleConnectionChange(bool isConnected) {
    if (_isConnected != isConnected) {
      _isConnected = isConnected;
      debugPrint('Connection status changed: $isConnected');
      if (navigatorKey2.currentContext != null) {
      ScaffoldMessenger.of(navigatorKey2.currentContext!).clearSnackBars(); // Clear existing SnackBars
      ScaffoldMessenger.of(navigatorKey2.currentContext!).showSnackBar(
        SnackBar(
          content: Text(isConnected ? 'Connection restored' : 'Lost connection to Redis server'),
          duration: Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    notifyListeners();
  }
}

Future<void> initialize(RedisService redisService) async {
  _redisService = redisService;
  _isConnected = redisService.isConnected;
  redisService.onConnectionStatusChanged = _handleConnectionChange;
    //debugPrint('Starting UserState initialization');
    try {
      await fetchTerpiezFromRedis(redisService);
      debugPrint('Successfully initialized UserState with Redis data');
    } catch (e) {
      debugPrint('Error during UserState initialization: $e');
    }
}
  // List<Terpiez> get getTerpiez => terpiez;
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

   Future<File> _saveToFile(Uint8List bytes, String filename) async {
  try {
    debugPrint('Starting to save file...');
    final directory = await getApplicationDocumentsDirectory();
    final directory2 = await getExternalStorageDirectory();
   // debugPrint('Got directory: ${directory.path}');
    final file = File('${directory.path}/$filename');
    //debugPrint('Got directory2: ${directory2?.path}');
    final file2 = File('${directory2?.path}/$filename');

    await directory.create(recursive: true);
    //debugPrint('Created file object: ${file.path}');
    await file.writeAsBytes(bytes);
     //debugPrint('Created file2 object: ${file2.path}');
    await file2.writeAsBytes(bytes);
    //debugPrint('Written bytes to file: ${file.path}');
    return file;
  } catch (e) {
    debugPrint('Error saving file: $e');
    throw Exception('Failed to save file: $filename');
  }
}

  
  void _updateNearestTerpiez() {
    if (_currentLocation == null){
      debugPrint('Cannot update nearest Terpiez: No current location');
      return;
    }

   // debugPrint('Updating nearest Terpiez. Current location: ${_currentLocation!.latitude}, ${_currentLocation!.longitude}');
    //debugPrint('Number of Terpiez to check: ${terpiez.length}');

    double minDistance = double.infinity;
    Terpiez? closestTerpiez;
    var uncaughtTerpiez = terpiez.where((terp) => !terp.caught).toList();
  if (uncaughtTerpiez.isEmpty) {
    _nearestDistance = null;
    notifyListeners();
    return;
  }

    for (var terp in terpiez) {
      if (!terp.caught || !terp.caughtLocations.any((loc) => 
      Geolocator.distanceBetween(
        loc.latitude, 
        loc.longitude,
        _currentLocation!.latitude,
        _currentLocation!.longitude
      ) < 10)) {  // Only consider uncaught Terpiez
        final distance = Geolocator.distanceBetween(
          _currentLocation!.latitude,
          _currentLocation!.longitude,
          terp.location.latitude,
          terp.location.longitude,
        );

        if (distance < minDistance) {
          minDistance = distance;
          closestTerpiez = terp;
        }
      }
    }
    // If all Terpiez are caught, set distance to null
   _nearestDistance = minDistance == double.infinity ? null : minDistance;
    notifyListeners();
  //debugPrint('Updated nearest distance: $_nearestDistance');
  if (closestTerpiez != null) {
   // debugPrint('Closest Terpiez is ${closestTerpiez.name} at ${_nearestDistance}m');
  } else {
   // debugPrint('No uncaught Terpiez found');
  }
  
  notifyListeners();
  }

  void clearCaughtLocations() {
  for (var terp in terpiez) {
    terp.caughtLocations = [terp.location];
  }
  notifyListeners();
}

 Future<Terpiez?> incrementTerpiez(RedisService redisService) async {
  if(!_isConnected){
     scaffoldKey.currentState?.showSnackBar(
      const SnackBar(content: Text('Cannot catch while disconnected'))
    );
    return null;

  }
  debugPrint('Starting incrementTerpiez');
    if (!isInCatchRange) {
      debugPrint('Not in catch range');
      return null;
    }

    debugPrint('Finding closest uncaught Terpiez');
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
      //debugPrint('found closest Terpiez: {$closestUncaught}');
      _terpiezCaught++;
      debugPrint('Starting place to save information:');
      if(!terpiez.any((terp) => terp.name == closestUncaught!.name && terp.caught)){
        closestUncaught.caught = true;
        debugPrint('Do we Get Here?');
        try {
          final directory = await getApplicationDocumentsDirectory();
          //final terpiezDir = Directory('${directory.path}/Android/data/com.example.terpiez');
          //await terpiezDir.create(recursive: true);
          debugPrint('Getting information to save');
          final details = await redisService.getTerpiezDetails(closestUncaught.terpiezId);
          final thumbnailBase64 = await redisService.getTerpiezImage(details['thumbnail']);
          final fullImageBase64 = await redisService.getTerpiezImage(details['image']);

         // debugPrint('About to save thumbnail for ${closestUncaught.name}');
          final thumbnailFile = await _saveToFile(base64Decode(thumbnailBase64), '${closestUncaught.name}_thumbnail.png');
         // debugPrint('About to save full image for ${closestUncaught.name}');
          final fullImageFile = await _saveToFile(base64Decode(fullImageBase64), '${closestUncaught.name}_full.png');
        // debugPrint('Files saved successfully');

          closestUncaught.thumbnailPath = thumbnailFile.path;
          closestUncaught.fullImagePath = fullImageFile.path;
          closestUncaught.stats = details['stats'];
          closestUncaught.description = details['description'];
          closestUncaught.caughtLocations.add(LatLng(
            _currentLocation!.latitude,
            _currentLocation!.longitude
          ));

         // debugPrint('Terp Location: ${closestUncaught.location.latitude}, ${closestUncaught?.location.longitude}');
          //debugPrint('Current Location: ${_currentLocation?.latitude}, ${_currentLocation?.longitude}');
          //debugPrint('Caught status before: ${closestUncaught.caught}');

          _updateNearestTerpiez();
        // Update distances after catching
          notifyListeners();

          await saveUserStateToRedis(redisService);
          return closestUncaught;



        } catch (e) {
          debugPrint('Failed to download Terpiez details: $e');
          return null;
        }



        }
      }
      // _updateNearestTerpiez();
      //   // Update distances after catching
      // notifyListeners();

      // await saveUserStateToRedis(redisService);
      return null;
    }



  Future<void> loadCaughtTerpiezFromRedis(RedisService redisService) async {
  try {
    // Fetch user-specific data
    final userData = await redisService.getTerpiezDetails(_userID);

    if (userData.containsKey('caughtTerpiez')) {
      final caughtList = List<String>.from(userData['caughtTerpiez']);
      for (var terp in terpiez) {
        if (caughtList.contains(terp.name)) {
          terp.caught = true;
        }
      }
      notifyListeners();
    }
  } catch (e) {
    debugPrint('Error loading caught Terpiez from Redis: $e');
  }
}


  Future<void> fetchTerpiezFromRedis(RedisService redisService) async {
  
  try {
    //debugPrint('Starting to fetch Terpiez from Redis');
    final locations = await redisService.getLocations();
    //debugPrint('Raw locations data: $locations');
    
    // Clear existing terpiez list
    terpiez.clear();
    
    for (var location in locations) {
      try {
        //debugPrint('Processing location: $location');
        final id = location['id'] as String;
        
        // Get Terpiez details
        final details = await redisService.getTerpiezDetails(id);
        //debugPrint('Got details for Terpiez: ${details['name']}');
        
        if (details['thumbnail'] != null) {
          //debugPrint('Found thumbnail key: ${details['thumbnail']}');
          //final thumbnailData = await redisService.getTerpiezImage(details['thumbnail']);
          
          // Save thumbnail to file
          //final directory = await getApplicationDocumentsDirectory();
          //final terpiezDir = Directory('${directory.path}/im');
          //await terpiezDir.create(recursive: true);
          
          
          //final thumbnailPath = await _saveToFile(bytes, filename)
          //final thumbnailFile = File(thumbnailPath);
          //await thumbnailFile.writeAsBytes(base64Decode(thumbnailData));
          //debugPrint('Saved thumbnail to: $thumbnailPath');
          
          // Create new Terpiez instance
          final newTerpiez = Terpiez(
            name: details['name'],
            icon: Icons.catching_pokemon,
            terpiezId: id,
            location: LatLng(
              double.parse(location['lat'].toString()),
              double.parse(location['lon'].toString()),
            ),
            imageKey: details['image'],
            thumbnailKey: details['thumbnail'],
            stats: Map<String, dynamic>.from(details['stats'] ?? {}),
            description: details['description'] ?? '',
          );
          

          // if (details['image'] != null) {
          //   final imageData = await redisService.getTerpiezImage(details['image']);
          //   final fullImagePath = '${terpiezDir.path}/${details['name']}_full.png';
          //   final imageFile = File(fullImagePath);
          //   await imageFile.writeAsBytes(base64Decode(imageData));
          //   debugPrint('Saved full image to: $fullImagePath');
            
          //   newTerpiez.fullImagePath = fullImagePath;
          // }
          
          terpiez.add(newTerpiez);
          //debugPrint('Successfully added Terpiez: ${newTerpiez.name}');
        } else {
          debugPrint('No thumbnail found for Terpiez: ${details['name']}');
        }
      } catch (e, stackTrace) {
        debugPrint('Error processing individual Terpiez: $e');
        debugPrint('Stack trace: $stackTrace');
      }
    }
    
    notifyListeners();
    debugPrint('Finished fetching Terpiez. Total count: ${terpiez.length}');
  } catch (e, stackTrace) {
    debugPrint('Error in fetchTerpiezFromRedis: $e');
    debugPrint('Stack trace: $stackTrace');
    rethrow;
  }
  }



    Future<void> saveUserStateToRedis(RedisService redisService) async {
      try {
        final data = {
          'terpiezCaught': _terpiezCaught,
          'daysActive': numOfDaysPlayed,
          'caughtTerpiez': terpiez
              .where((terp) => terp.caught)
              .map((terp) => terp.name)
              .toList(),
        };
        await redisService.updateUserData(_userID, data);
      } catch (e) {
        debugPrint('Error saving user state to Redis: $e');
      }
    }

    // Add to UserState class
  Future<void> resetAllData() async {
    try {
      final String newUUID = const Uuid().v4();
      
      // Update all storage locations
      await ManageCredentials.storeUUID(newUUID);
      final storage = const FlutterSecureStorage();
      await storage.write(key: 'user_uuid', value: newUUID);
      
      // Reset all state variables
      _userID = newUUID;
      _terpiezCaught = 0;
      _startDate = DateTime.now();
      
      // Reset Terpiez data and clean up files
      for (var terp in terpiez) {
        terp.caught = false;
        terp.caughtLocations = [terp.location];
        
        if (terp.thumbnailPath != null) {
          try {
            final file = File(terp.thumbnailPath!);
            if (await file.exists()) {
              await file.delete();
            }
          } catch (e) {
            debugPrint('Error deleting thumbnail: $e');
          }
          terp.thumbnailPath = null;
        }
        
        if (terp.fullImagePath != null) {
          try {
            final file = File(terp.fullImagePath!);
            if (await file.exists()) {
              await file.delete();
            }
          } catch (e) {
            debugPrint('Error deleting full image: $e');
          }
          terp.fullImagePath = null;
        }
      }
      
      // Update Redis if connected
      if (_redisService != null && _isConnected) {
        await _redisService!.updateUserData(newUUID, {
          'terpiezCaught': 0,
          'daysActive': 0,
          'caughtTerpiez': [],
        });
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error in resetAllData: $e');
      rethrow;
    }
  }
}




class TerpiezBackgroundService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static const notificationChannelId = 'terpiez_nearby';
  static const foregroundNotificationId = 1;
  static const nearbyNotificationId = 2;
  static final FlutterBackgroundService _service = FlutterBackgroundService();
  static final SoundService _soundService = SoundService();

  static void _handleNotificationTap(String? payload) async {
    if (payload == 'finder') {
    try{
    final hasLoggedIn = await ManageCredentials.hasLoggedIn();
    if (!hasLoggedIn) return;

    final credentials = await ManageCredentials.getCredentials();
    if (credentials['username'] != null && credentials['password'] != null) {
      final redisService = RedisService(
        username: credentials['username']!,
        password: credentials['password']!,
      );
      final userState = UserState();
      await userState.initialize(redisService);

       runApp(
        MaterialApp(
          navigatorKey: navigatorKey2,
          home: Builder(
            builder: (context) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                DefaultTabController.of(context)?.animateTo(1);
              });
              return ChangeNotifierProvider.value(
                value: userState,
                child: const MyApp(),
              );
            },
          ),
        ),
      );
    }
    } catch (e) {
      debugPrint('Error: $e');
    }
    
}
}

  static Future<void> initialize() async {
    // Initialize notifications
     debugPrint("Starting TerpiezBackground service initialization");
  await _soundService.initialize();
  debugPrint("Sound service initialized, enabled: ${_soundService.isSoundEnabled}");
  
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidSettings);
    
    // Handle notification clicks when app launches
    // final NotificationAppLaunchDetails? launchDetails = 
    //     await _notifications.getNotificationAppLaunchDetails();
    // if (launchDetails?.didNotificationLaunchApp ?? false) {
    //   _handleNotificationTap(launchDetails?.notificationResponse?.payload);
    // }

    // Initialize notifications with click handling
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) => _handleNotificationTap(details.payload),
    );

    // Create notification channel
    const channel = AndroidNotificationChannel(
      notificationChannelId,
      'Nearby Terpiez',
      importance: Importance.high,
      sound: null,
      playSound: false,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);


    await _notifications
    .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
    ?.requestNotificationsPermission();

    final NotificationAppLaunchDetails? launchDetails = 
      await _notifications.getNotificationAppLaunchDetails();
      
  if (launchDetails?.didNotificationLaunchApp ?? false) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleNotificationTap(launchDetails?.notificationResponse?.payload);
    });
  }

    // Configure background service
    await _service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: notificationChannelId,
        initialNotificationTitle: 'Terpiez Finder',
        initialNotificationContent: 'Searching for nearby Terpiez...',
        foregroundServiceNotificationId: foregroundNotificationId,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
      ),
      
    );

    
  }

  @pragma('vm:entry-point')
  static Future<void> onStart(ServiceInstance service) async {
    if (service is AndroidServiceInstance) {
      service.setAsForegroundService();
    }

    //final soundService = SoundService();
    final prefs = await SharedPreferences.getInstance();
    final soundEnabled = prefs.getBool('sound_enabled') ?? true;

    if (soundEnabled) {
      debugPrint("Background service starting with sound enabled");
      await _soundService.initialize();
    }

    LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

     Geolocator.getPositionStream(locationSettings: locationSettings)
      .listen((Position position) async {
        debugPrint("Position update received: ${position.latitude}, ${position.longitude}");
        final terpiez = await _getNearbyTerpiez(position);
        if (terpiez != null) {
          // Re-check sound preferences each time
          await _soundService.initialize();
          debugPrint("Sound enabled in background: ${_soundService.isSoundEnabled}");
          
          if(_soundService.isSoundEnabled) {
            await _soundService.playNearbySound();
          }
          await _showNearbyNotification(terpiez['name']);
        }
      });
    //  }
    //});
  }

  static Future<Map<String, dynamic>?> _getNearbyTerpiez(Position position) async {
    try {
      final credentials = await ManageCredentials.getCredentials();
      if (credentials['username'] == null || credentials['password'] == null) {
        return null;
      }

      final redisService = RedisService(
        username: credentials['username']!,
        password: credentials['password']!,
      );

      final locations = await redisService.getLocations();
      
      for (var location in locations) {
        final distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          double.parse(location['lat'].toString()),
          double.parse(location['lon'].toString()),
        );

        debugPrint('Distance to Terpiez: ${distance.toStringAsFixed(1)}m');
        //  debugPrint('Terpiez details: we get here tho!! :)'); 

        if (distance <= 20) {  // Between 10-20m range
          final details = await redisService.getTerpiezDetails(location['id']);
           debugPrint('Terpiez details: $details'); 
          return {
            'name': details['name'],
            'distance': distance,
            'id': location['id']
          };
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error in _getNearbyTerpiez: $e');
      return null;
    }
  }

  static Future<void> _showNearbyNotification(String terpiezName) async {
  debugPrint("Starting notification setup");
  
  final soundEnabled = SoundService().isSoundEnabled;

  debugPrint("Showing notification with sound enabled: $soundEnabled");
    
    try {
      final androidDetails = AndroidNotificationDetails(
       notificationChannelId,
        'Nearby Terpiez',
        channelDescription: 'Notifications for nearby Terpiez',
        importance: Importance.max,
        priority: Priority.high,
        sound: null,
        playSound: false,
        ongoing: false,
        autoCancel: true,
        enableLights: true,
        enableVibration: true,
      );

      await _notifications.show(
        DateTime.now().millisecondsSinceEpoch % 100000,
        'Terpiez Nearby!',
        'A $terpiezName is within range!',
        NotificationDetails(android: androidDetails),
        payload: 'finder'
      );
      //  if (soundEnabled) {
      //     await SoundService().playNearbySound();
      //   }
    } catch (e) {
      debugPrint("Error showing notification: $e");
    }
    }
}

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  
  final AudioPlayer _catchPlayer = AudioPlayer();
  final AudioPlayer _nearbyPlayer = AudioPlayer();
  bool _soundEnabled = true;
  static const _soundKey = 'sound_enabled';
  
  SoundService._internal();

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    await AudioCache.instance.loadAll([
      'catch_sound.wav', 
      'nearby_sound.wav',
    ]);
    _soundEnabled = prefs.getBool(_soundKey) ?? true;
    debugPrint("Sound service initialized with enabled: $_soundEnabled");
  }

  Future<void> playCatchSound() async {
    if (!_soundEnabled) return;
    await _catchPlayer.stop();
    await _catchPlayer.play(AssetSource('catch_sound.wav'));
  }

  Future<void> playNearbySound() async {
    debugPrint("Attempting to play nearby sound");
    if (!_soundEnabled) {
      debugPrint("Sound disabled, skipping");
      return;
    }
    
    try {
      await _nearbyPlayer.stop();
    debugPrint("Loading sound file...");
    await _nearbyPlayer.play(AssetSource('nearby_sound.wav'));
    
    _nearbyPlayer.onPlayerStateChanged.listen((state) {
      debugPrint("Player state changed: $state");
    });
    
    _nearbyPlayer.onPlayerComplete.listen((event) {
      debugPrint("Sound finished playing");
    });
    } catch (e) {
      debugPrint("Play error: $e");
    }
  }

  Future<void> setSoundEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundKey, enabled);
    _soundEnabled = enabled;
    debugPrint("Sound enabled set to: $_soundEnabled");
  }

  bool get isSoundEnabled => _soundEnabled;

  void dispose() {
    _catchPlayer.dispose();
    _nearbyPlayer.dispose();
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

class ManageCredentials {
  static const String _passwordKey = 'redis_password';
  static const String _userNameKey = 'redis_username';
  static const String _uuidKey = 'user_uuid';
  static const String _firstLaunchKey = 'default_firstVal';
  static const String _hasLoggedInKey = 'has_LoggedIN';
  static const String _secureUUIDKey = 'secure_user_uuid';

  static final _storage =  const FlutterSecureStorage();

  static Future<bool> hasLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasLoggedInKey) ?? false;
  }

  static Future<void> storeCredentials(String username, String password) async {
    await _storage.write(key: _userNameKey, value: username);
    await _storage.write(key: _passwordKey, value: password);

    final preference = await SharedPreferences.getInstance();
    await preference.setBool(_hasLoggedInKey, true);
  }

  static Future <Map<String, String?>> getCredentials() async {
    return {
      'username': await _storage.read(key: _userNameKey),
      'password': await _storage.read(key: _passwordKey),
    };
  }
  static Future<void> storeUUID(String uuid) async {
     final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString(_uuidKey, uuid),
      _storage.write(key: _secureUUIDKey, value: uuid),
  ]);
  }
  
  static Future<String?> getUUID() async {
    final prefs = await SharedPreferences.getInstance();
    final sharedPrefsUuid = prefs.getString(_uuidKey);
    final secureStorageUuid = await _storage.read(key: _secureUUIDKey);
    
    if (sharedPrefsUuid != null && secureStorageUuid != null) {
      if (sharedPrefsUuid != secureStorageUuid) {
        await prefs.setString(_uuidKey, secureStorageUuid);
        return secureStorageUuid;
      }
      return sharedPrefsUuid;
    }
    return sharedPrefsUuid ?? secureStorageUuid;
  }
  
  // Store/retrieve first launch date
  static Future<void> storeFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_firstLaunchKey)) {
      await prefs.setString(_firstLaunchKey, DateTime.now().toIso8601String());
    }
  }
  
  static Future<DateTime?> getFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = prefs.getString(_firstLaunchKey);
    return dateStr != null ? DateTime.parse(dateStr) : null;
  }

}

class RedisService {
  static const String _host = 'cmsc436-0101-redis.cs.umd.edu';
  static const int _port = 6380;
  
  Command? _cmd;
  final String username;
  final String password;

  bool _isConnected = false;
  Timer? _probeTimer;
  Function(bool)? onConnectionStatusChanged;
  static const Duration connectionTimeout = Duration(seconds: 1);
  
  RedisService({
    required this.username, 
    required this.password,
    this.onConnectionStatusChanged,}) {
      _startProbing();
    }

    Future<dynamic> _executeRedisOperation(Function operation) async {
    if (!_isConnected && operation != _probe) {
      debugPrint('Coming from executeRedisOperation');
      throw Exception('Not connected to Redis from Execute operations method');
    }
    try {
      return await operation().timeout(connectionTimeout);
    } on TimeoutException {
      _isConnected = false;
      onConnectionStatusChanged?.call(false);
      throw Exception('Redis operation timed out');
    }
  }

  // Only allow probes when disconnected
  void _startProbing() {
    _probeTimer?.cancel();
    _probeTimer = Timer.periodic(Duration(seconds: 10), (_) {
     _probe();
    });
  }

  Future<void> _probe() async {
  try {
    final conn = RedisConnection();
    final cmd = await conn.connect(_host, _port).timeout(connectionTimeout);
    await cmd.send_object(['AUTH', username, password]).timeout(connectionTimeout);
    if (!_isConnected) {
      _isConnected = true;
      onConnectionStatusChanged?.call(true);
    }
  } catch (e) {
    if (_isConnected) {
      _isConnected = false;
      onConnectionStatusChanged?.call(false);
    }
  }
}

   bool get isConnected => _isConnected;

  
  Future<void> connect() async {

    if (_cmd != null) return;

      try {
        
        final conn = RedisConnection();
        _cmd = await conn.connect(_host, _port).timeout(connectionTimeout);
       // debugPrint('Attempting to authenticate with Redis...');
        await _cmd!.send_object(['AUTH', username, password]).timeout(connectionTimeout);
        _isConnected = true;
        onConnectionStatusChanged?.call(true);
       // debugPrint('Successfully authenticated with Redis');
    } catch (e){
      _isConnected = false;
      onConnectionStatusChanged?.call(false);
      debugPrint('Redis connection error: $e');
      throw Exception ('Failed to connect from connect method: $e');
    }  
  }
  Future<void> disconnect() async {
    _cmd = null;
  }
  


  Future<List<Map<String, dynamic>>> getLocations() async {
      // if (!_isConnected) throw Exception('Not connected to Redis from getLocations');
       

    try {
      await connect().timeout(connectionTimeout);
      if (!_isConnected) {
    throw Exception('Not connected to Redis from getLocations method');
  }
      debugPrint('Fetching locations from Redis...');
      final result = await _cmd!.send_object(['JSON.GET', 'locations', '.']).timeout(connectionTimeout);
     // debugPrint('Raw locations response: $result');
      if (result != null) {
        debugPrint('Fetched Locations from Redis');
        final List<dynamic> decoded = jsonDecode(result.toString());
        return decoded.map((item) => Map<String, dynamic>.from(item)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching locations: $e');
      throw Exception('Failed to fetch locations: $e');
    }
  }
 
  Future<Map<String, dynamic>> getTerpiezDetails(String id) async {
      // if (!_isConnected) throw Exception('Not connected to Redis from getTerpiezDetails');
    try {
      await connect().timeout(connectionTimeout);
      if (!_isConnected) {
    throw Exception('Not connected to Redis From getTerpiezDetails method');
  }
     // debugPrint('Fetching details for Terpiez ID: $id');
      final result = await _cmd!.send_object(['JSON.GET', 'terpiez', '.$id']).timeout(connectionTimeout);
      //debugPrint('Raw Terpiez details: $result');
      if (result != null) {
        // debugPrint('Raw Terpiez not null');
        return Map<String, dynamic>.from(jsonDecode(result.toString()));
      }
      throw Exception('No details found for Terpiez ID: $id');
    } catch (e) {
      debugPrint('Error fetching Terpiez details: $e');
      throw Exception('Failed to fetch Terpiez details: $e');
    }
  }

  Future<String> getTerpiezImage(String imageKey) async {
      //  if (!_isConnected) {
      //     await _probe(); // Try to reconnect
      //     if (!_isConnected) throw Exception('Not connected to Redis');
      //   }

    try {
      await connect().timeout(connectionTimeout);
       if (!_isConnected) {
  throw Exception('Not connected to Redis from getTerpiezImageMethod');
}
     // debugPrint('Fetching image with key: $imageKey');
      final result = await _cmd!.send_object(['JSON.GET', 'images', '.$imageKey']).timeout(connectionTimeout);
      //debugPrint('Successfully retrieved image data');
      if (result != null) {
        return jsonDecode(result.toString());
      }
      throw Exception('No image found for key: $imageKey');
    } catch (e) {
      debugPrint('Error fetching image: $e');
      throw Exception('Failed to fetch image: $e');
    }
  }
 
  Future<void> updateUserData(String uuid, Map<String, dynamic> data) async {
       
    try {

      await connect().timeout(connectionTimeout);

      if (!_isConnected){
        throw Exception('Not connected to Redis from updateUserData');
        
       }
      // Fix the Redis error by properly structuring the data
      final jsonData = jsonEncode({uuid: data});
    // debugPrint('Updating user data for UUID: $uuid');
     // debugPrint('Data to be saved: $jsonData');
      
      // Create the root object first if it doesn't exist
      await _cmd!.send_object([
        'JSON.SET',
        username,
        '.',
        '{}',
        'NX'  // Only set if it doesn't exist
      ]).timeout(connectionTimeout);
      
      // Then update the specific UUID path
      await _cmd!.send_object([
        'JSON.SET',
        username,
        '.$uuid',
        jsonEncode(data)
      ]).timeout(connectionTimeout);

      debugPrint('Successfully updated user data');
    } catch (e) {
      debugPrint('Error updating user data: $e');
      throw Exception('Failed to update user data: $e');
    }
  }

}

class LoginDialog extends StatefulWidget {
  const LoginDialog({Key? key}) : super(key: key);

  @override
  State<LoginDialog> createState() => _LoginDialogState();
}

class _LoginDialogState extends State<LoginDialog> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _attemptLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final service = RedisService(
        username: _usernameController.text,
        password: _passwordController.text,
      );
      
      // Test connection
      await service.connect();
      
      // Store credentials if successful
      await ManageCredentials.storeCredentials(
        _usernameController.text,
        _passwordController.text,
      );
      
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Invalid credentials or connection error';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Redis Login Required'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Username is required' : null,
            ),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Password is required' : null,
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : _attemptLogin,
          child: _isLoading
              ? const CircularProgressIndicator()
              : const Text('Login'),
        ),
      ],
    );
  }
}

//9c78c8ac89a64d08a2745e379cd682f3
//json.get bmeletoy .114ef678-01b2-477c-9bb8-0cc8014553e3