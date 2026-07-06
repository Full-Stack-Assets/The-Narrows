#!/usr/bin/env python3
"""
Import bounded road splines from southcoast-roads.json (full OSM road network).

Run inside Unreal Editor 5.8 with Python Editor Script Plugin enabled.

Filters roads to a configurable center/radius in southcoast meter coordinates,
then spawns spline actors using the project ground plane (X/Z horizontal, Y up).

Tune CENTER_X_M, CENTER_Z_M, RADIUS_M, and MAX_ROAD_SPLINES at the top.
"""

from __future__ import annotations

import json
import os

try:
    import unreal
except ImportError as exc:  # pragma: no cover
    raise SystemExit(
        "This script must run inside the Unreal Editor Python environment."
    ) from exc


SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.normpath(os.path.join(SCRIPT_DIR, "..", ".."))

ROADS_JSON = os.path.join(REPO_ROOT, "quahog-project-files", "mapdata", "southcoast-roads.json")
MAP_PATH = "/Game/Maps/MH_VerticalSlice"

METERS_TO_CM = 100.0

# Default: New Bedford waterfront district near first mission target (~ -272m east)
CENTER_X_M = -272.0
CENTER_Z_M = 106.0
RADIUS_M = 900.0
MAX_ROAD_SPLINES = 250
MIN_POINTS = 2


def log(message: str) -> None:
    unreal.log(f"[MountHope Roads] {message}")


def warn(message: str) -> None:
    unreal.log_warning(f"[MountHope Roads] {message}")


def southcoast_to_unreal(x_east_m: float, z_north_m: float, y_up_m: float = 0.0) -> unreal.Vector:
    """southcoast-roads.json uses x=east, z=north; missions use X/Z ground plane."""
    return unreal.Vector(
        x_east_m * METERS_TO_CM,
        y_up_m * METERS_TO_CM,
        z_north_m * METERS_TO_CM,
    )


def road_near_center(road: dict) -> bool:
    radius_sq = RADIUS_M * RADIUS_M
    for point in road.get("points", []):
        if len(point) < 2:
            continue
        dx = point[0] - CENTER_X_M
        dz = point[1] - CENTER_Z_M
        if (dx * dx) + (dz * dz) <= radius_sq:
            return True
    return False


def load_map() -> None:
    if unreal.EditorAssetLibrary.does_asset_exist(MAP_PATH):
        unreal.EditorLoadingAndSavingUtils.load_map(MAP_PATH)
    else:
        warn(f"Map missing: {MAP_PATH} — run editor_bootstrap_vertical_slice.py first.")


def spawn_road_spline(road: dict, index: int) -> None:
    points = road.get("points", [])
    if len(points) < MIN_POINTS:
        return

    start = southcoast_to_unreal(points[0][0], points[0][1])
    actor = unreal.EditorLevelLibrary.spawn_actor_from_class(
        unreal.Actor,
        start,
        unreal.Rotator(0.0, 0.0, 0.0),
    )

    highway = road.get("highway", "road")
    label_name = road.get("name", highway) or highway
    actor.set_actor_label(f"MH_SC_Road_{index:04d}_{label_name[:20]}")

    spline = actor.add_component_by_class(
        unreal.SplineComponent,
        manual_attachment=False,
        relative_transform=unreal.Transform(),
    )

    for point in points:
        if len(point) < 2:
            continue
        world_point = southcoast_to_unreal(point[0], point[1])
        local_point = actor.get_transform().inverse_transform_position(world_point)
        spline.add_spline_point(local_point, unreal.SplineCoordinateSpace.LOCAL, False)

    spline.set_closed_loop(False, False)
    spline.set_editor_property("mobility", unreal.ComponentMobility.STATIC)


def main() -> None:
    if not os.path.isfile(ROADS_JSON):
        warn(f"Road JSON not found: {ROADS_JSON}")
        return

    log(
        f"Loading roads near ({CENTER_X_M}, {CENTER_Z_M}) within {RADIUS_M}m "
        f"(max {MAX_ROAD_SPLINES} splines)..."
    )
    load_map()

    with open(ROADS_JSON, encoding="utf-8") as handle:
        data = json.load(handle)

    roads = [road for road in data.get("roads", []) if road_near_center(road)]
    roads.sort(key=lambda road: road.get("highway", ""))
    roads = roads[:MAX_ROAD_SPLINES]

    if not roads:
        warn("No roads matched the bounding radius — adjust CENTER_* or RADIUS_M.")
        return

    for index, road in enumerate(roads):
        spawn_road_spline(road, index)

    unreal.EditorLoadingAndSavingUtils.save_dirty_packages(True, True)
    log(f"Spawned {len(roads)} southcoast road splines.")
    warn("Press P in editor to verify nav; run editor_setup_navmesh.py to add bounds.")


if __name__ == "__main__":
    main()
