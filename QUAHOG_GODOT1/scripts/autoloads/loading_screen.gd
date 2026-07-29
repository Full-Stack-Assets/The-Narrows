extends CanvasLayer
















const PRELOAD_PATHS: PackedStringArray = [

    "res://scenes/game_world.tscn", 
    "res://scenes/main.tscn", 
    "res://scenes/player.tscn", 
    "res://assets/3d_vfx/impact_explosions/effects/impact/vfx_impact_02.tscn", 
    "res://assets/3d_vfx/muzzle_flash/effects/muzzle_flash/muzzle_flash_03.tscn", 

    "res://assets/3d_vfx/muzzle_flash/src/material/muzzle_flash/flash_03/flash_03_front.tres", 
    "res://assets/3d_vfx/muzzle_flash/src/material/muzzle_flash/flash_03/flash_03_glow.tres", 
    "res://assets/3d_vfx/muzzle_flash/src/material/muzzle_flash/flash_03/flash_03_long.tres", 
    "res://assets/3d_vfx/muzzle_flash/src/material/muzzle_flash/flash_03/flash_03_side.tres", 
    "res://assets/3d_vfx/shared/texture/gradient/circle/circle_01.tres", 
    "res://assets/3d_vfx/shared/texture/gradient/circle/circle_02.tres", 
    "res://assets/3d_vfx/shared/texture/gradient/circle/circle_03.tres", 
    "res://assets/3d_vfx/shared/texture/gradient/line/line_x_01.tres", 
    "res://assets/3d_vfx/shared/texture/gradient/line/line_y_01.tres", 
    "res://assets/3d_vfx/shared/texture/gradient/line/line_y_02.tres", 
    "res://assets/3d_vfx/shared/texture/gradient/ring/ring_01.tres", 
    "res://assets/3d_vfx/shared/texture/gradient/ring/ring_02.tres", 
    "res://assets/3d_vfx/shared/texture/gradient/ring/ring_03.tres", 
    "res://assets/3d_vfx/shared/texture/gradient/ring/ring_04.tres", 
    "res://assets/3d_vfx/shared/texture/gradient/ring/ring_in_01.tres", 
    "res://assets/3d_vfx/shared/texture/gradient/ring/ring_in_02.tres", 
    "res://assets/3d_vfx/shared/texture/gradient/ring/ring_in_03.tres", 
    "res://assets/3d_vfx/shared/texture/gradient/ring/ring_in_04.tres", 
    "res://assets/3d_vfx/shared/texture/gradient/ring/ring_out_01.tres", 
    "res://assets/3d_vfx/shared/texture/gradient/ring/ring_out_02.tres", 
    "res://assets/3d_vfx/shared/texture/gradient/ring/ring_out_03.tres", 
    "res://assets/3d_vfx/shared/texture/gradient/ring/ring_out_04.tres", 
    "res://assets/3d_vfx/shared/texture/gradient/square/square_01.tres", 
    "res://assets/3d_vfx/shared/texture/gradient/square/square_02.tres", 
    "res://assets/3d_vfx/shared/texture/gradient/square/square_03.tres", 
    "res://assets/3d_vfx/shared/texture/gradient/square/square_04.tres", 
    "res://assets/3d_vfx/shared/texture/gradient/up/right_01.tres", 
    "res://assets/3d_vfx/shared/texture/gradient/up/up_01.tres", 
    "res://assets/3d_vfx/shared/texture/gradient/up/up_02.tres", 
    "res://assets/3d_vfx/shared/texture/gradient/up/up_03.tres", 
    "res://assets/3d_vfx/shared/texture/gradient/up/up_04.tres", 
    "res://assets/3d_vfx/shared/texture/noise/cell/cell_euclidean_01.tres", 
    "res://assets/3d_vfx/shared/texture/noise/cell/cell_euclidean_02.tres", 
    "res://assets/3d_vfx/shared/texture/noise/cell/cell_euclidean_03.tres", 
    "res://assets/3d_vfx/shared/texture/noise/cell/cell_inverted_01.tres", 
    "res://assets/3d_vfx/shared/texture/noise/cell/cell_inverted_02.tres", 
    "res://assets/3d_vfx/shared/texture/noise/cell/cell_inverted_03.tres", 
    "res://assets/3d_vfx/shared/texture/noise/cell/cell_manhattan_01.tres", 
    "res://assets/3d_vfx/shared/texture/noise/cell/cell_manhattan_02.tres", 
    "res://assets/3d_vfx/shared/texture/noise/cell/cell_manhattan_03.tres", 
    "res://assets/3d_vfx/shared/texture/noise/cell/cell_warped_01.tres", 
    "res://assets/3d_vfx/shared/texture/noise/cell/cell_warped_02.tres", 
    "res://assets/3d_vfx/shared/texture/noise/cell/cell_warped_03.tres", 
    "res://assets/3d_vfx/shared/texture/noise/pingpong/pingpong_01.tres", 
    "res://assets/3d_vfx/shared/texture/noise/pingpong/pingpong_02.tres", 
    "res://assets/3d_vfx/shared/texture/noise/pingpong/pingpong_03.tres", 
    "res://assets/3d_vfx/shared/texture/noise/pingpong/pingpong_simple_01.tres", 
    "res://assets/3d_vfx/shared/texture/noise/pingpong/pingpong_simple_02.tres", 
    "res://assets/3d_vfx/shared/texture/noise/pingpong/pingpong_simple_03.tres", 
    "res://assets/3d_vfx/shared/texture/noise/warp/warp_blotch_01.tres", 
    "res://assets/3d_vfx/shared/texture/noise/warp/warp_blotch_02.tres", 
    "res://assets/3d_vfx/shared/texture/noise/warp/warp_brush_01.tres", 
    "res://assets/3d_vfx/shared/texture/noise/warp/warp_brush_02.tres", 
    "res://assets/3d_vfx/shared/texture/noise/warp/warp_ridge_01.tres", 
    "res://assets/3d_vfx/shared/texture/noise/warp/warp_ridge_02.tres", 
    "res://assets/3d_vfx/shared/texture/noise/web/web_01.tres", 
    "res://assets/3d_vfx/shared/texture/noise/web/web_02.tres", 
    "res://assets/3d_vfx/shared/texture/noise/web/web_03.tres", 
    "res://assets/3d_vfx/shared/texture/noise/web/web_warped_01.tres", 
    "res://assets/3d_vfx/shared/texture/noise/web/web_warped_02.tres", 
    "res://assets/3d_vfx/shared/texture/noise/web/web_warped_03.tres", 
    "res://assets/fonts/noto_serif.ttf", 
    "res://assets/textures/skyboxes/south_coast_dusk_sky.tres", 
    "res://assets/ui/app_icon.webp", 
    "res://assets/ui/banner.webp", 
    "res://assets/ui/btn_play.png", 
    "res://assets/ui/btn_play.tres", 
    "res://assets/ui/cover.webp", 
    "res://assets/ui/cover_sm.webp", 
    "res://assets/ui/loading_bar_accent.tres", 
    "res://assets/ui/loading_screen.png", 
    "res://assets/ui/panel_dialog.png", 
    "res://assets/ui/panel_dialog.tres", 
    "res://assets/ui/panel_hud.png", 
    "res://assets/ui/panel_hud.tres", 
    "res://assets/ui/theme.tres", 
    "res://assets/ui/title_poster.webp", 
    "res://assets/ui/title_poster_sm.webp", 
    "res://assets/ui/wordmark_title.png", 

    "res://assets/3d_vfx/shared/texture/cracks_01.png", 
    "res://assets/3d_vfx/shared/texture/cracks_emission_01.png", 
    "res://assets/3d_vfx/shared/texture/flare/flare_01.png", 
    "res://assets/3d_vfx/shared/texture/flare/flare_02.png", 
    "res://assets/3d_vfx/shared/texture/flare/flare_03.png", 
    "res://assets/3d_vfx/shared/texture/flare/flare_04.png", 
    "res://assets/3d_vfx/shared/texture/flash/flash_01.png", 
    "res://assets/3d_vfx/shared/texture/flash/flash_02.png", 
    "res://assets/3d_vfx/shared/texture/flash/flash_03.png", 
    "res://assets/3d_vfx/shared/texture/flash/flash_04.png", 
    "res://assets/3d_vfx/shared/texture/flash_front/flash_front_01.png", 
    "res://assets/3d_vfx/shared/texture/flash_front/flash_front_02.png", 
    "res://assets/3d_vfx/shared/texture/flash_front/flash_front_03.png", 
    "res://assets/3d_vfx/shared/texture/flash_front/flash_front_04.png", 
    "res://assets/3d_vfx/shared/texture/flash_front/flash_front_05.png", 
    "res://assets/3d_vfx/shared/texture/flash_front/flash_front_06.png", 
    "res://assets/3d_vfx/shared/texture/flash_long/flash_long_01.png", 
    "res://assets/3d_vfx/shared/texture/flash_long/flash_long_02.png", 
    "res://assets/3d_vfx/shared/texture/flash_long/flash_long_03.png", 
    "res://assets/3d_vfx/shared/texture/flash_long/flash_long_04.png", 
    "res://assets/3d_vfx/shared/texture/flash_side/flash_side_01.png", 
    "res://assets/3d_vfx/shared/texture/flash_side/flash_side_02.png", 
    "res://assets/3d_vfx/shared/texture/flash_side/flash_side_03.png", 
    "res://assets/3d_vfx/shared/texture/flash_side/flash_side_04.png", 
    "res://assets/3d_vfx/shared/texture/flash_side/flash_side_05.png", 
    "res://assets/3d_vfx/shared/texture/flash_side/flash_side_06.png", 
    "res://assets/3d_vfx/shared/texture/icon/pickup_icons/batch_health_icon.png", 
    "res://assets/3d_vfx/shared/texture/icon/pickup_icons/batch_heart_icon.png", 
    "res://assets/3d_vfx/shared/texture/icon/pickup_icons/batch_lightning_icon.png", 
    "res://assets/3d_vfx/shared/texture/icon/pickup_icons/batch_shield_icon.png", 
    "res://assets/3d_vfx/shared/texture/placeholder.png", 
    "res://assets/3d_vfx/shared/texture/spirals/spirals_01.png", 
    "res://assets/3d_vfx/shared/texture/spirals/spirals_02.png", 
    "res://assets/3d_vfx/shared/texture/spirals/spirals_03.png", 
    "res://assets/3d_vfx/shared/texture/spirals/spirals_04.png", 
    "res://assets/3d_vfx/shared/texture/spirals/spirals_05.png", 
    "res://assets/3d_vfx/shared/texture/spirals/spirals_06.png", 
    "res://assets/environment/buildings/brick_mill_tripo_model_basecolor.jpg", 
    "res://assets/environment/buildings/brick_mill_tripo_model_basecolor.png", 
    "res://assets/environment/buildings/brick_mill_tripo_model_normal.jpg", 
    "res://assets/environment/buildings/brick_mill_tripo_model_normal.png", 
    "res://assets/environment/buildings/brick_mill_tripo_model_rm.jpg", 
    "res://assets/environment/buildings/brick_mill_tripo_model_rm.png", 
    "res://assets/environment/buildings/civic_building_tripo_model_basecolor.jpg", 
    "res://assets/environment/buildings/civic_building_tripo_model_basecolor.png", 
    "res://assets/environment/buildings/civic_building_tripo_model_normal.jpg", 
    "res://assets/environment/buildings/civic_building_tripo_model_normal.png", 
    "res://assets/environment/buildings/civic_building_tripo_model_rm.jpg", 
    "res://assets/environment/buildings/civic_building_tripo_model_rm.png", 
    "res://assets/environment/buildings/corner_store_tripo_model_basecolor.jpg", 
    "res://assets/environment/buildings/corner_store_tripo_model_basecolor.png", 
    "res://assets/environment/buildings/corner_store_tripo_model_normal.jpg", 
    "res://assets/environment/buildings/corner_store_tripo_model_normal.png", 
    "res://assets/environment/buildings/corner_store_tripo_model_rm.jpg", 
    "res://assets/environment/buildings/corner_store_tripo_model_rm.png", 
    "res://assets/environment/buildings/diner_tripo_model_basecolor.jpg", 
    "res://assets/environment/buildings/diner_tripo_model_basecolor.png", 
    "res://assets/environment/buildings/diner_tripo_model_normal.jpg", 
    "res://assets/environment/buildings/diner_tripo_model_normal.png", 
    "res://assets/environment/buildings/diner_tripo_model_rm.jpg", 
    "res://assets/environment/buildings/diner_tripo_model_rm.png", 
    "res://assets/environment/buildings/pawn_shop_tripo_model_basecolor.jpg", 
    "res://assets/environment/buildings/pawn_shop_tripo_model_basecolor.png", 
    "res://assets/environment/buildings/pawn_shop_tripo_model_normal.jpg", 
    "res://assets/environment/buildings/pawn_shop_tripo_model_normal.png", 
    "res://assets/environment/buildings/pawn_shop_tripo_model_rm.jpg", 
    "res://assets/environment/buildings/pawn_shop_tripo_model_rm.png", 
    "res://assets/environment/buildings/triple_decker_tripo_model_basecolor.jpg", 
    "res://assets/environment/buildings/triple_decker_tripo_model_basecolor.png", 
    "res://assets/environment/buildings/triple_decker_tripo_model_normal.jpg", 
    "res://assets/environment/buildings/triple_decker_tripo_model_normal.png", 
    "res://assets/environment/buildings/triple_decker_tripo_model_rm.jpg", 
    "res://assets/environment/buildings/triple_decker_tripo_model_rm.png", 
    "res://assets/props/containers/dumpster_tripo_image_30f8b7f6-49bb-47ff-87d8-7b1a0fb060f3_0.jpg", 
    "res://assets/props/containers/dumpster_tripo_image_30f8b7f6-49bb-47ff-87d8-7b1a0fb060f3_0.png", 
    "res://assets/props/containers/dumpster_tripo_image_30f8b7f6-49bb-47ff-87d8-7b1a0fb060f3_1.jpg", 
    "res://assets/props/containers/dumpster_tripo_image_30f8b7f6-49bb-47ff-87d8-7b1a0fb060f3_1.png", 
    "res://assets/props/containers/dumpster_tripo_image_30f8b7f6-49bb-47ff-87d8-7b1a0fb060f3_2.jpg", 
    "res://assets/props/containers/dumpster_tripo_image_30f8b7f6-49bb-47ff-87d8-7b1a0fb060f3_2.png", 
    "res://assets/props/decorations/fire_hydrant_tripo_image_2890f797-8ceb-4b68-b921-02135abdf136_0.jpg", 
    "res://assets/props/decorations/fire_hydrant_tripo_image_2890f797-8ceb-4b68-b921-02135abdf136_0.png", 
    "res://assets/props/decorations/fire_hydrant_tripo_image_2890f797-8ceb-4b68-b921-02135abdf136_1.jpg", 
    "res://assets/props/decorations/fire_hydrant_tripo_image_2890f797-8ceb-4b68-b921-02135abdf136_1.png", 
    "res://assets/props/decorations/fire_hydrant_tripo_image_2890f797-8ceb-4b68-b921-02135abdf136_2.jpg", 
    "res://assets/props/decorations/fire_hydrant_tripo_image_2890f797-8ceb-4b68-b921-02135abdf136_2.png", 
    "res://assets/props/decorations/streetlight_tripo_image_2059c74c-6b97-47cf-902a-03ee72db2c5a_0.jpg", 
    "res://assets/props/decorations/streetlight_tripo_image_2059c74c-6b97-47cf-902a-03ee72db2c5a_0.png", 
    "res://assets/props/decorations/streetlight_tripo_image_2059c74c-6b97-47cf-902a-03ee72db2c5a_1.jpg", 
    "res://assets/props/decorations/streetlight_tripo_image_2059c74c-6b97-47cf-902a-03ee72db2c5a_1.png", 
    "res://assets/props/decorations/streetlight_tripo_image_2059c74c-6b97-47cf-902a-03ee72db2c5a_2.jpg", 
    "res://assets/props/decorations/streetlight_tripo_image_2059c74c-6b97-47cf-902a-03ee72db2c5a_2.png", 
    "res://assets/props/furniture/park_bench_tripo_image_75bdb75b-01e9-40f8-a8a2-ed426e5345c8_0.jpg", 
    "res://assets/props/furniture/park_bench_tripo_image_75bdb75b-01e9-40f8-a8a2-ed426e5345c8_0.png", 
    "res://assets/props/furniture/park_bench_tripo_image_75bdb75b-01e9-40f8-a8a2-ed426e5345c8_1.jpg", 
    "res://assets/props/furniture/park_bench_tripo_image_75bdb75b-01e9-40f8-a8a2-ed426e5345c8_1.png", 
    "res://assets/props/furniture/park_bench_tripo_image_75bdb75b-01e9-40f8-a8a2-ed426e5345c8_2.jpg", 
    "res://assets/props/furniture/park_bench_tripo_image_75bdb75b-01e9-40f8-a8a2-ed426e5345c8_2.png", 
    "res://assets/props/items/armor_vest_tripo_image_28276fb9-2707-4db5-a7af-34122857273e_0.jpg", 
    "res://assets/props/items/armor_vest_tripo_image_28276fb9-2707-4db5-a7af-34122857273e_1.jpg", 
    "res://assets/props/items/armor_vest_tripo_image_28276fb9-2707-4db5-a7af-34122857273e_2.jpg", 
    "res://assets/props/items/medkit_tripo_image_066f9bbb-13b8-42f1-8cec-83a75cd63d57_0.jpg", 
    "res://assets/props/items/medkit_tripo_image_066f9bbb-13b8-42f1-8cec-83a75cd63d57_1.jpg", 
    "res://assets/props/items/medkit_tripo_image_066f9bbb-13b8-42f1-8cec-83a75cd63d57_2.jpg", 
    "res://assets/props/vehicles/sedan_tripo_image_165b9c32-8b38-4b3c-97f3-36ed8103dd72_0.png", 
    "res://assets/props/vehicles/sedan_tripo_image_165b9c32-8b38-4b3c-97f3-36ed8103dd72_1.png", 
    "res://assets/props/vehicles/sedan_tripo_image_165b9c32-8b38-4b3c-97f3-36ed8103dd72_2.png", 
    "res://assets/props/vehicles/suv_tripo_image_e8cb6c86-dd13-486b-8a7d-a86429636ecc_0.png", 
    "res://assets/props/vehicles/suv_tripo_image_e8cb6c86-dd13-486b-8a7d-a86429636ecc_1.png", 
    "res://assets/props/vehicles/suv_tripo_image_e8cb6c86-dd13-486b-8a7d-a86429636ecc_2.png", 
    "res://assets/props/vehicles/taxi_tripo_image_2be5733b-4ba5-44fc-a638-cb75aa5b67de_0.png", 
    "res://assets/props/vehicles/taxi_tripo_image_2be5733b-4ba5-44fc-a638-cb75aa5b67de_1.png", 
    "res://assets/props/vehicles/taxi_tripo_image_2be5733b-4ba5-44fc-a638-cb75aa5b67de_2.png", 
    "res://assets/props/weapons/bat_tripo_image_3fd57aaf-5a1c-4d8b-97ba-cfdbb2f75c08_0.jpg", 
    "res://assets/props/weapons/bat_tripo_image_3fd57aaf-5a1c-4d8b-97ba-cfdbb2f75c08_1.jpg", 
    "res://assets/props/weapons/bat_tripo_image_3fd57aaf-5a1c-4d8b-97ba-cfdbb2f75c08_2.jpg", 
    "res://assets/props/weapons/pistol_tripo_image_35001e88-fcd1-43fd-af9b-8c2f51164255_0.jpg", 
    "res://assets/props/weapons/pistol_tripo_image_35001e88-fcd1-43fd-af9b-8c2f51164255_1.jpg", 
    "res://assets/props/weapons/pistol_tripo_image_35001e88-fcd1-43fd-af9b-8c2f51164255_2.jpg", 
    "res://assets/props/weapons/rifle_tripo_image_9a542ac2-9109-4b6c-9e3f-8215f087e4dd_0.jpg", 
    "res://assets/props/weapons/rifle_tripo_image_9a542ac2-9109-4b6c-9e3f-8215f087e4dd_1.jpg", 
    "res://assets/props/weapons/rifle_tripo_image_9a542ac2-9109-4b6c-9e3f-8215f087e4dd_2.jpg", 
    "res://assets/props/weapons/shotgun_tripo_model_basecolor.jpg", 
    "res://assets/props/weapons/shotgun_tripo_model_normal.jpg", 
    "res://assets/props/weapons/shotgun_tripo_model_rm.jpg", 
    "res://assets/textures/floors/cobblestone.png", 
    "res://assets/textures/floors/concrete_sidewalk.png", 
    "res://assets/textures/floors/wet_asphalt.png", 
    "res://assets/textures/skyboxes/south_coast_dusk_skybox.png", 
    "res://assets/textures/walls/facade_concrete_office.png", 
    "res://assets/textures/walls/facade_windows_dusk.png", 
    "res://assets/textures/walls/storefront_lit_strip.png", 
    "res://assets/textures/walls/weathered_brick.png", 

    "res://assets/audio/ambient/ambient_coastal_city_coastal_city.mp3", 
    "res://assets/audio/music/music_exploration_explore_theme.mp3", 
    "res://assets/audio/music/music_menu_menu_theme.mp3", 
    "res://assets/audio/sfx/environment/environment_police_siren.mp3", 
    "res://assets/audio/sfx/pickup/pickup_armor_equip.mp3", 
    "res://assets/audio/sfx/pickup/pickup_cash_reward.mp3", 
    "res://assets/audio/sfx/pickup/pickup_heal_use.mp3", 
    "res://assets/audio/sfx/player/player_footstep_concrete.mp3", 
    "res://assets/audio/sfx/player/player_player_hurt.mp3", 
    "res://assets/audio/sfx/player/player_player_wasted.mp3", 
    "res://assets/audio/sfx/ui/ui_busted.mp3", 
    "res://assets/audio/sfx/ui/ui_job_accept.mp3", 
    "res://assets/audio/sfx/ui/ui_shop_buy.mp3", 
    "res://assets/audio/sfx/ui/ui_shop_denied.mp3", 
    "res://assets/audio/sfx/ui/ui_ui_click.mp3", 
    "res://assets/audio/sfx/ui/ui_ui_confirm.mp3", 
    "res://assets/audio/sfx/vehicle/vehicle_engine_ambient.mp3", 
    "res://assets/audio/sfx/vehicle/vehicle_car_enter.mp3", 
    "res://assets/audio/sfx/vehicle/vehicle_tire_screech.mp3", 
    "res://assets/audio/sfx/weapon/weapon_bullet_impact.mp3", 
    "res://assets/audio/sfx/weapon/weapon_melee_hit.mp3", 
    "res://assets/audio/sfx/weapon/weapon_melee_swing.mp3", 
    "res://assets/audio/sfx/weapon/weapon_pistol_reload.mp3", 
    "res://assets/audio/sfx/weapon/weapon_pistol_shot.mp3", 
    "res://assets/audio/sfx/weapon/weapon_rifle_shot.mp3", 
    "res://assets/audio/sfx/weapon/weapon_shotgun_blast.mp3", 

    "res://assets/animations/humanoid_profile_bone_map.tres", 
    "res://assets/characters/cop/cop.glb", 
    "res://assets/characters/cop/cop_animations.tres", 
    "res://assets/characters/mission_giver/mission_giver.glb", 
    "res://assets/characters/mission_giver/mission_giver_animations.tres", 
    "res://assets/characters/pedestrian_female/pedestrian_female.glb", 
    "res://assets/characters/pedestrian_female/pedestrian_female_animations.tres", 
    "res://assets/characters/pedestrian_male/pedestrian_male.glb", 
    "res://assets/characters/pedestrian_male/pedestrian_male_animations.tres", 
    "res://assets/characters/protagonist/protagonist.glb", 
    "res://assets/characters/protagonist/protagonist_animations.tres", 
    "res://assets/environment/buildings/brick_mill.glb", 
    "res://assets/environment/buildings/civic_building.glb", 
    "res://assets/environment/buildings/corner_store.glb", 
    "res://assets/environment/buildings/diner.glb", 
    "res://assets/environment/buildings/pawn_shop.glb", 
    "res://assets/environment/buildings/triple_decker.glb", 
    "res://assets/props/containers/dumpster.glb", 
    "res://assets/props/decorations/fire_hydrant.glb", 
    "res://assets/props/decorations/streetlight.glb", 
    "res://assets/props/furniture/park_bench.glb", 
    "res://assets/props/items/armor_vest.glb", 
    "res://assets/props/items/medkit.glb", 
    "res://assets/props/vehicles/sedan.glb", 
    "res://assets/props/vehicles/suv.glb", 
    "res://assets/props/vehicles/taxi.glb", 
    "res://assets/props/weapons/bat.glb", 
    "res://assets/props/weapons/pistol.glb", 
    "res://assets/props/weapons/rifle.glb", 
    "res://assets/props/weapons/shotgun.glb", 
]

