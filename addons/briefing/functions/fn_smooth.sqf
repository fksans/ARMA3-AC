#include "..\script_component.hpp"
/*
 * Chaikin 平滑：每次把每一段替换成 1/4 和 3/4 处的两个点，首尾点保留。
 *
 * Arguments:
 * 0: 点 <ARRAY> [[x, y, z], ...]
 * 1: 迭代次数 <NUMBER> (default: 2)
 *
 * Return Value:
 * 平滑后的点 <ARRAY>
 */

params ["_pts", ["_iterations", 2]];

if (count _pts < 3) exitWith {+_pts};

for "_k" from 1 to _iterations do {
    private _out = [_pts select 0];
    for "_i" from 0 to (count _pts - 2) do {
        private _a = _pts select _i;
        private _b = _pts select (_i + 1);
        _out pushBack ((_a vectorMultiply 0.75) vectorAdd (_b vectorMultiply 0.25));
        _out pushBack ((_a vectorMultiply 0.25) vectorAdd (_b vectorMultiply 0.75));
    };
    _out pushBack (_pts select (count _pts - 1));
    _pts = _out;
};

_pts
