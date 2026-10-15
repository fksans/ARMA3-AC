#include "..\script_component.hpp"
/*
 * 发送一个事件（主持人和有标注权限的指挥官都会调用）。
 * 1. 先在本机处理（公共变量的监听不会在发送者本机触发，不手动执行的话自己看不到）
 * 2. 增删元素：写这个元素自己的公共变量 BRF_el_<id>（删除写 []），给中途加入的人用；
 *    同时创建 / 删除对应的原版标记 acb_<id>（见 BRF_fnc_mirror）
 * 3. 写 BRF_evt 并广播（在线的人靠它播动画）。放在第 2 步之后：同一台机器发的公共变量按顺序到达，
 *    收到事件的人一定已经有元素变量
 * 开关会话时另外广播 BRF_session
 *
 * Arguments（_this 就是事件数组，和 BRF_fnc_onEvent 相同）:
 * ["add", 元素] / ["del", id] / ["clear"] / ["session", 开关, 名字, clientOwner]
 *
 * Example:
 * ["del", "2_5"] call BRF_fnc_send
 */

private _evt = _this;
if (!(_evt isEqualType []) || {_evt isEqualTo []} || {!((_evt select 0) isEqualType "")}) exitWith {};

// 权限按本机真实身份判断，不看界面身份（BRF_role）：
// 开关简报、清屏只有 Zeus；画 / 删只有 Zeus 或简报进行中有标注权限的人，而且非 Zeus 只能删自己画的
private _isZeus = call BRF_fnc_canPresent;
private _canDraw = _isZeus || {(BRF_session select 0) && {[player] call BRF_fnc_canDraw}};
private _allowed = switch (_evt select 0) do {
    case "session";
    case "clear": {_isZeus};
    case "add": {_canDraw};
    case "del": {
        _isZeus || {_canDraw && {((BRF_elMap getOrDefault [_evt param [1, ""], []]) param [E_AUTHOR, ""]) == getPlayerUID player}}
    };
    default {false};
};
if (!_allowed) exitWith {
    diag_log text format ["[BRF] refused %1: no permission", _evt select 0];
};

private _fnc_publish = {
    params ["_id", "_value"];
    private _var = "BRF_el_" + _id;
    missionNamespace setVariable [_var, _value];
    publicVariable _var;
};

// 清屏要清掉所有人画的，包括本机还没收到事件的：先从公共变量里取全
private _cleared = [];
if ((_evt select 0) == "clear") then {
    _cleared = ([] call BRF_fnc_collectState) apply {_x select 0};
};

_evt call BRF_fnc_onEvent;          // 本机先处理，BRF_state 在这里更新

switch (_evt select 0) do {
    case "add": {
        private _el = _evt select 1;
        [_el select 0, _el] call _fnc_publish;
        ["add", _el] call BRF_fnc_mirror;
    };
    case "del": {
        [_evt select 1, []] call _fnc_publish;
        ["del", _evt select 1] call BRF_fnc_mirror;
    };
    case "clear": {
        {[_x, []] call _fnc_publish} forEach _cleared;
        ["clearAll"] call BRF_fnc_mirror;
    };
};

BRF_evt = _evt;
publicVariable "BRF_evt";

if ((_evt select 0) == "session") then {
    publicVariable "BRF_session";
};
