#include "..\script_component.hpp"
/*
 * 测试用（M1 渲染原型）：在本机打开观看界面，放一组写死的元素（线、虚线、图标、威胁圈、区域各一个），
 * 依次播放出场动画。只在本机，不发网络；会改动本机的 BRF_state，所以只能在单机 / 编辑器里用。
 *
 * Arguments:
 * 0: 中心位置 <ARRAY> (default: 玩家位置)
 *
 * Example:
 * [] call BRF_fnc_demo
 */

if (isMultiplayer) exitWith {
    systemChat localize "STR_BRF_DemoSPOnly";
};

params [["_center", getPosATL player, [[]]]];
_center params ["_x0", "_y0"];

// 先清掉本机现有的元素（不影响其他人）
["clear"] call BRF_fnc_onEvent;
[] call BRF_fnc_purge;
BRF_els = [];
BRF_elMap = createHashMap;

[] call BRF_fnc_openViewer;

private _fnc_pt = {
    params ["_dx", "_dy"];
    [round (_x0 + _dx), round (_y0 + _dy)]
};

private _curve = [];
for "_i" from 0 to 40 do {
    _curve pushBack ([-1500 + _i * 70, 400 * sin (_i * 9)] call _fnc_pt);
};

private _elements = [
    ["demo_1", "line", 0, [_curve, true, false, LINE_WIDTH]],
    ["demo_2", "line", 2, [[[-1500, -900] call _fnc_pt, [1200, -900] call _fnc_pt], true, true, LINE_WIDTH]],
    ["demo_3", "icon", 3, [[1500, 200] call _fnc_pt, "tgt", "TGT ALPHA"]],
    ["demo_4", "ring", 1, [[1700, 900] call _fnc_pt, 600]],
    ["demo_5", "area", 2, [[[-600, 900] call _fnc_pt, [200, 1300] call _fnc_pt, [500, 700] call _fnc_pt, [0, 1000] call _fnc_pt, [-400, 500] call _fnc_pt]]]
];

// 等观看界面打开后，对准中心，然后每隔 0.8 秒放一个
[{!isNull (uiNamespace getVariable ["BRF_viewer", displayNull])}, {
    params ["_center", "_elements"];
    private _map = (uiNamespace getVariable "BRF_viewer") displayCtrl IDC_BRF_MAP;
    _map ctrlMapAnimAdd [0, 0.08, _center];
    ctrlMapAnimCommit _map;
    {
        [{["add", _this] call BRF_fnc_onEvent}, _x, 0.5 + _forEachIndex * 0.8] call CBA_fnc_waitAndExecute;
    } forEach _elements;
}, [_center, _elements], 5] call CBA_fnc_waitUntilAndExecute;
