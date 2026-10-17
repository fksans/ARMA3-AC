#include "..\script_component.hpp"
/*
 * 刷新主持界面右侧的标注权限面板：列出所有玩家和他们现在能不能标注。
 * 每行 lbData = 玩家 UID；点一行由 BRF_fnc_presenterAction "accessCycle" 切换。
 */

private _display = uiNamespace getVariable ["BRF_presenter", displayNull];
if (isNull _display) exitWith {};
private _list = _display displayCtrl IDC_BRF_P_ACCESS_LIST;

uiNamespace setVariable ["BRF_suppressAccessSel", true];
lbClear _list;
private _players = (allPlayers - entities "HeadlessClient_F") select {getPlayerUID _x != ""};
_players = [_players, [], {toLower name _x}] call BIS_fnc_sortBy;
{
    private _uid = getPlayerUID _x;
    private _state = switch (true) do {
        case (!isNull getAssignedCuratorLogic _x): {["STR_BRF_AccessZeus", [0.55, 1, 0.9, 1]]};
        case (_uid in BRF_drawDenied): {["STR_BRF_AccessDenied", [1, 0.45, 0.4, 1]]};
        case (_uid in BRF_drawGrants): {["STR_BRF_AccessGranted", [0.5, 1, 0.5, 1]]};
        case ([_x, true] call BRF_fnc_canDraw): {["STR_BRF_AccessAutoYes", [0.8, 0.95, 0.9, 1]]};
        default {["STR_BRF_AccessAutoNo", [0.6, 0.65, 0.65, 1]]};
    };
    private _row = _list lbAdd format ["%1  [%2]", name _x, localize (_state select 0)];
    _list lbSetColor [_row, _state select 1];
    // Zeus 不用改
    _list lbSetData [_row, ["", _uid] select isNull getAssignedCuratorLogic _x];
} forEach _players;
_list lbSetCurSel -1;
uiNamespace setVariable ["BRF_suppressAccessSel", false];
