#include "..\script_component.hpp"
/*
 * 主持界面右下角的临时提示，4 秒后自动清掉。
 *
 * Arguments:
 * 0: 文字 <STRING>
 * 1: 颜色 <ARRAY> (default: 黄色)
 */

params [["_text", "", [""]], ["_color", [1, 0.85, 0.4, 1], [[]]]];

private _display = uiNamespace getVariable ["BRF_presenter", displayNull];
if (isNull _display) exitWith {};

private _ctrl = _display displayCtrl IDC_BRF_P_MESSAGE;
_ctrl ctrlSetText _text;
_ctrl ctrlSetTextColor _color;

BRF_messageToken = (missionNamespace getVariable ["BRF_messageToken", 0]) + 1;
[{
    params ["_ctrl", "_token"];
    if (_token == BRF_messageToken && {!isNull _ctrl}) then {
        _ctrl ctrlSetText "";
    };
}, [_ctrl, BRF_messageToken], 4] call CBA_fnc_waitAndExecute;
