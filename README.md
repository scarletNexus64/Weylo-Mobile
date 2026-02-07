<div align="center">

<img src="assets/images/logo.png" alt="Weylo Logo" width="200"/>

# 🔐 Weylo Mobile

**Application de messagerie anonyme et sociale**

[![Flutter](https://img.shields.io/badge/Flutter-3.10+-02569B?logo=flutter)](https://flutter.dev)
[![GetX](https://img.shields.io/badge/GetX-4.7.3-9C27B0?logo=flutter)](https://pub.dev/packages/get)
[![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-Private-red)]()

*Une plateforme sociale innovante permettant aux utilisateurs de s'exprimer librement et de se connecter de manière authentique.*

[Fonctionnalités](#-fonctionnalités) • [Architecture](#-architecture) • [Installation](#-installation) • [Documentation](#-documentation)

</div>

---

## 📱 À Propos

**Weylo** est une application mobile sociale de nouvelle génération qui combine la messagerie instantanée, le partage de contenus éphémères, et des fonctionnalités sociales uniques dans une seule plateforme.

### 🎯 Vision

Créer un espace où les utilisateurs peuvent:
- 💬 Communiquer de manière authentique
- 🤫 Partager des confessions anonymes
- 📸 Poster des stories éphémères
- 👥 Rejoindre des communautés
- 💰 Monétiser leur contenu

---

## ✨ Fonctionnalités

### 🔐 Authentification
- Inscription/Connexion sécurisée
- Authentification par email/téléphone
- Récupération de mot de passe
- Sessions persistantes

### 💬 Messagerie
- Messages privés en temps réel
- Chat de groupe
- Envoi de médias (photos, vidéos, audio)
- Messages vocaux avec effets
- Statuts en ligne

### 🤫 Confessions
- Posts anonymes
- Système de votes
- Commentaires
- Partage social
- Modération intelligente

### 📸 Stories
- Stories éphémères (24h)
- Photos et vidéos
- Filtres et stickers
- Réponses aux stories
- Statistiques de vues

### 👥 Groupes
- Création de groupes
- Gestion des membres
- Conversations de groupe
- Rôles et permissions

### 💰 Monétisation
- Abonnements premium
- Promotions de posts
- Cadeaux virtuels
- Portefeuille intégré
- Système de gains

### ⚙️ Paramètres
- Gestion du profil
- Préférences de confidentialité
- Notifications personnalisables
- Thème clair/sombre
- Multi-langue (FR/EN)

---

## 🏗️ Architecture

### Stack Technique

```
Flutter 3.10+
    ├── GetX 4.7.3          (State Management & Navigation)
    ├── Dio                 (HTTP Client)
    ├── WebSockets          (Real-time Communication)
    ├── Firebase            (Push Notifications)
    └── Shared Preferences  (Local Storage)
```

### Pattern: GetX Pattern (MVC)

```
lib/
├── bindings/               # Dependency Injection
│   └── initial_binding.dart
│
├── controllers/            # Global Controllers
│   ├── theme_controller.dart
│   └── locale_controller.dart
│
├── core/                   # Core Utilities
│   ├── constants/
│   ├── theme/
│   ├── utils/
│   └── errors/
│
├── data/                   # Data Layer
│   ├── models/            # Data Models
│   └── providers/         # API Services
│
├── modules/               # Feature Modules
│   ├── auth/             # 🔐 Authentication
│   ├── feed/             # 📰 Feed
│   ├── profile/          # 👤 Profile
│   ├── messages/         # 💬 Messages
│   ├── confessions/      # 🤫 Confessions
│   ├── stories/          # 📸 Stories
│   ├── groups/           # 👥 Groups
│   ├── wallet/           # 💰 Wallet
│   ├── premium/          # ⭐ Premium
│   ├── settings/         # ⚙️  Settings
│   └── ...
│
├── routes/               # Navigation
│   ├── app_pages.dart
│   └── app_routes.dart
│
└── main.dart            # Entry Point
```

### Modules (14)

Chaque module suit la structure MVC:
```
module_name/
├── bindings/
│   └── module_binding.dart     # DI
├── controllers/
│   └── module_controller.dart  # Business Logic
└── views/
    └── module_view.dart        # UI
```

---

## 🚀 Installation

### Prérequis

- Flutter SDK 3.10 ou supérieur
- Dart 3.0 ou supérieur
- Android Studio / Xcode
- Git

### Étapes

1. **Cloner le projet**
```bash
git clone https://github.com/votre-username/weylo-mobile.git
cd weylo-mobile
```

2. **Installer les dépendances**
```bash
flutter pub get
```

3. **Configurer l'environnement**
```bash
# Copier le fichier de configuration
cp .env.example .env

# Éditer avec vos clés API
nano .env
```

4. **Lancer l'application**
```bash
# Development
flutter run

# Production
flutter run --release
```

---

## 🔧 Configuration

### Variables d'Environnement

Créer un fichier `.env` à la racine:

```env
API_BASE_URL=https://api.weylo.com
WEBSOCKET_URL=wss://ws.weylo.com
PUSHER_KEY=your_pusher_key
PUSHER_CLUSTER=eu
```

### API Backend

L'application nécessite un backend compatible. Endpoints requis:

```
POST   /api/auth/login
POST   /api/auth/register
GET    /api/user/profile
POST   /api/messages
GET    /api/stories
...
```

---

## 📚 Documentation

### Guides Disponibles

- **[STRUCTURE_FINALE.md](STRUCTURE_FINALE.md)** - Architecture complète
- **[GETX_MIGRATION_GUIDE.md](GETX_MIGRATION_GUIDE.md)** - Guide de migration GetX
- **[REFACTORING_SUMMARY.md](REFACTORING_SUMMARY.md)** - Résumé du refactoring
- **[NEXT_STEPS.md](NEXT_STEPS.md)** - Prochaines étapes
- **[CORRECTIONS_EFFECTUEES.md](CORRECTIONS_EFFECTUEES.md)** - Corrections appliquées

### GetX CLI

Le projet utilise GetX CLI pour générer du code:

```bash
# Installer GetX CLI
flutter pub global activate get_cli

# Créer un nouveau module
get create page:module_name

# Créer une vue
get create view:view_name on module_name

# Créer un controller
get create controller:controller_name on module_name
```

---

## 🎨 Design System

### Thèmes

- **Light Mode** - Interface claire et moderne
- **Dark Mode** - Mode sombre pour réduire la fatigue oculaire

### Couleurs Principales

```dart
Primary:    #9C27B0 (Violet)
Secondary:  #FF4081 (Rose)
Success:    #4CAF50 (Vert)
Error:      #F44336 (Rouge)
Warning:    #FF9800 (Orange)
```

### Composants

- Custom Buttons
- Custom Text Fields
- Avatar Widgets
- Loading Indicators
- Empty States
- Premium Badges

---

## 🧪 Tests

```bash
# Lancer tous les tests
flutter test

# Tests unitaires
flutter test test/unit

# Tests de widgets
flutter test test/widgets

# Tests d'intégration
flutter test test/integration

# Coverage
flutter test --coverage
```

---

## 📦 Build & Deploy

### Android

```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# App Bundle (Play Store)
flutter build appbundle --release
```

### iOS

```bash
# Debug
flutter build ios --debug

# Release
flutter build ios --release
```

---

## 🤝 Contribution

Les contributions sont les bienvenues! Voici comment contribuer:

1. Fork le projet
2. Créer une branche (`git checkout -b feature/AmazingFeature`)
3. Commit les changes (`git commit -m 'Add AmazingFeature'`)
4. Push vers la branche (`git push origin feature/AmazingFeature`)
5. Ouvrir une Pull Request

### Standards de Code

- Respecter la structure GetX Pattern
- Suivre les conventions Dart/Flutter
- Écrire des tests pour les nouvelles fonctionnalités
- Documenter le code avec des commentaires
- Utiliser GetX pour la gestion d'état

---

## 📝 Changelog

### Version 1.0.0 (2026-02-07)

#### ✨ Refactorisation Majeure
- Migration complète vers GetX Pattern
- Restructuration de l'architecture en modules
- Suppression de Provider au profit de GetX
- Migration du routing vers GetX Navigation

#### 🔧 Améliorations
- 14 modules créés avec structure MVC
- 3 controllers globaux (Auth, Theme, Locale)
- Tous les imports corrigés
- 0 erreur de compilation

#### 📚 Documentation
- Documentation complète ajoutée
- Guides de migration créés
- README professionnel

---

## 🐛 Bugs Connus

- [ ] Certains widgets nécessitent une refactorisation (confession_card, stories_bar)
- [ ] Quelques warnings de style à corriger

---

## 🗺️ Roadmap

### Version 1.1
- [ ] Refactoriser les widgets restants
- [ ] Migrer tous les providers vers controllers
- [ ] Compléter toutes les vues
- [ ] Tests unitaires complets

### Version 1.2
- [ ] Dark mode amélioré
- [ ] Animations avancées
- [ ] Performance optimizations
- [ ] Internationalisation complète

### Version 2.0
- [ ] Nouveaux modules (Events, Marketplace)
- [ ] AR Filters pour les stories
- [ ] Voice/Video calls
- [ ] Desktop support

---

## 📄 License

Ce projet est privé et propriétaire. Tous droits réservés.

---

## 👥 Équipe

### Développeurs
- **Développeur Principal** - Architecture & Développement

### Contact
- **Email**: contact@weylo.com
- **Website**: https://weylo.com

---

## 🙏 Remerciements

- [Flutter Team](https://flutter.dev) - Framework incroyable
- [GetX](https://pub.dev/packages/get) - State management simplifié
- [Dio](https://pub.dev/packages/dio) - HTTP client puissant
- La communauté Flutter

---

<div align="center">

**Fait avec ❤️ en utilisant Flutter & GetX**

[⬆ Retour en haut](#-weylo-mobile)

</div>
