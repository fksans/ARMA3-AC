#include "..\script_component.hpp"
/*
 * 打开主持界面。Zeus 界面（display 312）打开时作为它的子 display 弹出，关掉就回到 Zeus。
 * 简报的主持人不在 Zeus 界面里时，也可以从游戏画面打开。
 *
 * Return Value:
 * 是否允许打开 <BOOL>
 */

if !(call BRF_fnc_canPresent) exitWith {
    systemChat localize "STR_BRF_NotCurator";
    false
};

// 下一帧再创建：避免和 ZEN 右键菜单关闭等同一帧的 UI 操作冲突
[{
    if (!isNull (uiNamespace getVariable ["BRF_presenter", displayNull])) exitWith {};
    if !(call BRF_fnc_canPresent) exitWith {};

    [false] call BRF_fnc_closeViewer;

    private _parent = findDisplay 312;
    if (isNull _parent) then {_parent = findDisplay 46};
    _parent createDisplay "BRF_Presenter";
}] call CBA_fnc_execNextFrame;

true
