# Rapport synthétique – WaveControl

## 1. Choix des outils

### Flutter / Dart
Le projet a été développé avec Flutter et Dart pour une raison principale : disposer d’une application mobile unique qui fonctionne à la fois sur iOS et Android.

Ce choix permet :
- de partager la même base de code,
- de réduire le temps de développement,
- de simplifier la maintenance.

### Visual Studio Code
Visual Studio Code a été utilisé comme environnement de développement car il est léger, pratique pour Flutter, et bien intégré à GitHub Copilot.

### Pourquoi GitHub Copilot
Copilot a été un vrai accélérateur dans ce projet.

Contexte de travail :
- le langage Dart n’était pas maîtrisé au départ,
- le projet devait être réalisé en environ 3 mois,
- il fallait produire rapidement un résultat fonctionnel.

Copilot a aidé à :
- gagner du temps sur la syntaxe et la structure du code,
- avancer malgré la montée en compétence sur un nouveau langage,
- rester efficace grâce à une expérience déjà positive avec cet outil.

## 2. Rôle de l’application

L’application WaveControl a pour rôle de centraliser la gestion du système autour de la base station.

Fonctions principales :
- configurer la base station,
- ajouter et gérer des configurations,
- ajouter et gérer des télécommandes IR,
- monitorer l’état du système,
- piloter les équipements.

En résumé, l’application sert à la fois à configurer, superviser et commander l’installation.

## 3. Utilisateurs : 3 modes

L’application est organisée autour de 3 modes d’utilisation :

- Mode Utilisateur : accès aux fonctions essentielles de supervision et d’usage quotidien.
- Mode Technicien : accès intermédiaire pour la configuration et les réglages opérationnels.
- Mode Développeur : accès avancé pour les fonctions techniques et les tests.

Cette séparation permet d’adapter l’interface au profil et d’éviter des manipulations sensibles par des utilisateurs non techniques.

## 4. Mode de communication

### Wi-Fi + Base Station
Le smartphone communique avec la base station via le réseau Wi-Fi (connectivité IP).

### Communication MQTT
Une fois la connectivité Wi-Fi active, la logique métier passe par un service central : `MQTTService` (singleton + `ChangeNotifier`).

#### 4.1 Établissement de session MQTT (dans le code)

Au lancement de l’application, le code appelle :
- `MQTTService().connect(...)`
- puis, si la connexion réussit : `publishMessage('home/matter/request', 'test')`

Concrètement, la session est configurée avec :
- `MqttServerClient` (package `mqtt_client`),
- `keepAlivePeriod = 60`,
- authentification utilisateur/mot de passe,
- Last Will sur `home/status` (message `Offline`),
- publication `Online` sur `home/status` après connexion.

Ce mécanisme permet de connaître l’état de présence du client côté broker.

#### 4.2 Abonnements et topics suivis

Après connexion, l’application s’abonne à :
- `home/#` (écoute large),
- `home/+/state`,
- `home/+/status`,
- `home/+/color`.

L’objectif est de recevoir à la fois :
- les réponses globales (ex: inventaire d’équipements),
- les mises à jour fines d’état (ON/OFF, luminosité, couleur),
- les retours fonctionnels bracelet/IR.

#### 4.3 Publication de commandes depuis l’UI (exemples concrets)

Dans ton code, l’UI ne publie pas directement partout : elle passe majoritairement par des helpers du service.

Exemples réels :
- `setBrightness(topic, brightness)` : conversion 0–100 vers 0–255 puis publication vers `.../brightness/set`.
- `setRgbColor(topic, r, g, b)` : publication vers `.../color/set` avec payload `r,g,b`.
- `publishMessage(topic, message)` : méthode générique utilisée dans les écrans de configuration.

Exemples de topics utilisés dans tes écrans :
- `home/wristband/request` pour demander les possibilités,
- `home/wristband/get_config` pour lire la config existante,
- `home/wristband/config` pour envoyer la configuration,
- `home/remote/saved`, `home/remote/new`, `home/IR/feedback` pour les télécommandes IR.

#### 4.4 Traitement des messages entrants et mise à jour des états

La méthode `_handleIncomingMessage(topic, payload)` centralise le parsing entrant.

Deux traitements importants :

1. **Réponse inventaire équipements** (`home/matter/response`)  
	- parsing JSON de la liste,  
	- création/mise à jour de `deviceStates`,  
	- extraction de `state`, `brightness`, `rgb_color`,  
	- suppression des équipements absents dans la nouvelle réponse.

2. **Mises à jour incrémentales par topic**  
	- lecture du topic (ex: `home/lum_1/brightness/state`),  
	- mise à jour ciblée du `DeviceState` concerné,  
	- notification UI via `notifyListeners()`.

Le service ignore volontairement les topics de périphériques non connus pour éviter de polluer l’état local.

