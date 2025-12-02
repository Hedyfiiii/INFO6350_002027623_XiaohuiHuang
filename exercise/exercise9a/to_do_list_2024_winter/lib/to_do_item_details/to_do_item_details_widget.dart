import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;
import 'to_do_item_details_model.dart';
export 'to_do_item_details_model.dart';

class ToDoItemDetailsWidget extends StatefulWidget {
  const ToDoItemDetailsWidget({
    super.key,
    required this.title,
    required this.description,
    required this.image,
    this.address,
    this.latitude,
    this.longitude,
  });

  final String? title;
  final String? description;
  final String? image;
  final String? address;
  final double? latitude;
  final double? longitude;

  @override
  State<ToDoItemDetailsWidget> createState() => _ToDoItemDetailsWidgetState();
}

class _ToDoItemDetailsWidgetState extends State<ToDoItemDetailsWidget>
    with TickerProviderStateMixin {
  late ToDoItemDetailsModel _model;
  gmaps.GoogleMapController? _mapController;
  Position? _currentPosition;
  String? _distanceText;
  bool _isLoadingLocation = true;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  final animationsMap = <String, AnimationInfo>{};

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ToDoItemDetailsModel());

    animationsMap.addAll({
      'imageOnPageLoadAnimation': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 600.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
          MoveEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 600.0.ms,
            begin: Offset(0.0, 40.0),
            end: Offset(0.0, 0.0),
          ),
          ScaleEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 600.0.ms,
            begin: Offset(0.6, 0.6),
            end: Offset(1.0, 1.0),
          ),
        ],
      ),
      'textOnPageLoadAnimation1': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 600.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
          MoveEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 600.0.ms,
            begin: Offset(50.0, 0.0),
            end: Offset(0.0, 0.0),
          ),
        ],
      ),
      'textOnPageLoadAnimation2': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          VisibilityEffect(duration: 1.ms),
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 600.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
          MoveEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 600.0.ms,
            begin: Offset(60.0, 0.0),
            end: Offset(0.0, 0.0),
          ),
        ],
      ),
      'textOnPageLoadAnimation3': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          VisibilityEffect(duration: 100.ms),
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 100.0.ms,
            duration: 600.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
          MoveEffect(
            curve: Curves.easeInOut,
            delay: 100.0.ms,
            duration: 600.0.ms,
            begin: Offset(60.0, 0.0),
            end: Offset(0.0, 0.0),
          ),
        ],
      ),
    });

    _loadCurrentLocation();
  }

  Future<void> _loadCurrentLocation() async {
    if (widget.latitude != null && widget.longitude != null) {
      try {
        // Check if location services are enabled
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          setState(() => _isLoadingLocation = false);
          return;
        }

        // Check permission
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            setState(() => _isLoadingLocation = false);
            return;
          }
        }

        if (permission == LocationPermission.deniedForever) {
          setState(() => _isLoadingLocation = false);
          return;
        }

        // Get current position
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        if (mounted) {
          setState(() {
            _currentPosition = position;
            final distance = Geolocator.distanceBetween(
              position.latitude,
              position.longitude,
              widget.latitude!,
              widget.longitude!,
            );
            _distanceText = _formatDistance(distance);
            _isLoadingLocation = false;
          });
        }
      } catch (e) {
        print('Location error: $e');
        if (mounted) {
          setState(() => _isLoadingLocation = false);
        }
      }
    } else {
      setState(() => _isLoadingLocation = false);
    }
  }

  String _formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.toStringAsFixed(0)} m';
    } else {
      double km = distanceInMeters / 1000;
      return '${km.toStringAsFixed(2)} km';
    }
  }

  void _fitBothMarkers() {
    if (_currentPosition == null || widget.latitude == null) return;

    final bounds = gmaps.LatLngBounds(
      southwest: gmaps.LatLng(
        math.min(_currentPosition!.latitude, widget.latitude!),
        math.min(_currentPosition!.longitude, widget.longitude!),
      ),
      northeast: gmaps.LatLng(
        math.max(_currentPosition!.latitude, widget.latitude!),
        math.max(_currentPosition!.longitude, widget.longitude!),
      ),
    );

    _mapController?.animateCamera(
      gmaps.CameraUpdate.newLatLngBounds(bounds, 100),
    );
  }

  @override
  void dispose() {
    _model.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _model.unfocusNode.canRequestFocus
          ? FocusScope.of(context).requestFocus(_model.unfocusNode)
          : FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
        appBar: AppBar(
          backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
          automaticallyImplyLeading: false,
          leading: FlutterFlowIconButton(
            borderColor: Colors.transparent,
            borderRadius: 30.0,
            borderWidth: 1.0,
            buttonSize: 60.0,
            icon: Icon(
              Icons.arrow_back_rounded,
              color: FlutterFlowTheme.of(context).primaryText,
              size: 30.0,
            ),
            onPressed: () async {
              context.pop();
            },
          ),
          actions: [],
          centerTitle: false,
          elevation: 0.0,
        ),
        body: SafeArea(
          top: true,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(12.0),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image
                        if (widget.image != null && widget.image!.isNotEmpty)
                          Hero(
                            tag: widget.image!,
                            transitionOnUserGestures: true,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: Image.network(
                                widget.image!,
                                width: double.infinity,
                                height: 250.0,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ).animateOnPageLoad(
                              animationsMap['imageOnPageLoadAnimation']!),

                        // Title
                        Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              0.0, 16.0, 0.0, 0.0),
                          child: Text(
                            valueOrDefault<String>(
                              widget.title,
                              'Title',
                            ),
                            style: FlutterFlowTheme.of(context)
                                .displaySmall
                                .override(
                                  fontFamily: 'Outfit',
                                  letterSpacing: 0.0,
                                ),
                          ).animateOnPageLoad(
                              animationsMap['textOnPageLoadAnimation1']!),
                        ),

                        // Description Label
                        Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              4.0, 4.0, 0.0, 0.0),
                          child: Text(
                            'Description',
                            style: FlutterFlowTheme.of(context)
                                .labelMedium
                                .override(
                                  fontFamily: 'Readex Pro',
                                  letterSpacing: 0.0,
                                ),
                          ).animateOnPageLoad(
                              animationsMap['textOnPageLoadAnimation2']!),
                        ),

                        // Description Text
                        Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              4.0, 4.0, 0.0, 0.0),
                          child: AutoSizeText(
                            valueOrDefault<String>(
                              widget.description,
                              'Desc for ToDo Item',
                            ),
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  fontFamily: 'Readex Pro',
                                  letterSpacing: 0.0,
                                ),
                          ).animateOnPageLoad(
                              animationsMap['textOnPageLoadAnimation3']!),
                        ),

                        // Location Section
                        if (widget.address != null && widget.address!.isNotEmpty) ...[
                          // Location Label
                          Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                4.0, 24.0, 0.0, 8.0),
                            child: Text(
                              'Location',
                              style: FlutterFlowTheme.of(context)
                                  .labelMedium
                                  .override(
                                    fontFamily: 'Readex Pro',
                                    fontSize: 16.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),

                          // Address
                          Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                4.0, 0.0, 0.0, 0.0),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  color: FlutterFlowTheme.of(context).primary,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    widget.address!,
                                    style: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          fontFamily: 'Readex Pro',
                                          letterSpacing: 0.0,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Distance Display
                          if (_distanceText != null)
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  0.0, 12.0, 0.0, 0.0),
                              child: Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(12.0),
                                decoration: BoxDecoration(
                                  color: FlutterFlowTheme.of(context)
                                      .secondaryBackground,
                                  borderRadius: BorderRadius.circular(8.0),
                                  border: Border.all(
                                    color:
                                        FlutterFlowTheme.of(context).primary,
                                    width: 2.0,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.directions_car,
                                      color:
                                          FlutterFlowTheme.of(context).primary,
                                      size: 24.0,
                                    ),
                                    SizedBox(width: 12.0),
                                    Text(
                                      'Distance: $_distanceText',
                                      style: FlutterFlowTheme.of(context)
                                          .titleMedium
                                          .override(
                                            fontFamily: 'Readex Pro',
                                            color: FlutterFlowTheme.of(context)
                                                .primary,
                                            letterSpacing: 0.0,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          // Loading indicator
                          if (_isLoadingLocation && _distanceText == null)
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  0.0, 12.0, 0.0, 0.0),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        FlutterFlowTheme.of(context).primary,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Getting your location...',
                                    style: FlutterFlowTheme.of(context)
                                        .bodySmall
                                        .override(
                                          fontFamily: 'Readex Pro',
                                          letterSpacing: 0.0,
                                        ),
                                  ),
                                ],
                              ),
                            ),

                          // Google Map
                          if (widget.latitude != null && widget.longitude != null)
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  0.0, 16.0, 0.0, 0.0),
                              child: Container(
                                height: 300,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12.0),
                                  border: Border.all(
                                    color:
                                        FlutterFlowTheme.of(context).alternate,
                                    width: 2.0,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10.0),
                                  child: gmaps.GoogleMap(
                                    initialCameraPosition: gmaps.CameraPosition(
                                      target: gmaps.LatLng(widget.latitude!, widget.longitude!),
                                      zoom: 15,
                                    ),
                                    markers: {
                                      gmaps.Marker(
                                        markerId:gmaps.MarkerId('todo_location'),
                                        position: gmaps.LatLng(widget.latitude!, widget.longitude!),
                                        infoWindow: gmaps.InfoWindow(
                                          title: widget.title ?? 'ToDo Location',
                                          snippet: widget.address,
                                        ),
                                      ),
                                      if (_currentPosition != null)
                                        gmaps.Marker(
                                          markerId: gmaps.MarkerId('current_location'),
                                          position: gmaps.LatLng(
                                            _currentPosition!.latitude,
                                            _currentPosition!.longitude,
                                          ),
                                          icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
                                            gmaps.BitmapDescriptor.hueBlue,
                                          ),
                                          infoWindow: gmaps.InfoWindow(title: 'Your Location'),
                                        ),
                                    },
                                    myLocationEnabled: true,
                                    myLocationButtonEnabled: true,
                                    zoomControlsEnabled: true,
                                    mapType: gmaps.MapType.normal,
                                    onMapCreated: (controller) {
                                      _mapController = controller;
                                      if (_currentPosition != null) {
                                        Future.delayed(
                                          Duration(milliseconds: 500),
                                          () => _fitBothMarkers(),
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}