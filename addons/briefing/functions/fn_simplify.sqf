#include "..\script_component.hpp"
/*
 * Douglas-Peucker 简化。用栈迭代实现，不用递归，长线也不会堆栈过深。
 *
 * Arguments:
 * 0: 点 <ARRAY> [[x, y, z], ...]
 * 1: 容差（米） <NUMBER>
 *
 * Return Value:
 * 简化后的点 <ARRAY>（首尾点保留）
 */

params ["_pts", "_eps"];

private _n = count _pts;
if (_n < 3) exitWith {+_pts};

private _keep = [];
_keep resize _n;
_keep = _keep apply {false};
_keep set [0, true];
_keep set [_n - 1, true];

private _stack = [[0, _n - 1]];
while {_stack isNotEqualTo []} do {
    (_stack deleteAt (count _stack - 1)) params ["_i0", "_i1"];
    if (_i1 - _i0 < 2) then {continue};

    private _a = _pts select _i0;
    private _b = _pts select _i1;
    private _dMax = -1;
    private _iMax = -1;
    for "_i" from (_i0 + 1) to (_i1 - 1) do {
        private _d = [_pts select _i, _a, _b] call BRF_fnc_segDist;
        if (_d > _dMax) then {
            _dMax = _d;
            _iMax = _i;
        };
    };

    if (_dMax > _eps) then {
        _keep set [_iMax, true];
        _stack pushBack [_i0, _iMax];
        _stack pushBack [_iMax, _i1];
    };
};

private _result = [];
{
    if (_keep select _forEachIndex) then {_result pushBack _x};
} forEach _pts;
_result
