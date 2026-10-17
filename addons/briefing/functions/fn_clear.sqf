#include "..\script_component.hpp"
/*
 * 主持端：清屏（Ctrl+Shift+Del 或工具栏按钮）。3 秒内再按一次才真正清空。
 */

private _now = diag_tickTime;
if (_now - (missionNamespace getVariable ["BRF_clearArmed", -10]) > 3) exitWith {
    BRF_clearArmed = _now;
    [localize "STR_BRF_MsgClearConfirm", [1, 0.5, 0.4, 1]] call BRF_fnc_presenterMessage;
};

BRF_clearArmed = -10;
["clear"] call BRF_fnc_send;
BRF_undoStack = [];
// 播放出去的预案元素也清掉了，下次从第 1 步重新播
BRF_planPlayed = [];
BRF_planTokens = [];
[localize "STR_BRF_MsgCleared", [0.55, 1, 0.9, 1]] call BRF_fnc_presenterMessage;
[] call BRF_fnc_presenterUpdate;
