class WristbandDevice {
  final String entityId;
  final String friendlyName;
  final String state;
  final String type;
  final List<String>? capabilities;

  WristbandDevice({
    required this.entityId,
    required this.friendlyName,
    required this.state,
    required this.type,
    this.capabilities,
  });

  factory WristbandDevice.fromJson(Map<String, dynamic> json) {
    return WristbandDevice(
      entityId: json['entity_id'],
      friendlyName: json['friendly_name'],
      state: json['state'],
      type: json['type'],
      capabilities: json['capabilities'] != null
          ? List<String>.from(json['capabilities'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'entity_id': entityId,
      'friendly_name': friendlyName,
      'state': state,
      'type': type,
      if (capabilities != null) 'capabilities': capabilities,
    };
  }
}

class WristbandPossibility {
  final List<WristbandDevice> devices;
  final List<String> movements;

  WristbandPossibility({
    required this.devices,
    required this.movements,
  });

  factory WristbandPossibility.fromJson(Map<String, dynamic> json) {
    return WristbandPossibility(
      devices: (json['devices'] as List)
          .map((device) => WristbandDevice.fromJson(device))
          .toList(),
      movements: List<String>.from(json['movements']),
    );
  }
}

class WristbandConfig {
  final String mouvement;
  final String entityId;
  final String actionType;

  WristbandConfig({
    required this.mouvement,
    required this.entityId,
    required this.actionType,
  });

  factory WristbandConfig.fromJson(Map<String, dynamic> json) {
    return WristbandConfig(
      mouvement: json['mouvement'],
      entityId: json['entity_id'],
      actionType: json['action_type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mouvement': mouvement,
      'entity_id': entityId,
      'action_type': actionType,
    };
  }
}

class WristbandConfigStatus {
  final String status;
  final String message;

  WristbandConfigStatus({
    required this.status,
    required this.message,
  });

  factory WristbandConfigStatus.fromJson(Map<String, dynamic> json) {
    return WristbandConfigStatus(
      status: json['status'],
      message: json['message'],
    );
  }
}

class WristbandExecutionStatus {
  final String status;
  final String movement;
  final String entityId;
  final String action;

  WristbandExecutionStatus({
    required this.status,
    required this.movement,
    required this.entityId,
    required this.action,
  });

  factory WristbandExecutionStatus.fromJson(Map<String, dynamic> json) {
    return WristbandExecutionStatus(
      status: json['status'],
      movement: json['movement'],
      entityId: json['entity_id'],
      action: json['action'],
    );
  }
}