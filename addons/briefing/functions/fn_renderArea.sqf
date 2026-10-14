#include "..\script_component.hpp"
/*
 * 画区域：按周长进度描边（0.6 秒，和线条延伸同一套逻辑）→ 填充透明度从 0 升到 0.15（0.4 秒）。
 * drawPolygon 不能填充，填充用预先拆好的三角形 + drawTriangle。
 *
 * Arguments:
 * 0: 地图控件 <CONTROL>
 * 1: 缓存 <ARRAY> [闭合的点(3D), 累计长度, 周长, 三角形]
 * 2: 颜色 <ARRAY>
 * 3: t0 <NUMBER>
 * 4: 当前时间 <NUMBER>
 * 5: 1 像素 = 多少米 <NUMBER>
 */

params ["_map", "_cache", "_col", "_t0", "_now", "_mpp"];
_cache params ["_pts", "_cum", "_len", "_tris"];

private _age = _now - _t0;

// 填充（描边完成后）
private _fillK = ((((_age - AREA_STROKE_TIME) / AREA_FILL_TIME) min 1) max 0);
if (_fillK > 0 && {_tris isNotEqualTo []}) then {
    private _fill = +_col;
    _fill set [3, 0.15 * _fillK * (_col select 3)];
    _map drawTriangle [_tris, _fill, BRF_texFill];
};

// 描边
private _f = (((_age / AREA_STROKE_TIME) min 1) max 0) call BRF_fnc_easeOutCubic;
[_map, _pts, _cum, _len * _f, _col, LINE_WIDTH, false, 0, _now, _mpp] call BRF_fnc_drawLine;
