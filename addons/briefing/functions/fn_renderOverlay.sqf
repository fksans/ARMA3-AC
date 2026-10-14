#include "..\script_component.hpp"
/*
 * 地图底层叠加：房屋、地名、比例尺（主持端和观看端共用，在简报元素之前画，元素压在上面）。
 * 原版地图把地名和房屋画成深色，在暗色底图上看不见，所以自己用青色重新画一遍。
 *
 * - 房屋：放大到街区级别（1 像素 < 1.6 米）才画，按包围盒画成半透明的块，缩放越大越清楚。
 *   附近的房屋查一次缓存起来，视角移出缓存范围才重新查（nearestTerrainObjects 比较慢）。
 * - 地名：首都 / 城市 / 村庄 / 小地名按缩放级别逐级出现，等宽字体、全大写。整张地图只查一次。
 * - 比例尺：右下角，长度取整到 100 M、500 M、1 KM 这类数字。
 *
 * Arguments:
 * 0: 地图控件 <CONTROL>
 * 1: 1 像素 = 多少米 <NUMBER>
 * 2: 整体透明度 <NUMBER>（观看界面淡出时变小）
 */

params ["_map", "_mpp", "_alpha"];

if (_alpha <= 0) exitWith {};

BRF_viewBox params ["_minX", "_minY", "_maxX", "_maxY"];
private _now = diag_tickTime;
private _font = "EtelkaMonospacePro";

// ---------------------------------------------------------------------------
// 房屋
// ---------------------------------------------------------------------------
private _houseK = (((HOUSE_MAX_MPP - _mpp) / (HOUSE_MAX_MPP * 0.35)) min 1) max 0;
if (_houseK > 0) then {
    private _center = [(_minX + _maxX) / 2, (_minY + _maxY) / 2, 0];
    private _radius = ((_center distance2D [_minX, _minY, 0]) + 200) min HOUSE_MAX_RADIUS;
    BRF_houseCache params [["_cCenter", [0, 0, 0]], ["_cRadius", 0], ["_cTris", []], ["_cTime", -10]];

    // 视角移出缓存范围（或者缩小后需要更大范围）就重新查，最多每 0.5 秒一次
    private _stale = (_center distance2D _cCenter) + _radius > _cRadius;
    if (_stale && {_now - _cTime > 0.5}) then {
        private _queryRadius = (_radius * 1.4) min HOUSE_MAX_RADIUS;
        private _tris = [];
        {
            (boundingBoxReal _x) params ["_bMin", "_bMax", "_bR"];
            if (_bR > 60 || {_bR < 1}) then {continue}; // 不正常的包围盒（太大 / 太小）跳过
            _bMin params ["_x1", "_y1"];
            _bMax params ["_x2", "_y2"];
            private _c1 = _x modelToWorld [_x1, _y1, 0];
            private _c2 = _x modelToWorld [_x2, _y1, 0];
            private _c3 = _x modelToWorld [_x2, _y2, 0];
            private _c4 = _x modelToWorld [_x1, _y2, 0];
            _tris append [_c1, _c2, _c3, _c1, _c3, _c4];
        } forEach (nearestTerrainObjects [_center, HOUSE_TYPES, _queryRadius, false, true]);
        BRF_houseCache = [_center, _queryRadius, _tris, _now];
        _cTris = _tris;
    };

    if (_cTris isNotEqualTo []) then {
        _map drawTriangle [_cTris, [0.30, 0.70, 0.65, 0.32 * _houseK * _alpha], BRF_texFill];
    };
};

// ---------------------------------------------------------------------------
// 地名
// ---------------------------------------------------------------------------
if (isNil "BRF_locCache") then {
    // [位置, 大写名字, 最大显示的 m/px, 字号, 画圆点]
    private _tiers = createHashMapFromArray [
        ["namecitycapital", [1e9, 0.046, true]],
        ["namecity", [30, 0.040, true]],
        ["namevillage", [12, 0.034, false]],
        ["airport", [12, 0.034, false]],
        ["namelocal", [4, 0.030, false]],
        ["namemarine", [8, 0.030, false]]
    ];
    BRF_locCache = [];
    private _half = worldSize / 2;
    {
        private _name = text _x;
        if (_name == "") then {continue};
        (_tiers getOrDefault [toLower type _x, []]) params [["_maxMpp", 0], ["_size", 0.03], ["_dot", false]];
        if (_maxMpp <= 0) then {continue};
        (locationPosition _x) params ["_lx", "_ly"];
        BRF_locCache pushBack [[_lx, _ly, 0], toUpper _name, _maxMpp, _size, _dot];
    } forEach nearestLocations [[_half, _half], ["NameCityCapital", "NameCity", "NameVillage", "Airport", "NameLocal", "NameMarine"], worldSize];
};

{
    _x params ["_pos", "_name", "_maxMpp", "_size", "_dot"];
    if (_mpp > _maxMpp) then {continue};
    _pos params ["_px", "_py"];
    if (_px < _minX || {_px > _maxX} || {_py < _minY} || {_py > _maxY}) then {continue};

    // 快到显示上限时淡出，不会一下子蹦出来
    private _a = ((((_maxMpp - _mpp) / (_maxMpp * 0.25)) min 1) max 0) * _alpha;
    private _col = [0.55, 0.95, 0.85, 0.85 * _a];
    if (_dot) then {
        _map drawIcon [BRF_texWhite, _col, _pos, 4, 4, 45];
    };
    _map drawIcon [BRF_texClear, _col, _pos vectorAdd [0, 10 * _mpp, 0], 1, 1, 0, _name, 2, _size, _font, "center"];
} forEach BRF_locCache;

// ---------------------------------------------------------------------------
// 比例尺（右下角，状态栏上方）
// ---------------------------------------------------------------------------
private _target = SCALE_BAR_PX * _mpp;
private _value = 10;
{
    if (_x <= _target) then {_value = _x};
} forEach [10, 20, 50, 100, 200, 250, 500, 1000, 2000, 2500, 5000, 10000, 20000, 50000];

ctrlPosition _map params ["_sx", "_sy", "_sw", "_sh"];
private _barPx = _value / _mpp;
private _right = (_sx + _sw) min (safeZoneX + safeZoneW) - 0.02 * safeZoneW;
private _bottom = (_sy + _sh) min (safeZoneY + safeZoneH) - 0.07 * safeZoneH;
private _start = (_map ctrlMapScreenToWorld [_right - _barPx * pixelW, _bottom]) + [0];
private _end = _start vectorAdd [_value, 0, 0];
private _barCol = [0.55, 0.95, 0.85, 0.9 * _alpha];
private _glowCol = [0.40, 0.90, 0.80, 0.2 * _alpha];
_map drawLine [_start, _end, _glowCol, 6];
_map drawLine [_start, _end, _barCol, 2];
{
    _x params ["_p", "_h"];
    _map drawLine [_p, _p vectorAdd [0, _h * _mpp, 0], _barCol, 2];
} forEach [[_start, 7], [_start vectorAdd [_value / 2, 0, 0], 4], [_end, 7]];

private _label = if (_value >= 1000) then {format ["%1 KM", _value / 1000]} else {format ["%1 M", _value]};
_map drawIcon [BRF_texClear, _barCol, _start vectorAdd [_value / 2, 16 * _mpp, 0], 1, 1, 0, _label, 2, 0.032, _font, "center"];
