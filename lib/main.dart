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


final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final hasLoggedIn = await ManageCredentials.hasLoggedIn();


 
  if (!hasLoggedIn) {
    runApp(
      MaterialApp(
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

      runApp(
        ChangeNotifierProvider.value(
          value: userState,
          child: const MyApp(),
        ),
      );
    }
  }

  // if (!hasLoggedIn) {
  //   runApp(
  //     MaterialApp(
  //       navigatorKey: navigatorKey, // Attach the global key
  //       home: Builder(
  //         builder: (context) {
  //           // Show the login dialog
  //           WidgetsBinding.instance.addPostFrameCallback((_) async {
  //             await showDialog(
  //               barrierDismissible: false, // Force user to complete login
  //               context: context,
  //               builder: (_) => const LoginDialog(),
  //             );
  //           });
  //           // Return a placeholder while login is processed
  //           return const Scaffold(body: Center(child: CircularProgressIndicator()));
  //         },
  //       ),
  //     ),
  //   );
  // } else {
  //   runApp(
  //     ChangeNotifierProvider(
  //       create: (context) => UserState(),
  //       child: const MyApp(),
  //     ),
  //   );
  // }
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
                          provider.Consumer<UserState> (
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
                          provider.Consumer<UserState> (
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
                          child:provider.Consumer<UserState> (
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

               provider.Consumer<UserState>(
                  builder: (context, userState, child) {
                    final uniqueCaughtTerpiez = userState.getTerpiez.where((terp) => terp.caught).toSet().toList();

                    return ListView.builder(
                      itemCount: uniqueCaughtTerpiez.length,
                      itemBuilder: (context, index) {
                        final terp = uniqueCaughtTerpiez[index];
                        return ListTile(
                                    leading: terp.thumbnailPath != null
                            ? Image.file(
                                File(terp.thumbnailPath!),
                                width: 40,
                                height: 40,
                              )
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
                               Marker(
                                 point: terp.location,
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

  @override
  void initState() {
    super.initState();
    // Request permission immediately when the view is created
    if (!_hasRequestedPermission) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initLocationTracking();
      });
    }
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
                  markers: userState.getTerpiez
                    .where((terp) => !terp.caught && currentLocation != null)
                    .take(10)
                    .map((terp) {
                      final distance = Geolocator.distanceBetween(
                        currentLocation!.latitude,
                        currentLocation!.longitude,
                        terp.location.latitude,
                        terp.location.longitude,
                      );
                      if (distance <= 10) {
                        return Marker(
                          point: terp.location,
                          width: 30,
                          height: 30,
                          child: const Icon(Icons.place, color: Colors.black, size: 30),
                        );
                      }
                      return null;
                    })
                    .where((marker) => marker != null)
                    .cast<Marker>()
                    .toList(),
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
              'Closest Terpiez: ${userState.nearestDistance?.toStringAsFixed(1) ?? "undefined"} m',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: userState.isInCatchRange ? () async {
          // Retrieve stored credentials
                      final credentials = await ManageCredentials.getCredentials();
                      if (credentials['username'] != null && credentials['password'] != null) {
                        final redisService = RedisService(
                          username: credentials['username']!,
                          password: credentials['password']!,
                        );

                        // Call incrementTerpiez with RedisService
                        userState.incrementTerpiez(redisService);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Redis credentials not found. Please log in again.'),
                          ),
                        );
                      }
                    }
                  : null,
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


class UserState extends ChangeNotifier {
  int _terpiezCaught = 0;
  final String _userID;
  DateTime _startDate;
  Position? _currentLocation;
  double? _nearestDistance; 
   bool _canCatch = true; 

   bool get canCatch => _canCatch;
  //Terpiez? _nearestTerpiez;  

  List<Terpiez> terpiez = [];

  UserState() : _startDate = DateTime.now(), _userID = const Uuid().v4(){
    debugPrint('Initializing UserState with UUID: $_userID');
  }

  

  // Keep existing getters
  Position? get currentLocation => _currentLocation;
  List<Terpiez> get getTerpiez {
  debugPrint('Getting terpiez list. Count: ${terpiez.length}');
  for (var terp in terpiez) {
    debugPrint('Terpiez: ${terp.name}, Thumbnail: ${terp.thumbnailPath}');
  }
  return terpiez;
}

Future<void> initialize(RedisService redisService) async {
    debugPrint('Starting UserState initialization');
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
    try{
      final directory = await getApplicationDocumentsDirectory();
      final terpiezDir = Directory('${directory.path}/terpiez_images');

      if(!await terpiezDir.exists()){
        await terpiezDir.create(recursive: true);
      }

      final file = File('${terpiezDir.path}/filename');
      await file.writeAsBytes(bytes);
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

    debugPrint('Updating nearest Terpiez. Current location: ${_currentLocation!.latitude}, ${_currentLocation!.longitude}');
    debugPrint('Number of Terpiez to check: ${terpiez.length}');

    double minDistance = double.infinity;
    Terpiez? closestTerpiez;

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
          closestTerpiez = terp;
        }
      }
    }
    // If all Terpiez are caught, set distance to null
   _nearestDistance = minDistance == double.infinity ? null : minDistance;
  debugPrint('Updated nearest distance: $_nearestDistance');
  if (closestTerpiez != null) {
    debugPrint('Closest Terpiez is ${closestTerpiez.name} at ${_nearestDistance}m');
  } else {
    debugPrint('No uncaught Terpiez found');
  }
  
  notifyListeners();
  }

  void incrementTerpiez(RedisService redisService) async {
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

      if(!terpiez.any((terp) => terp.name == closestUncaught!.name && terp.caught)){
        try {
          final details = await redisService.getTerpiezDetails(closestUncaught.name);
          final thumbnailBase64 = await redisService.getTerpiezImage(details['thumbnail']);
          final fullImageBase64 = await redisService.getTerpiezImage(details['image']);


          final decodedThumbnail = base64Decode(thumbnailBase64);
          final decodedFullImage = base64Decode(fullImageBase64);

          // Save locally
          final thumbnailFile = await _saveToFile(decodedThumbnail, '${closestUncaught.name}_thumbnail.png');
          final fullImageFile = await _saveToFile(decodedFullImage, '${closestUncaught.name}_full.png');

          closestUncaught.thumbnailPath = thumbnailFile.path;
          closestUncaught.fullImagePath = fullImageFile.path;
          closestUncaught.stats = details['stats'];
          closestUncaught.description = details['description'];
        } catch (e) {
          debugPrint('Failed to download Terpiez details: $e');
        }

        }
      }
      _updateNearestTerpiez();  // Update distances after catching
      notifyListeners();

      await saveUserStateToRedis(redisService);
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
    debugPrint('Starting to fetch Terpiez from Redis');
    final locations = await redisService.getLocations();
    debugPrint('Raw locations data: $locations');
    
    // Clear existing terpiez list
    terpiez.clear();
    
    for (var location in locations) {
      try {
        debugPrint('Processing location: $location');
        final id = location['id'] as String;
        
        // Get Terpiez details
        final details = await redisService.getTerpiezDetails(id);
        debugPrint('Got details for Terpiez: ${details['name']}');
        
        if (details['thumbnail'] != null) {
          debugPrint('Found thumbnail key: ${details['thumbnail']}');
          final thumbnailData = await redisService.getTerpiezImage(details['thumbnail']);
          
          // Save thumbnail to file
          final directory = await getApplicationDocumentsDirectory();
          final terpiezDir = Directory('${directory.path}/terpiez_images');
          await terpiezDir.create(recursive: true);
          
          final thumbnailPath = '${terpiezDir.path}/${details['name']}_thumbnail.png';
          final thumbnailFile = File(thumbnailPath);
          await thumbnailFile.writeAsBytes(base64Decode(thumbnailData));
          debugPrint('Saved thumbnail to: $thumbnailPath');
          
          // Create new Terpiez instance
          final newTerpiez = Terpiez(
            name: details['name'],
            icon: Icons.catching_pokemon,
            location: LatLng(
              double.parse(location['lat'].toString()),
              double.parse(location['lon'].toString()),
            ),
            thumbnailPath: thumbnailPath,
            stats: Map<String, dynamic>.from(details['stats'] ?? {}),
            description: details['description'] ?? '',
          );

          if (details['image'] != null) {
            final imageData = await redisService.getTerpiezImage(details['image']);
            final fullImagePath = '${terpiezDir.path}/${details['name']}_full.png';
            final imageFile = File(fullImagePath);
            await imageFile.writeAsBytes(base64Decode(imageData));
            debugPrint('Saved full image to: $fullImagePath');
            
            newTerpiez.fullImagePath = fullImagePath;
          }
          
          terpiez.add(newTerpiez);
          debugPrint('Successfully added Terpiez: ${newTerpiez.name}');
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

  static final _storage = FlutterSecureStorage();

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
    await prefs.setString(_uuidKey, uuid);
  }
  
  static Future<String?> getUUID() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_uuidKey);
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
  
  RedisService({required this.username, required this.password});
  
  Future<void> connect() async {
    if (_cmd != null) return;

      try {
        final conn = RedisConnection();
        _cmd = await conn.connect(_host, _port);
        debugPrint('Attempting to authenticate with Redis...');
        await _cmd!.send_object(['AUTH', username, password]);
        debugPrint('Successfully authenticated with Redis');
    } catch (e){
      debugPrint('Redis connection error: $e');
      throw Exception ('Failed to connect: $e');
    }  
  }
  Future<void> disconnect() async {
    _cmd = null;
  }
  


  Future<List<Map<String, dynamic>>> getLocations() async {
    try {
      await connect();
      debugPrint('Fetching locations from Redis...');
      final result = await _cmd!.send_object(['JSON.GET', 'locations', '.']);
      debugPrint('Raw locations response: $result');
      if (result != null) {
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
    try {
      await connect();
      debugPrint('Fetching details for Terpiez ID: $id');
      final result = await _cmd!.send_object(['JSON.GET', 'terpiez', '.$id']);
      debugPrint('Raw Terpiez details: $result');
      if (result != null) {
        return Map<String, dynamic>.from(jsonDecode(result.toString()));
      }
      throw Exception('No details found for Terpiez ID: $id');
    } catch (e) {
      debugPrint('Error fetching Terpiez details: $e');
      throw Exception('Failed to fetch Terpiez details: $e');
    }
  }

  Future<String> getTerpiezImage(String imageKey) async {
    try {
      await connect();
      debugPrint('Fetching image with key: $imageKey');
      final result = await _cmd!.send_object(['JSON.GET', 'images', '.$imageKey']);
      debugPrint('Successfully retrieved image data');
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
      await connect();
      // Fix the Redis error by properly structuring the data
      final jsonData = jsonEncode({uuid: data});
      debugPrint('Updating user data for UUID: $uuid');
      debugPrint('Data to be saved: $jsonData');
      
      // Create the root object first if it doesn't exist
      await _cmd!.send_object([
        'JSON.SET',
        username,
        '.',
        '{}',
        'NX'  // Only set if it doesn't exist
      ]);
      
      // Then update the specific UUID path
      await _cmd!.send_object([
        'JSON.SET',
        username,
        '.$uuid',
        jsonEncode(data)
      ]);
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