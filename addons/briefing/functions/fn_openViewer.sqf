#include "..\script_component.hpp"
/*
 * 打开观看界面（全屏暗色地图）。这个界面会接管键盘鼠标，看简报期间人物不会乱动。
 * 主持界面开着时不打开（Zeus 自己用主持界面看）。
 */

if (!hasInterface) exitWith {};

[{!isNull findDisplay 46}, {
    if (!isNull (uiNamespace getVariable ["BRF_viewer", displayNull])) exitWith {};
    if (!isNull (uiNamespace getVariable ["BRF_presenter", displayNull])) exitWith {};

    // Zeus 界面开着时叠在它上面，否则叠在游戏画面上
    private _parent = findDisplay 312;
    if (isNull _parent) then {_parent = findDisplay 46};
    _parent createDisplay "BRF_Viewer";
}] call CBA_fnc_waitUntilAndExecute;
