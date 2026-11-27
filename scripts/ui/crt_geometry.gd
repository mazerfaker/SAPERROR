extends RefCounted
# The original approved CRT contour is mapped onto the corresponding 1920x1080 composition.
const LEGACY_CANVAS := Vector2(1672, 941)
const CANVAS := Vector2(1920, 1080)
const ART_SCALE := CANVAS / LEGACY_CANVAS
const LEGACY_SCREEN := Rect2(475, 119, 713, 481)
const SCREEN := Rect2(LEGACY_SCREEN.position*ART_SCALE,LEGACY_SCREEN.size*ART_SCALE)
const RASTER := Vector2i(1426, 962)
const GAME_GRID_AREA := Vector2(648, 608)
const GAME_GRID_CENTER := Vector2(713, 484)
const GAME_CELL_GAP := 4
const CONTOUR := [Vector2(514,125),Vector2(624,119),Vector2(1000,120),Vector2(1144,130),Vector2(1168,145),Vector2(1181,178),Vector2(1186,233),Vector2(1187,470),Vector2(1181,548),Vector2(1167,578),Vector2(1142,592),Vector2(1044,599),Vector2(630,599),Vector2(522,592),Vector2(494,580),Vector2(483,555),Vector2(478,510),Vector2(475,400),Vector2(476,250),Vector2(483,178),Vector2(495,145)]
static func mask_points() -> PackedVector2Array:
	var points := PackedVector2Array()
	for point in CONTOUR: points.append((point - LEGACY_SCREEN.position) / LEGACY_SCREEN.size)
	return points
static func fit(window: Vector2) -> Rect2:
	var factor: float = minf(window.x / CANVAS.x, window.y / CANVAS.y)
	return Rect2((window - CANVAS * factor) * 0.5, CANVAS * factor)
const FIXED_BULGE: float = 0.04 # exactly 25% of crt.1 maximum 0.16
static func warp(uv: Vector2) -> Vector2:
	var p: Vector2 = uv*2.0-Vector2.ONE
	return (p*(1.0+FIXED_BULGE*p.dot(p))/(1.0+2.0*FIXED_BULGE)+Vector2.ONE)*0.5
static func to_raster(local: Vector2) -> Vector2:
	return warp(local / SCREEN.size)*Vector2(RASTER)
static func grid_metrics(area: Vector2, columns: int, rows: int, gap: float) -> Vector2:
	if columns <= 0 or rows <= 0: return Vector2.ZERO
	var side: float = floorf(maxf(0.0, minf((area.x-gap*(columns-1))/columns,(area.y-gap*(rows-1))/rows)))
	return Vector2(side,side)