#### 4.5 Canal spécialisé bracelet/IR dans ton architecture

Pour les flux bracelet/IR, le service stocke les messages récents dans `recentMessages` (limités aux 50 derniers).  
Ensuite, des écrans comme `configuration_screen.dart`, `view_configs_screen.dart` et `ir_device_detail_screen.dart` lisent cette file et appliquent un traitement métier avec déduplication (`topic + message + timestamp`).

Ce choix permet :
- de garder un service MQTT générique,
- et de laisser la logique métier spécifique au niveau des écrans concernés.

#### 4.6 Robustesse réseau et reconnexion automatique

Le service écoute les changements de connectivité (`connectivity_plus`).  
Si le réseau revient après coupure, une reconnexion MQTT automatique est tentée avec les paramètres sauvegardés.

Après reconnexion :
- l’UI est notifiée,
- une requête `home/matter/request` est relancée pour resynchroniser les états.

En parallèle, un polling de puissance bracelet est effectué toutes les 30 secondes via `home/wristband/request/power`, et la réponse `home/wristband/feedback/power` est parsée puis exposée via `batteryStatusNotifier`.

#### 4.7 Pourquoi ce design MQTT est pertinent

- Service unique = point central de vérité pour les états,
- UI réactive via `ChangeNotifier` / `ValueNotifier`,
- séparation claire entre transport MQTT et logique métier écran,
- bonne résilience en cas de coupure réseau.

## 5. Organisation du projet (arborescence)

Présenter l’arborescence du code est pertinent dans un rapport technique, à condition de rester synthétique. L’objectif n’est pas de lister tous les fichiers, mais de montrer la logique d’organisation.

Extrait d’arborescence utile :

```text
lib/
	main.dart                 -> point d’entrée de l’application
	screens/                  -> écrans (Home, Settings, Monitoring, Configuration, IR...)
	services/                 -> logique applicative (MQTT, paramètres, connectivité)
	models/                   -> structures de données (états, configurations)
	widgets/                  -> composants UI réutilisables
	theme/                    -> thème visuel (couleurs, styles)
```

Pourquoi cette structure est importante :
- elle sépare clairement l’interface et la logique métier,
- elle facilite la maintenance et l’évolution du projet,
- elle aide un nouveau développeur à comprendre rapidement le code.

### Détail du dossier `screens/`

Le dossier `screens/` regroupe les pages visibles par l’utilisateur et les parcours de navigation.

- `splash_screen.dart` : écran de démarrage et transition vers l’accueil.
- `home_screen.dart` : hub principal, état global et accès aux modules selon le mode.
- `settings_screen.dart` : paramètres généraux (mode, MQTT, préférences).
- `monitoring_screen.dart` : supervision des équipements et retours d’état.
- `configuration_screen.dart` : configuration bracelet et associations geste → action.
- `view_configs_screen.dart` : consultation des configurations existantes.
- `mqtt_control_page.dart` : page technique de test MQTT (mode développeur).
- `add_ir_screen.dart`, `IR_configuration_screen.dart`, `periph_saved_screen.dart`, `ir_device_detail_screen.dart` : gestion des télécommandes IR (ajout, liste, détail, maintenance).

En résumé, `screens/` porte l’expérience utilisateur et la logique de navigation.

### Détail du dossier `services/`

Le dossier `services/` centralise la logique transverse et la communication.

- `mqtt_service.dart` : connexion au broker MQTT, abonnement aux topics, publication des commandes, réception des messages, exposition des états utiles à l’UI.
- `app_settings.dart` : gestion des préférences persistantes (mode utilisateur, paramètres de connexion, thème, langue, etc.).

Ce dossier est le cœur technique de l’application : les écrans consomment ces services au lieu de gérer directement le réseau et le stockage.

### Détail du dossier `models/`

Le dossier `models/` contient les structures de données métier manipulées dans les écrans et services.

- `device_state.dart` : représentation d’un équipement (identifiant, état, propriétés d’affichage, métadonnées).
- `wristband_config.dart` : structures liées aux configurations du bracelet (gestes, actions, statuts).
- `config_item.dart` : modèle d’élément de configuration utilisé dans les flux de paramétrage.
- `command_history.dart` : modèle d’historique des commandes/messages pour le suivi et le diagnostic.

Le rôle des modèles est de standardiser les données échangées entre UI et services, afin de limiter les erreurs et faciliter l’évolution du code.

## 6. Conclusion

Le choix Flutter/Dart, combiné à Visual Studio Code et Copilot, a permis de livrer une application mobile multiplateforme dans un délai court.

WaveControl répond au besoin métier principal : configurer la base station, gérer les configurations et télécommandes IR, monitorer le système et piloter les équipements, avec une architecture d’usage claire basée sur 3 modes et une communication Wi-Fi/MQTT efficace.