const CORE_PRELOAD_PATHS: PackedStringArray = [
    "res://scenes/game_world.tscn",
    "res://scenes/player.tscn",
]

const PHASE_PROGRESS: Dictionary = {
    "STARTING": 0.08,
    "LOADING CORE MAP": 0.35,
    "SPAWNING PLAYER": 0.62,
    "STARTING CITY": 0.82,
    "READY": 1.0,
}




const DEFAULT_ACCENT: = Color(0.96, 0.7, 0.45, 1.0)
const DEFAULT_BG: = Color(0.08, 0.08, 0.1, 0.85)

var _cache: Dictionary = {}
var _preloaded: bool = false
var _busy: bool = false
var _vfx_warmed: bool = false

var _root: Control
var _progress: ProgressBar
var _status: Label


func _ready() -> void :
    layer = 100
    process_mode = Node.PROCESS_MODE_ALWAYS
    visible = false
    _build_ui()
    if StartupMetrics and not StartupMetrics.phase_marked.is_connected(_on_startup_phase_marked):
        StartupMetrics.phase_marked.connect(_on_startup_phase_marked)
















func _resolve_accent() -> Color:
    if ResourceLoader.exists("res://assets/ui/loading_bar_accent.tres"):
        var sb: = load("res://assets/ui/loading_bar_accent.tres") as StyleBoxFlat
        if sb:
            return sb.bg_color
    if ResourceLoader.exists("res://assets/ui/theme.tres"):
        var t: = load("res://assets/ui/theme.tres") as Theme
        if t:
            var fill: = t.get_stylebox("fill", "ProgressBar") as StyleBoxFlat
            if fill:
                return fill.bg_color
    return DEFAULT_ACCENT


