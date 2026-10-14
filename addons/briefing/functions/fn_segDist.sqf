#include "..\script_component.hpp"
/*
 * 点到线段的二维距离。
 *
 * Arguments:
 * 0: 点 <ARRAY> [x, y, z]
 * 1: 线段起点 <ARRAY> [x, y, z]
 * 2: 线段终点 <ARRAY> [x, y, z]
 *
 * Return Value:
 * 距离 <NUMBER>
 */

params ["_p", "_a", "_b"];

private _ab = _b vectorDiff _a;
_ab set [2, 0];
private _len2 = _ab vectorDotProduct _ab;
if (_len2 <= 0) exitWith {_p distance2D _a};

private _ap = _p vectorDiff _a;
_ap set [2, 0];
private _t = (((_ap vectorDotProduct _ab) / _len2) max 0) min 1;

_p distance2D (_a vectorAdd (_ab vectorMultiply _t))
