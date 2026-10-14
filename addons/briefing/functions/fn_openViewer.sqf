#include "..\script_component.hpp"
/*
 * 打开观看界面（全屏暗色地图）。这个界面会接管键盘鼠标，看简报期间人物不会乱动。
 * 主持界面开着时不打开（Zeus 自己用主持界面看）。
 *
 * Arguments:
 * 0: 播放开场动画 <BOOL> (default: false)。只有开始简报时为 true；中途加入、按 Ctrl+B 重新打开时直接显示
 */

params [["_intro", false, [false]]];

if (!hasInterface) exitWith {};
BRF_viewerIntroPending = _intro;

[{!isNull findDisplay 46}, {
    if (
        !isNull (uiNamespace getVariable ["BRF_viewer", displayNull])
        || {!isNull (uiNamespace getVariable ["BRF_presenter", displayNull])}
    ) exitWith {
        BRF_viewerIntroPending = false; // 没打开新界面，开场标记不留到下一次
    };

    // Zeus 界面开着时叠在它上面，否则叠在游戏画面上
    private _parent = findDisplay 312;
    if (isNull _parent) then {_parent = findDisplay 46};
    _parent createDisplay "BRF_Viewer";
}] call CBA_fnc_waitUntilAndExecute;
