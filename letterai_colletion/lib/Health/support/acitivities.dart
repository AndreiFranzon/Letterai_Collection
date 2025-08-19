enum HealthWorkoutActivityType {
  AMERICAN_FOOTBALL,
  ARCHERY,
  AUSTRALIAN_FOOTBALL,
  BADMINTON,
  BASEBALL,
  BASKETBALL,
  BIKING,
  BOXING,
  CRICKET,
  CROSS_COUNTRY_SKIING,
  CURLING,
  DOWNHILL_SKING,
  ELLIPTICAL,
  FENCING,
  GOLF,
  GYMNASTICS,
  HANDBALL,
  HIGH_INTENSITY_INTERVAL_TRAINING,
  HIKING,
  HOCKEY,
  JUMP_ROPE,
  KICKBOXING,
  MARTIAL_ARTS,
  PILATES,
  RACQUETBALL,
  ROWING,
  RUGBY,
  RUNNING,
  SAILING,
  SKATING,
  SNOWBOARDING,
  SOCCER,
  SOFTBALL,
  SQUASH,
  STAIR_CLIMBING,
  SWIMMING,
  TABLE_TENNIS,
  TENNIS,
  VOLLEYBALL,
  WALKING,
  WATER_POLO,
  YOGA,
  BARRE,
  BOWLING,
  CARDIO_DANCE,
  CLIMBING,
  COOLDOWN,
  CORE_TRAINING,
  CROSS_TRAINING,
  DISC_SPORTS,
  EQUESTRIAN_SPORTS,
  FISHING,
  FITNESS_GAMING,
  FLEXIBILITY,
  FUNCTIONAL_STRENGTH_TRAINING,
  HAND_CYCLING,
  HUNTING,
  LACROSSE,
  MIND_AND_BODY,
  MIXED_CARDIO,
  PADDLE_SPORTS,
  PICKLEBALL,
  PLAY,
  PREPARATION_AND_RECOVERY,
  SNOW_SPORTS,
  SOCIAL_DANCE,
  STAIRS,
  STEP_TRAINING,
  SURFING,
  TAI_CHI,
  TRACK_AND_FIELD,
  TRADITIONAL_STRENGTH_TRAINING,
  WATER_FITNESS,
  WATER_SPORTS,
  WHEELCHAIR_RUN_PACE,
  WHEELCHAIR_WALK_PACE,
  WRESTLING,
  UNDERWATER_DIVING,
  BIKING_STATIONARY,
  CALISTHENICS,
  DANCING,
  FRISBEE_DISC,
  GUIDED_BREATHING,
  ICE_SKATING,
  PARAGLIDING,
  ROCK_CLIMBING,
  ROWING_MACHINE,
  RUNNING_TREADMILL,
  SCUBA_DIVING,
  SKIING,
  SNOWSHOEING,
  STAIR_CLIMBING_MACHINE,
  STRENGTH_TRAINING,
  SWIMMING_OPEN_WATER,
  SWIMMING_POOL,
  WALKING_TREADMILL,
  WEIGHTLIFTING,
  WHEELCHAIR,
  OTHER,
}

// Função que retorna um mapa de ID para cada atividade
Map<HealthWorkoutActivityType, int> gerarMapaAtividades() {
  final Map<HealthWorkoutActivityType, int> mapa = {};
  int id = 1; // Começa do 1, você pode ajustar

  for (var atividade in HealthWorkoutActivityType.values) {
    mapa[atividade] = id;
    id++;
  }

  return mapa;
}

// Função que retorna uma atividade para cada ID
Map<int, String> gerarNomeAtividades() {
  final Map<int, String> gerarMapaAtividades = {};
  int id =1;

  for (var atividade in HealthWorkoutActivityType.values) {
    gerarMapaAtividades[id] = atividade.toString().split('.').last;
    id ++;
  }

  return gerarMapaAtividades;
}

String getNomeExercicio(int id) {
  final nomeAtividade = gerarNomeAtividades();
  final atividade = nomeAtividade[id];
  return atividade != null ? atividade.toString().split('.').last: "Desconhecido";
}
