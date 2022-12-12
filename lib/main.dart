// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_midi/flutter_midi.dart';
import 'package:sensors_plus/sensors_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sensors Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, this.title}) : super(key: key);

  final String? title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<double>? _gyroscopeValues;
  final _streamSubscriptions = <StreamSubscription<dynamic>>[];

  late final FlutterMidi _flutterMidi;

  int previousSound = 21;

  @override
  Widget build(BuildContext context) {
    final gyroscope =
        _gyroscopeValues?.map((double v) => v.toStringAsFixed(1)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sensor Example'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(width: 1.0, color: Colors.black38),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('Gyroscope: $gyroscope'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    for (final subscription in _streamSubscriptions) {
      subscription.cancel();
    }
  }

  @override
  void initState() {
    super.initState();
    _load('assets/yamaha.sf2');

    _streamSubscriptions.add(
      gyroscopeEvents.expand<int>((GyroscopeEvent event) {
        if (event.x.abs() > 0.0) {
          final newSound = (50 + event.x * 50.0).clamp(21, 108).toInt();
          final isUp = previousSound < newSound;
          final diff =
              isUp ? newSound - previousSound  : previousSound- newSound;
          setState(() {
            _gyroscopeValues = <double>[event.x, event.y, event.z];
          });

          debugPrint(diff.toString());
          return List.generate(diff.abs(),
              (index) => isUp ? previousSound + index : previousSound - index);
        } else {
          _flutterMidi.stopMidiNote(midi: previousSound);
          return [21];
        }
      }).asyncMap((event) async {
        await Future.delayed(const Duration(milliseconds: 75));
        return event;
      })
          .listen((sound) {
        _flutterMidi.stopMidiNote(midi: previousSound);
        if (sound != 21) {
          setState(() {
            previousSound = sound;
          });
          _flutterMidi.playMidiNote(midi: sound);
        }
      }),
    );
  }

  void _load(String asset) async {
    _flutterMidi = FlutterMidi();
    _flutterMidi.unmute();
    final byte = await rootBundle.load(asset);
    _flutterMidi.prepare(sf2: byte);
  }
}
