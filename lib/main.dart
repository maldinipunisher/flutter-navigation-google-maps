import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const Mat());
}

class Mat extends StatelessWidget {
  const Mat({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MyApp(),
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({Key key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  GoogleMapController _mapController;
  LatLng lat;
  final startAddressController = TextEditingController();
  final destinationAddressController = TextEditingController();

  LatLng _startPosition;
  LatLng _destinationPosition;

  Set<Marker> markers = {};
  String _startAddress;
  String _destinationAddress;
  final Set<Polyline> _polylines = {};
  List<LatLng> polylineCoordinates = [];
  PolylinePoints polylinePoints = PolylinePoints();
  Placemark _startPlaceMark;
  Placemark _destinationPlaceMark;

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _mapController.animateCamera(CameraUpdate.newLatLngZoom(lat, 20));
  }

  void _addMarker(LatLng point) {
    setState(() {
      Marker destinationMarker = Marker(
        markerId: MarkerId(point.toString()),
        position: point,
        infoWindow: InfoWindow(
          title: 'Destination ${point.toString()}',
        ),
        icon: BitmapDescriptor.defaultMarker,
      );
      _destinationPosition = point;
      markers.clear();
      markers.add(destinationMarker);
    });
  }

  Future<Placemark> _getAddress(LatLng latLng) async {
    final result =
        await placemarkFromCoordinates(latLng.latitude, latLng.longitude);
    return result.first;
  }

  void setPolylines() async {
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        "YOUR-API-KEY",
        PointLatLng(_startPosition.latitude, _startPosition.longitude),
        PointLatLng(
            _destinationPosition.latitude, _destinationPosition.longitude));
    setState(() {
      _polylines.clear();
      polylineCoordinates.clear();
    });
    if (result.points.isNotEmpty) {
      result.points.map((point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }).toList();
    }

    setState(() {
      Polyline polyline = Polyline(
          polylineId: const PolylineId("poly"),
          color: const Color.fromARGB(255, 40, 122, 198),
          points: polylineCoordinates);

      _polylines.add(polyline);
    });
  }

  Future<PermissionStatus> getPermissions() async {
    try {
      await Permission.location.request();
      return Permission.location.status;
    } catch (e) {
      return Future.error("Permission Error : $e");
    }
  }

  @override
  void initState() {
    getPermissions().then((status) {
      if (status.isGranted) {
        Geolocator.getCurrentPosition().then((offset) {
          setState(() {
            lat = LatLng(offset.latitude, offset.longitude);
            _getAddress(lat).then((placemark) {
              setState(() {
                _startPlaceMark = placemark;
                _startAddress =
                    "${_startPlaceMark.name}, ${_startPlaceMark.country}";
              });
            });
          });
        });
      } else {
        getPermissions();
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Google Maps Testing"),
        ),
        body: Stack(
          children: [
            (lat == null)
                ? SpinKitFadingCircle(
                    color: Colors.primaries.first,
                  )
                : GoogleMap(
                    polylines: _polylines,
                    markers: Set<Marker>.from(markers),
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    mapType: MapType.normal,
                    zoomControlsEnabled: false,
                    zoomGesturesEnabled: true,
                    initialCameraPosition:
                        CameraPosition(target: lat, zoom: 20),
                    onMapCreated: _onMapCreated,
                    onLongPress: (point) {
                      _addMarker(point);
                      Future.delayed(const Duration(seconds: 1), () {
                        _getAddress(point).then((placemark) {
                          setState(() {
                            _destinationPlaceMark = placemark;
                            _destinationAddress =
                                "${_destinationPlaceMark.name}, ${_destinationPlaceMark.country}";
                          });
                        });
                      });
                    },
                  ),
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding:
                    const EdgeInsets.only(top: 700, bottom: 100, right: 50),
                child: Column(
                  children: [
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: FloatingActionButton(
                        elevation: 0,
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.transparent,
                        onPressed: () async {
                          setState(() {
                            _startPosition = lat;

                            double miny = (_startPosition.latitude <=
                                    _destinationPosition.latitude)
                                ? _startPosition.latitude
                                : _destinationPosition.latitude;
                            double minx = (_startPosition.longitude <=
                                    _destinationPosition.longitude)
                                ? _startPosition.longitude
                                : _destinationPosition.longitude;
                            double maxy = (_startPosition.latitude <=
                                    _destinationPosition.latitude)
                                ? _destinationPosition.latitude
                                : _startPosition.latitude;
                            double maxx = (_startPosition.longitude <=
                                    _destinationPosition.longitude)
                                ? _destinationPosition.longitude
                                : _startPosition.longitude;

                            double southWestLatitude = miny;
                            double southWestLongitude = minx;

                            double northEastLatitude = maxy;
                            double northEastLongitude = maxx;
                            _mapController.animateCamera(
                              CameraUpdate.newLatLngBounds(
                                LatLngBounds(
                                  northeast: LatLng(
                                      northEastLatitude, northEastLongitude),
                                  southwest: LatLng(
                                      southWestLatitude, southWestLongitude),
                                ),
                                210.0,
                              ),
                            );
                            setPolylines();
                          });
                        },
                        child: const Icon(Icons.arrow_upward,
                            size: 50, color: Colors.black),
                      ),
                    ),
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: FloatingActionButton(
                        elevation: 0,
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.transparent,
                        onPressed: () {
                          setState(() {
                            _mapController.animateCamera(
                                CameraUpdate.newLatLngZoom(lat, 20));
                            _getAddress(lat);
                          });
                        },
                        child: const Icon(Icons.gps_fixed,
                            size: 50, color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height * 15 / 100,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(_destinationAddress ?? "No Destination"),
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Icon(Icons.arrow_upward),
                  ),
                  Text(_startAddress ?? "No Start"),
                ],
              ),
            )
          ],
        ));
  }
}
