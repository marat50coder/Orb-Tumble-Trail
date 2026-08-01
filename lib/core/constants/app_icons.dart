import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

/// The single icon vocabulary of the app.
///
/// Everything is drawn from the Material Symbols *rounded* variable font, so
/// glyphs share one skeleton, one corner radius and one optical size. Weight
/// and fill are tuned per usage through [Icon.weight] / [Icon.fill] instead of
/// swapping icon families, which keeps the interface visually quiet.
abstract final class AppIcons {
  // Navigation & chrome
  static const IconData arrowLeft = Symbols.arrow_back_rounded;
  static const IconData arrowRight = Symbols.arrow_forward_rounded;
  static const IconData caretLeft = Symbols.chevron_left_rounded;
  static const IconData caretRight = Symbols.chevron_right_rounded;
  static const IconData collapse = Symbols.unfold_less_rounded;
  static const IconData undo = Symbols.undo_rounded;
  static const IconData refresh = Symbols.refresh_rounded;
  static const IconData more = Symbols.more_horiz_rounded;
  static const IconData close = Symbols.close_rounded;
  static const IconData closeCircle = Symbols.cancel_rounded;
  static const IconData check = Symbols.check_rounded;
  static const IconData checkCircle = Symbols.check_circle_rounded;
  static const IconData plus = Symbols.add_rounded;
  static const IconData plusCircle = Symbols.add_circle_rounded;
  static const IconData minus = Symbols.remove_rounded;
  static const IconData edit = Symbols.edit_rounded;
  static const IconData editNote = Symbols.edit_note_rounded;
  static const IconData trash = Symbols.delete_rounded;
  static const IconData copy = Symbols.content_copy_rounded;
  static const IconData info = Symbols.info_rounded;
  static const IconData warning = Symbols.error_rounded;
  static const IconData block = Symbols.block_rounded;
  static const IconData sliders = Symbols.tune_rounded;
  static const IconData settings = Symbols.settings_rounded;
  static const IconData shield = Symbols.verified_user_rounded;
  static const IconData lock = Symbols.lock_rounded;
  static const IconData lifebuoy = Symbols.support_rounded;
  static const IconData envelope = Symbols.mail_rounded;
  static const IconData image = Symbols.image_rounded;
  static const IconData camera = Symbols.photo_camera_rounded;
  static const IconData userCircle = Symbols.account_circle_rounded;
  static const IconData database = Symbols.database_rounded;
  static const IconData hardDrive = Symbols.storage_rounded;
  static const IconData wifiOff = Symbols.wifi_off_rounded;
  static const IconData phoneOff = Symbols.mobile_off_rounded;
  static const IconData vibrate = Symbols.vibration_rounded;
  static const IconData palette = Symbols.palette_rounded;
  static const IconData paintBrush = Symbols.brush_rounded;
  static const IconData quotes = Symbols.format_quote_rounded;
  static const IconData translate = Symbols.translate_rounded;

  // Trail metaphor
  static const IconData sphere = Symbols.lens_blur_rounded;
  static const IconData circleDashed = Symbols.radio_button_unchecked_rounded;
  static const IconData circlesThree = Symbols.workspaces_rounded;
  static const IconData path = Symbols.route_rounded;
  static const IconData compass = Symbols.explore_rounded;
  static const IconData flag = Symbols.flag_rounded;
  static const IconData target = Symbols.adjust_rounded;
  static const IconData gauge = Symbols.speed_rounded;
  static const IconData lightning = Symbols.bolt_rounded;
  static const IconData fire = Symbols.local_fire_department_rounded;
  static const IconData sparkle = Symbols.auto_awesome_rounded;
  static const IconData rocket = Symbols.rocket_launch_rounded;
  static const IconData crown = Symbols.workspace_premium_rounded;
  static const IconData medal = Symbols.military_tech_rounded;
  static const IconData star = Symbols.star_rounded;
  static const IconData heart = Symbols.favorite_rounded;
  static const IconData stack = Symbols.layers_rounded;
  static const IconData chartBar = Symbols.bar_chart_rounded;
  static const IconData scales = Symbols.balance_rounded;
  static const IconData planet = Symbols.public_rounded;

  // Time
  static const IconData clock = Symbols.schedule_rounded;
  static const IconData alarm = Symbols.alarm_rounded;
  static const IconData bell = Symbols.notifications_active_rounded;
  static const IconData timer = Symbols.timer_rounded;
  static const IconData calendar = Symbols.calendar_month_rounded;
  static const IconData play = Symbols.play_circle_rounded;
  static const IconData pause = Symbols.pause_circle_rounded;

  // Day cycle
  static const IconData sun = Symbols.light_mode_rounded;
  static const IconData sunHorizon = Symbols.wb_twilight_rounded;
  static const IconData moon = Symbols.dark_mode_rounded;
  static const IconData moonStars = Symbols.bedtime_rounded;

  // Habit library
  static const IconData atom = Symbols.science_rounded;
  static const IconData barbell = Symbols.fitness_center_rounded;
  static const IconData basketball = Symbols.sports_basketball_rounded;
  static const IconData bed = Symbols.bed_rounded;
  static const IconData book = Symbols.book_2_rounded;
  static const IconData bookOpen = Symbols.auto_stories_rounded;
  static const IconData brain = Symbols.psychology_rounded;
  static const IconData briefcase = Symbols.work_rounded;
  static const IconData broom = Symbols.cleaning_services_rounded;
  static const IconData carrot = Symbols.nutrition_rounded;
  static const IconData cigarette = Symbols.smoking_rooms_rounded;
  static const IconData code = Symbols.code_rounded;
  static const IconData coffee = Symbols.local_cafe_rounded;
  static const IconData drop = Symbols.water_drop_rounded;
  static const IconData flower = Symbols.local_florist_rounded;
  static const IconData forkKnife = Symbols.restaurant_rounded;
  static const IconData graduationCap = Symbols.school_rounded;
  static const IconData handHeart = Symbols.volunteer_activism_rounded;
  static const IconData meditation = Symbols.self_improvement_rounded;
  static const IconData heartbeat = Symbols.monitor_heart_rounded;
  static const IconData leaf = Symbols.eco_rounded;
  static const IconData mountains = Symbols.landscape_rounded;
  static const IconData music = Symbols.music_note_rounded;
  static const IconData bike = Symbols.directions_bike_rounded;
  static const IconData run = Symbols.directions_run_rounded;
  static const IconData walk = Symbols.directions_walk_rounded;
  static const IconData piggyBank = Symbols.savings_rounded;
  static const IconData pill = Symbols.medication_rounded;
  static const IconData shower = Symbols.shower_rounded;
  static const IconData smiley = Symbols.mood_rounded;
  static const IconData sneaker = Symbols.steps_rounded;
  static const IconData soccer = Symbols.sports_soccer_rounded;
  static const IconData swim = Symbols.pool_rounded;
  static const IconData tree = Symbols.park_rounded;
  static const IconData wallet = Symbols.account_balance_wallet_rounded;
  static const IconData wind = Symbols.air_rounded;
  static const IconData wine = Symbols.wine_bar_rounded;
  static const IconData yinYang = Symbols.all_inclusive_rounded;
}
