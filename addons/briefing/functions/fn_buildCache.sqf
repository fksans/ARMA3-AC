#include "..\script_component.hpp"
/*
 * 收到元素时预先算好渲染要用的东西，渲染时不重复算。顺便校验数据格式。
 * 点在这里转成三维 [x, y, 0]，方便做向量运算。
 *
 * Arguments:
 * 0: 类型 <STRING>
 * 1: 数据 <ARRAY>（格式见 DESIGN.md「数据模型」）
 *
 * Return Value:
 * 缓存 <ARRAY>，数据不合法时为 []
 *   line: [点(3D), 累计长度, 总长, 动画时长(首次渲染时算，-1 = 未算)]
 *   icon: [位置(3D), 标签的字符码数组, 已播放的闪烁次数]
 *   ring: [圆心(3D)]
 *   area: [闭合的点(3D，末尾补上第一个点), 累计长度, 周长, 三角形(3D，每 3 个一组)]
 */

params [["_type", "", [""]], ["_data", [], [[]]]];

private _fnc_toPoints = {
    // [[x, y], ...] -> [[x, y, 0], ...]；格式不对返回 []
    if !(_this isEqualType []) exitWith {[]};
    private _pts = [];
    {
        if !(_x isEqualTypeArray [0, 0]) exitWith {_pts = []};
        _pts pushBack [_x select 0, _x select 1, 0];
    } forEach _this;
    _pts
};

private _fnc_cumulative = {
    private _cum = [0];
    private _len = 0;
    for "_i" from 1 to (count _this - 1) do {
        _len = _len + ((_this select (_i - 1)) distance2D (_this select _i));
        _cum pushBack _len;
    };
    [_cum, _len]
};

private _cache = [];
switch (_type) do {
    case "line": {
        _data params [["_raw", [], [[]]]];
        private _pts = _raw call _fnc_toPoints;
        if (count _pts < 2 || {count _pts > MAX_LINE_POINTS * 2}) exitWith {};
        (_pts call _fnc_cumulative) params ["_cum", "_len"];
        if (_len > 0) then {
            _cache = [_pts, _cum, _len, -1];
        };
    };
    case "icon": {
        _data params [["_pos", [], [[]]], ["_kind", "", [""]], ["_label", "", [""]]];
        if !(_pos isEqualTypeArray [0, 0]) exitWith {};
        if (_label == "") then {_label = toUpper _kind};
        _cache = [[_pos select 0, _pos select 1, 0], toArray _label, -1];
    };
    case "ring": {
        _data params [["_center", [], [[]]], ["_radius", 0, [0]]];
        if (!(_center isEqualTypeArray [0, 0]) || {_radius <= 0}) exitWith {};
        _cache = [[_center select 0, _center select 1, 0]];
    };
    case "area": {
        _data params [["_raw", [], [[]]]];
        private _verts = _raw call _fnc_toPoints;
        if (count _verts < 3 || {count _verts > MAX_LINE_POINTS}) exitWith {};
        private _closed = _verts + [_verts select 0];
        (_closed call _fnc_cumulative) params ["_cum", "_len"];
        if (_len > 0) then {
            _cache = [_closed, _cum, _len, [_verts] call BRF_fnc_triangulate];
        };
    };
};

_cache
