import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RecordVoice extends ConsumerStatefulWidget{
  const RecordVoice({super.key});

  @override
  ConsumerState<RecordVoice> createState() => _RecordVoiceState();
}

class _RecordVoiceState extends ConsumerState<RecordVoice> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Text("Record Voice Page Created Successfully"),
    );
  }
}