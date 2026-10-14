#include "..\script_component.hpp"
/*
 * 画威胁圈：半径从 0 扩散到 r（0.4 秒）→ 每 2 秒一次脉冲（外圈从 r 扩到 1.15 r 同时淡出）。
 * 填充和描边分两次画：填充用 drawTriangle（扇形），描边用 drawLine 画，才能有线宽和发光。
 *
 * Arguments:
 * 0: 地图控件 <CONTROL>
 * 1: 数据 <ARRAY> [圆心, 半径米]
 * 2: 缓存 <ARRAY> [圆心(3D)]
 * 3: 颜色 <ARRAY>
 * 4: t0 <NUMBER>
 * 5: 当前时间 <NUMBER>
 * 6: 1 像素 = 多少米 <NUMBER>
 */

params ["_map", "_data", "_cache", "_col", "_t0", "_now", "_mpp"];
_data params ["", "_radius"];
_cache params ["_center"];

private _age = _now - _t0;
private _r = _radius * ((((_age / RING_EXPAND_TIME) min 1) max 0) call BRF_fnc_easeOutCubic);
if (_r <= 0) exitWith {};

private _glow = +_col;
_glow set [3, 0.25 * (_col select 3)];

private _fnc_circle = {
    params ["_rad", "_c", "_w", "_g"];
    // 屏幕上越大的圈分段越多，32 到 96 段
    private _segments = (round ((_rad / _mpp) / 6)) max 32 min 96;
    private _step = 360 / _segments;
    private _prev = _center vectorAdd [0, _rad, 0];
    for "_i" from 1 to _segments do {
        private _p = _center vectorAdd [_rad * sin (_i * _step), _rad * cos (_i * _step), 0];
        if (_g) then {_map drawLine [_prev, _p, _glow, _w * 3]};
        _map drawLine [_prev, _p, _c, _w];
        _prev = _p;
    };
};

// 填充（透明度 0.12）：扇形三角形 + drawTriangle（颜色由 color 参数决定，纹理用不透明白色）
private _fill = +_col;
_fill set [3, 0.12 * (_col select 3)];
private _tris = [];
private _prevFill = _center vectorAdd [0, _r, 0];
for "_i" from 1 to 48 do {
    private _p = _center vectorAdd [_r * sin (_i * 7.5), _r * cos (_i * 7.5), 0];
    _tris append [_center, _prevFill, _p];
    _prevFill = _p;
};
_map drawTriangle [_tris, _fill, BRF_texFill];

// 描边
[_r, _col, LINE_WIDTH, true] call _fnc_circle;

// 圆心十字
private _k = 6;
[_map, _center, [[-_k, 0], [_k, 0]], false, _col, 2, _mpp] call BRF_fnc_drawPath;
[_map, _center, [[0, -_k], [0, _k]], false, _col, 2, _mpp] call BRF_fnc_drawPath;

// 脉冲
if (_age > RING_EXPAND_TIME) then {
    private _ph = ((_age - RING_EXPAND_TIME) mod RING_PULSE_PERIOD) / RING_PULSE_PERIOD;
    private _pulse = +_col;
    _pulse set [3, (_col select 3) * (1 - _ph) * 0.8];
    [_radius * (1 + 0.15 * _ph), _pulse, 2, false] call _fnc_circle;
};
