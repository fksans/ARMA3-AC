#include "..\script_component.hpp"
/*
 * 打开标注界面。
 * "zeus"：主持界面。Zeus 界面（display 312）打开时作为它的子 display 弹出，关掉就回到 Zeus。
 *         简报的主持人不在 Zeus 界面里时，也可以从游戏画面打开。
 * "commander"：指挥官标注（非 Zeus、有标注权限的人在观看界面按 D）。只能在简报进行中打开，
 *         只有画图、橡皮（只擦自己的）和撤销，Esc 回到观看界面。
 *
 * Arguments:
 * 0: 身份 <STRING> (default: "zeus")
 *
 * Return Value:
 * 是否允许打开 <BOOL>
 */

params [["_role", "zeus", [""]]];

private _fnc_allowed = {
    if (_role == "commander") then {
        (BRF_session select 0) && {!(call BRF_fnc_isHost)} && {[player] call BRF_fnc_canDraw}
    } else {
        call BRF_fnc_canPresent
    };
};

if !(call _fnc_allowed) exitWith {
    systemChat localize (["STR_BRF_NotCurator", "STR_BRF_NoDrawAccess"] select (_role == "commander"));
    false
};

// 下一帧再创建：避免和 ZEN 右键菜单关闭等同一帧的 UI 操作冲突
[{
    params ["_role", "_fnc_allowed"];
    if (!isNull (uiNamespace getVariable ["BRF_presenter", displayNull])) exitWith {};
    if !(call _fnc_allowed) exitWith {};

    BRF_role = _role;
    [false] call BRF_fnc_closeViewer;

    private _parent = findDisplay 312;
    if (isNull _parent || {_role == "commander"}) then {_parent = findDisplay 46};
    _parent createDisplay "BRF_Presenter";
}, [_role, _fnc_allowed]] call CBA_fnc_execNextFrame;

true
