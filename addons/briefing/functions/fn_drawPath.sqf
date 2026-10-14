#include "..\script_component.hpp"
/*
 * 以某个位置为中心，按「像素」偏移画一条折线（固定屏幕大小的小图形：图标、角括号）。
 *
 * Arguments:
 * 0: 地图控件 <CONTROL>
 * 1: 中心 <ARRAY> [x, y, 0]
 * 2: 偏移（像素，y 向上） <ARRAY> [[dx, dy], ...]
 * 3: 闭合 <BOOL>
 * 4: 颜色 <ARRAY>
 * 5: 线宽 <NUMBER>
 * 6: 1 像素 = 多少米 <NUMBER>
 * 7: 发光 <BOOL> (default: false)
 */

params ["_map", "_center", "_offsets", "_closed", "_col", "_w", "_mpp", ["_glow", false]];

private _pts = _offsets apply {_center vectorAdd [(_x select 0) * _mpp, (_x select 1) * _mpp, 0]};
if (_closed) then {_pts pushBack (_pts select 0)};

private _glowCol = +_col;
_glowCol set [3, 0.25 * (_col select 3)];

for "_i" from 1 to (count _pts - 1) do {
    private _a = _pts select (_i - 1);
    private _b = _pts select _i;
    if (_glow) then {
        _map drawLine [_a, _b, _glowCol, _w * 3];
    };
    _map drawLine [_a, _b, _col, _w];
};
