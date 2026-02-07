import 'package:get/get.dart';

import '../modules/auth/bindings/auth_binding.dart';
import '../modules/auth/views/auth_view.dart';
import '../modules/confessions/bindings/confessions_binding.dart';
import '../modules/confessions/views/confessions_view.dart';
import '../modules/feed/bindings/feed_binding.dart';
import '../modules/feed/views/feed_view.dart';
import '../modules/groups/bindings/groups_binding.dart';
import '../modules/groups/views/groups_view.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/messages/bindings/messages_binding.dart';
import '../modules/messages/views/messages_view.dart';
import '../modules/monetization/bindings/monetization_binding.dart';
import '../modules/monetization/views/monetization_view.dart';
import '../modules/premium/bindings/premium_binding.dart';
import '../modules/premium/views/premium_view.dart';
import '../modules/profile/bindings/profile_binding.dart';
import '../modules/profile/views/profile_view.dart';
import '../modules/promotions/bindings/promotions_binding.dart';
import '../modules/promotions/views/promotions_view.dart';
import '../modules/search/bindings/search_binding.dart';
import '../modules/search/views/search_view.dart';
import '../modules/settings/bindings/settings_binding.dart';
import '../modules/settings/views/settings_view.dart';
import '../modules/stories/bindings/stories_binding.dart';
import '../modules/stories/views/stories_view.dart';
import '../modules/wallet/bindings/wallet_binding.dart';
import '../modules/wallet/views/wallet_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.HOME;

  static final routes = [
    GetPage(
      name: _Paths.HOME,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: _Paths.AUTH,
      page: () => const AuthView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: _Paths.FEED,
      page: () => const FeedView(),
      binding: FeedBinding(),
    ),
    GetPage(
      name: _Paths.PROFILE,
      page: () => const ProfileView(),
      binding: ProfileBinding(),
    ),
    GetPage(
      name: _Paths.MESSAGES,
      page: () => const MessagesView(),
      binding: MessagesBinding(),
    ),
    GetPage(
      name: _Paths.SEARCH,
      page: () => const SearchView(),
      binding: SearchBinding(),
    ),
    GetPage(
      name: _Paths.SETTINGS,
      page: () => const SettingsView(),
      binding: SettingsBinding(),
    ),
    GetPage(
      name: _Paths.WALLET,
      page: () => const WalletView(),
      binding: WalletBinding(),
    ),
    GetPage(
      name: _Paths.PREMIUM,
      page: () => const PremiumView(),
      binding: PremiumBinding(),
    ),
    GetPage(
      name: _Paths.MONETIZATION,
      page: () => const MonetizationView(),
      binding: MonetizationBinding(),
    ),
    GetPage(
      name: _Paths.CONFESSIONS,
      page: () => const ConfessionsView(),
      binding: ConfessionsBinding(),
    ),
    GetPage(
      name: _Paths.GROUPS,
      page: () => const GroupsView(),
      binding: GroupsBinding(),
    ),
    GetPage(
      name: _Paths.STORIES,
      page: () => const StoriesView(),
      binding: StoriesBinding(),
    ),
    GetPage(
      name: _Paths.PROMOTIONS,
      page: () => const PromotionsView(),
      binding: PromotionsBinding(),
    ),
  ];
}