func _build_ui() -> void :
    _root = Control.new()
    add_child(_root)
    _root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _root.mouse_filter = Control.MOUSE_FILTER_IGNORE



    var bg: = ColorRect.new()
    bg.color = Color.BLACK
    _root.add_child(bg)
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


    if ResourceLoader.exists("res://assets/ui/loading_screen.png"):
        var img: = TextureRect.new()
        img.texture = load("res://assets/ui/loading_screen.png")
        img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
        img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        _root.add_child(img)
        img.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


    var vignette: = ColorRect.new()
    vignette.color = Color(0, 0, 0, 0.3)
    _root.add_child(vignette)
    vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)



    if ResourceLoader.exists("res://assets/ui/wordmark_title.png"):
        var wm: = TextureRect.new()
        wm.texture = load("res://assets/ui/wordmark_title.png")
        wm.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        wm.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
        _root.add_child(wm)
        wm.anchor_left = 0.5
        wm.anchor_right = 0.5
        wm.anchor_top = 0.0
        wm.anchor_bottom = 0.0
        wm.offset_left = -450
        wm.offset_right = 450
        wm.offset_top = 80
        wm.offset_bottom = 380



    var band: = Control.new()
    _root.add_child(band)
    band.anchor_left = 0.5
    band.anchor_right = 0.5
    band.anchor_top = 1.0
    band.anchor_bottom = 1.0
    band.offset_left = -360
    band.offset_right = 360
    band.offset_top = -160
    band.offset_bottom = -40

    var vbox: = VBoxContainer.new()
    band.add_child(vbox)
    vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    vbox.add_theme_constant_override("separation", 12)

    _status = Label.new()
    _status.text = "Loading..."
    _status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    vbox.add_child(_status)





    var accent: = _resolve_accent()
    _progress = ProgressBar.new()
    _progress.min_value = 0.0
    _progress.max_value = 1.0
    _progress.show_percentage = false
    _progress.custom_minimum_size = Vector2(0, 22)
    var pb_bg: = StyleBoxFlat.new()
    pb_bg.bg_color = DEFAULT_BG
    pb_bg.set_corner_radius_all(6)
    var pb_fill: = StyleBoxFlat.new()
    pb_fill.bg_color = accent
    pb_fill.set_corner_radius_all(6)
    _progress.add_theme_stylebox_override("background", pb_bg)
    _progress.add_theme_stylebox_override("fill", pb_fill)
    vbox.add_child(_progress)


