#include "..\script_component.hpp"
/*
 * 主持端：发送一个事件。
 * 1. 先在本机处理（公共变量的监听不会在发送者本机触发，不手动执行的话 Zeus 自己看不到）
 * 2. 写 BRF_evt 并广播
 * 3. 增删、清屏后广播完整状态 BRF_state（兜底 + 中途加入）；开关会话时广播 BRF_session
 *
 * Arguments:
 * 0: 事件 <ARRAY>（格式见 BRF_fnc_onEvent）
 */

params [["_evt", [], [[]]]];
if (_evt isEqualTo []) exitWith {};

_evt call BRF_fnc_onEvent;          // 本机先处理，BRF_state 在这里更新

BRF_evt = _evt;
publicVariable "BRF_evt";

switch (_evt select 0) do {
    case "add";
    case "del";
    case "clear": {publicVariable "BRF_state"};
    case "session": {publicVariable "BRF_session"};
};
