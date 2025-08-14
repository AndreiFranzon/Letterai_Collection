import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:letterai_colletion/Health/util.dart';
import 'package:workmanager/workmanager.dart';

import 'package:letterai_colletion/Health/diary_sync/dados_fixos.dart';
import 'package:letterai_colletion/Health/diary_sync/dados_continuos.dart';

import 'package:letterai_colletion/Health/permanent_sync/dados_fixos_perm.dart';
import 'package:letterai_colletion/Health/permanent_sync/dados_continuos_perm.dart';

import 'package:letterai_colletion/Health/graphics/metrics_page.dart';
import 'package:letterai_colletion/Health/graphics/sleep_page.dart';

final health = Health();

const String syncTaskName = "sync_dados_permanentes";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == syncTaskName) {
      await sincronizarDadosFixosPermantentes();
      await sincronizarDadosContinuosPermanentes();
    }
    return Future.value(true);
  });
}

class HealthPage extends StatefulWidget {
  const HealthPage({super.key});

  @override
  HealthPageState createState() => HealthPageState();
}

enum AppState {
  DATA_NOT_FETCHED,
  FETCHING_DATA,
  DATA_READY,
  NO_DATA,
  AUTHORIZED,
  AUTH_NOT_GRANTED,
  DATA_ADDED,
  DATA_DELETED,
  DATA_NOT_ADDED,
  DATA_NOT_DELETED,
  STEPS_READY,
  HEALTH_CONNECT_STATUS,
  PERMISSIONS_REVOKING,
  PERMISSIONS_REVOKED,
  PERMISSIONS_NOT_REVOKED,
}

class HealthPageState extends State<HealthPage> {
  List<HealthDataPoint> _healthDataList = [];
  AppState _state = AppState.DATA_NOT_FETCHED;
  int _nofSteps = 0;
  List<RecordingMethod> recordingMethodsToFilter = [];

  // All types available depending on platform (iOS ot Android).
  List<HealthDataType> get types => (Platform.isAndroid)
      ? dataTypesAndroid
      : (Platform.isIOS)
          ? dataTypesIOS
          : [];

  List<HealthDataAccess> get permissions => types
      .map((type) =>
          // can only request READ permissions to the following list of types on iOS
          [
            HealthDataType.APPLE_MOVE_TIME,
            HealthDataType.APPLE_STAND_HOUR,
            HealthDataType.APPLE_STAND_TIME,
            HealthDataType.WALKING_HEART_RATE,
            HealthDataType.ELECTROCARDIOGRAM,
            HealthDataType.HIGH_HEART_RATE_EVENT,
            HealthDataType.LOW_HEART_RATE_EVENT,
            HealthDataType.IRREGULAR_HEART_RATE_EVENT,
            HealthDataType.EXERCISE_TIME,
          ].contains(type)
              ? HealthDataAccess.READ
              : HealthDataAccess.READ_WRITE)
      .toList();

  @override
  void initState() {
    // configure the health plugin before use and check the Health Connect status
    health.configure();
    health.getHealthConnectSdkStatus();

    super.initState();

    Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: true,
    );

    _registrarAgendamento();
  }

  Future<void> _registrarAgendamento() async {
    final now = DateTime.now();

    final proximaExecucao = DateTime(now.year, now.month, now.day, 0, 5)
      .add(const Duration(days: 1));

    final delay = proximaExecucao.difference(now);

    await Workmanager().registerPeriodicTask(
      "sync-task-id",
      syncTaskName,
      frequency:  const Duration(hours: 24),
      initialDelay: delay,
      constraints: Constraints(
        networkType: NetworkType.connected,
        ),
      );
  }

  Future<void> installHealthConnect() async =>
      await health.installHealthConnect();

  Future<bool> verificarPermissoes(BuildContext context) async {
  if (!Platform.isAndroid) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Apenas Android é suportado no momento.")),
    );
    return false;
  }

  final temPermissoes = await health.hasPermissions(types, permissions: permissions);

  if (temPermissoes != true) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Permissões do Google Health não ativadas. Por favor, ative para sincronizar os dados.",
        ),
      ),
    );
    return false;
  }

  return true;
  }

  Future<void> sincronizarTudo() async {
    setState(() => _state = AppState.FETCHING_DATA);

    final permissoesOk = await verificarPermissoes(context);
    if (!permissoesOk) {
      setState(() => _state = AppState.AUTH_NOT_GRANTED);
      installHealthConnect();
    }

    await sincronizarDadosFixos();
    await sincronizarDadosContinuos();

    setState(() => _state = AppState.DATA_READY);
  }

  Future<void> sincronizarTudoPerm() async {
    setState(() => _state = AppState.FETCHING_DATA);

    final permissoesOk = await verificarPermissoes(context);
    if (!permissoesOk) {
      setState(() => _state = AppState.AUTH_NOT_GRANTED);
      installHealthConnect();
    }

    await sincronizarDadosFixosPermantentes();
    await sincronizarDadosContinuosPermanentes();

    setState(() => _state = AppState.DATA_READY);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Saúde'),
        ),
        body: Column(
          children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MetricsPage()),
                  );
                },
                child: const Text('Ver Métricas'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SleepPage()),
                  );
                },
                child: const Text('Sono'),
              ),
          ],
        ),
        floatingActionButton: Builder(
          builder: (context) => FloatingActionButton(
            child: const Icon(Icons.menu),
            onPressed: () async {
              final RenderBox button = context.findRenderObject() as RenderBox;
              final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

              final Offset buttonTopLeft = button.localToGlobal(Offset.zero, ancestor: overlay);
              // Calculate the bottom-right point of the button in global coordinates
              final Offset buttonBottomRight = button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay);


              const double verticalOffset = 120.0;

              final result = await showMenu<String>(
                context: context,
                position: RelativeRect.fromRect(
                  Rect.fromPoints(
                   buttonTopLeft.translate(0, -verticalOffset), // Move the top-left point up
                  buttonBottomRight.translate(0, -verticalOffset), // Move the bottom-right point up
                ),
                  Offset.zero & overlay.size,
                ),
                items: [
                  const PopupMenuItem(
                    value: 'health',
                    child: Text('Health'),
                  ),
                  const PopupMenuItem(
                    value: 'sync',
                    child: Text('Sincronizar'),
                  ),
                  const PopupMenuItem(
                    value: 'sync_pem',
                    child: Text('SincronizarPerm'),
                  ),
                ],
              );

              if (result == 'health') {
                installHealthConnect();
              } else if (result == 'sync') {
                sincronizarTudo();
              } else if (result == 'sync_pem'){
                sincronizarTudoPerm();
              }
            },
          ),
        ),
      ),
    );
  }
}