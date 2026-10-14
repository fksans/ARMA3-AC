#include "..\script_component.hpp"
/*
 * 把多边形拆成三角形（耳切法，凸多边形和凹多边形都能处理），给 drawTriangle 填充用。
 * drawPolygon 不支持填充，所以区域填充只能靠这里拆出来的三角形。
 * 自相交等拆不下去的情况，剩下的部分退回扇形拆分。
 *
 * Arguments:
 * 0: 顶点 <ARRAY> [[x, y, z], ...]（不闭合，至少 3 个）
 *
 * Return Value:
 * 三角形顶点 <ARRAY> [a1, b1, c1, a2, b2, c2, ...]
 */

params ["_verts"];

private _n = count _verts;
if (_n < 3) exitWith {[]};

private _fnc_cross = {
    // (b - a) x (c - a) 的 z 分量
    params ["_a", "_b", "_c"];
    ((_b select 0) - (_a select 0)) * ((_c select 1) - (_a select 1))
        - ((_b select 1) - (_a select 1)) * ((_c select 0) - (_a select 0))
};

// 统一成逆时针
private _area = 0;
for "_i" from 0 to (_n - 1) do {
    private _a = _verts select _i;
    private _b = _verts select ((_i + 1) mod _n);
    _area = _area + (_a select 0) * (_b select 1) - (_b select 0) * (_a select 1);
};
private _idx = [];
for "_i" from 0 to (_n - 1) do {_idx pushBack _i};
if (_area < 0) then {reverse _idx};

private _tris = [];
while {count _idx > 3} do {
    private _m = count _idx;
    private _found = false;
    for "_k" from 0 to (_m - 1) do {
        private _ia = _idx select ((_k + _m - 1) mod _m);
        private _ib = _idx select _k;
        private _ic = _idx select ((_k + 1) mod _m);
        private _a = _verts select _ia;
        private _b = _verts select _ib;
        private _c = _verts select _ic;

        // 凸顶点才可能是耳朵
        if ([_a, _b, _c] call _fnc_cross <= 0) then {continue};

        // 其他顶点都不在三角形 abc 里
        private _inside = _idx findIf {
            if (_x in [_ia, _ib, _ic]) then {
                false
            } else {
                private _p = _verts select _x;
                ([_a, _b, _p] call _fnc_cross) >= 0
                    && {([_b, _c, _p] call _fnc_cross) >= 0}
                    && {([_c, _a, _p] call _fnc_cross) >= 0}
            };
        };
        if (_inside != -1) then {continue};

        _tris append [_a, _b, _c];
        _idx deleteAt _k;
        _found = true;
        break;
    };
    if (!_found) exitWith {};
};

// 剩下的部分（正常情况下正好 3 个点）扇形拆分
for "_k" from 1 to (count _idx - 2) do {
    _tris append [_verts select (_idx select 0), _verts select (_idx select _k), _verts select (_idx select (_k + 1))];
};

_tris