func _show() -> void :
    visible = true
    set_phase("STARTING")


func _hide() -> void :
    visible = false


func set_progress(p: float) -> void :
    if _progress:
        _progress.value = clamp(p, 0.0, 1.0)


func set_phase(phase: String) -> void:
    if _status:
        _status.text = phase
    set_progress(float(PHASE_PROGRESS.get(phase, 0.0)))


func _on_startup_phase_marked(name: String, _elapsed_from_boot_ms: int) -> void:
    match name:
        "play_pressed":
            set_phase("LOADING CORE MAP")
        "core_map_ready":
            set_phase("SPAWNING PLAYER")
        "player_ready":
            set_phase("STARTING CITY")
        "world_interactive":
            set_phase("READY")




func preload_and_change_scene(scene_path: String, min_display: float = 1.5) -> void :
    if _busy: return
    _busy = true
    _show()
    await get_tree().process_frame
    if not _preloaded:
        await _run_preload_sequence()
        _preloaded = true
    await _change_scene_to(scene_path)
    while StartupMetrics and StartupMetrics.elapsed_ms("play_pressed", "world_interactive") < 0:
        await get_tree().process_frame
    set_phase("READY")
    await get_tree().process_frame
    _hide()
    _busy = false




func change_scene(scene_path: String, min_display: float = 0.6) -> void :
    if _busy: return
    _busy = true
    _show()
    var t0: = Time.get_ticks_msec()
    await get_tree().process_frame
    await get_tree().process_frame
    await _change_scene_to(scene_path)
    var elapsed: = float(Time.get_ticks_msec() - t0) / 1000.0
    if elapsed < min_display:
        await get_tree().create_timer(min_display - elapsed).timeout
    _hide()
    _busy = false



















