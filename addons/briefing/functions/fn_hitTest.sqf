#include "..\script_component.hpp"
/*
 * 橡皮命中判断：鼠标下最上层的元素。
 * 先找线条、图标、圈和区域的边（屏幕距离小于 8 像素），找不到再找圈和区域的内部。
 *
 * Arguments:
 * 0: 地图控件 <CONTROL>
 * 1: 鼠标 x <NUMBER>
 * 2: 鼠标 y <NUMBER>
 *
 * Return Value:
 * 元素 id <STRING>，没有命中为 ""
 */

params ["_map", "_mx", "_my"];

private _p = (_map ctrlMapScreenToWorld [_mx, _my]) + [0];
private _threshold = HIT_PX * BRF_mpp;

private _fnc_pathDist = {
    params ["_pts"];
    private _d = 1e10;
    for "_i" from 1 to (count _pts - 1) do {
        _d = _d min ([_p, _pts select (_i - 1), _pts select _i] call BRF_fnc_segDist);
    };
    _d
};

private _fnc_inPolygon = {
    // 射线法；_pts 是闭合的（末尾等于第一个点）
    params ["_pts"];
    _p params ["_px", "_py"];
    private _in = false;
    for "_i" from 1 to (count _pts - 1) do {
        (_pts select (_i - 1)) params ["_ax", "_ay"];
        (_pts select _i) params ["_bx", "_by"];
        if (((_ay > _py) != (_by > _py)) && {_px < (_bx - _ax) * (_py - _ay) / (_by - _ay) + _ax}) then {
            _in = !_in;
        };
    };
    _in
};

private _hit = "";
private _live = BRF_els select {(_x select E_T1) < 0};
reverse _live; // 最后画的在最上面

// 第一遍：边
{
    _x params ["_id", "_type", "", "_data", "", "", "_cache"];
    private _match = switch (_type) do {
        case "line": {([_cache select 0] call _fnc_pathDist) < _threshold};
        case "icon": {(_p distance2D (_cache select 0)) < ICON_PX * 0.8 * BRF_mpp};
        case "ring": {abs ((_p distance2D (_cache select 0)) - (_data select 1)) < _threshold};
        case "area": {([_cache select 0] call _fnc_pathDist) < _threshold};
        default {false};
    };
    if (_match) exitWith {_hit = _id};
} forEach _live;

if (_hit != "") exitWith {_hit};

// 第二遍：内部
{
    _x params ["_id", "_type", "", "_data", "", "", "_cache"];
    private _match = switch (_type) do {
        case "ring": {(_p distance2D (_cache select 0)) < (_data select 1)};
        case "area": {[_cache select 0] call _fnc_inPolygon};
        default {false};
    };
    if (_match) exitWith {_hit = _id};
} forEach _live;

_hit
