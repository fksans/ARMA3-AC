#include "..\script_component.hpp"
/*
 * 主持端：撤销自己最后一个元素（Ctrl+Z）。
 * 维护一个自己发出的 id 栈；已经被橡皮 / 清屏删掉的跳过。不支持重做。
 *
 * Return Value:
 * 是否撤销了 <BOOL>
 */

private _done = false;
while {BRF_undoStack isNotEqualTo []} do {
    private _id = BRF_undoStack deleteAt (count BRF_undoStack - 1);
    private _record = BRF_elMap getOrDefault [_id, []];
    if (_record isNotEqualTo [] && {(_record select E_T1) < 0}) exitWith {
        ["del", _id] call BRF_fnc_send;
        _done = true;
    };
};

if (!_done) then {
    [localize "STR_BRF_MsgNothingToUndo", [1, 0.85, 0.4, 1]] call BRF_fnc_presenterMessage;
};
[] call BRF_fnc_presenterUpdate;

_done