func _run_preload_sequence() -> void :
    var total: = CORE_PRELOAD_PATHS.size()
    if total == 0:
        set_progress(0.92)
        return
    for i in total:
        var path: = CORE_PRELOAD_PATHS[i]
        if _cache.has(path) or not ResourceLoader.exists(path):
            await get_tree().process_frame
            continue
        var res: = load(path)
        if res:
            _cache[path] = res
        else:
            push_warning("LoadingScreen preload failed: " + path)

        await get_tree().process_frame


func _change_scene_to(scene_path: String) -> void :
    var packed: = _cache.get(scene_path) as PackedScene
    if packed:
        get_tree().change_scene_to_packed(packed)
    else:
        get_tree().change_scene_to_file(scene_path)
    set_progress(1.0)
    await get_tree().process_frame
    await get_tree().process_frame



















func _vfx_warmup() -> void :
    if _vfx_warmed:
        return
    _vfx_warmed = true
    if not OS.has_feature("web"):
        return
    var scene: = get_tree().current_scene
    var cam: = get_viewport().get_camera_3d()
    if scene == null or cam == null:
        return
    var vfx_paths: Array[String] = []
    for p in PRELOAD_PATHS:
        if p.ends_with(".tscn") and ("/3d_vfx/" in p) and ("/effects/" in p):
            vfx_paths.append(p)
    if vfx_paths.is_empty():
        return
    _status.text = "Preparing effects..."


    var holder: = Node3D.new()
    scene.add_child(holder)
    var spawn_at: = cam.global_position - cam.global_transform.basis.z * 3.0
    for path in vfx_paths:
        var ps: = _cache.get(path) as PackedScene
        if ps == null and ResourceLoader.exists(path):
            ps = load(path) as PackedScene
        if ps == null:
            continue
        var inst: Node = ps.instantiate()



        if "autoplay" in inst:
            inst.set("autoplay", false)
        if "proximity_fade" in inst:
            inst.set("proximity_fade", false)
        holder.add_child(inst)
        if inst is Node3D:
            inst.global_position = spawn_at
        if inst.has_node("AnimationPlayer") and inst.has_method("play"):
            inst.call("play")
        await get_tree().process_frame
        await get_tree().process_frame
        if is_instance_valid(inst):
            inst.queue_free()
    if is_instance_valid(holder):
        holder.queue_free()
