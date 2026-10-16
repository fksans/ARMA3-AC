#include "..\script_component.hpp"
/*
 * 主持界面的操作（工具栏按钮和快捷键共用）。
 *
 * Arguments:
 * 0: 操作 <STRING>
 *    "tool" 1-6 / "color" ±1 / "iconKind" / "arrow" / "focus" / "undo" / "clear"
 *    "session" / "rebuild" / "access"（权限面板开关）/ "accessCycle" UID / "close" / "takeover" / "watch"
 *    "plan"（编排模式开关）/ "follow"（指挥官：跟随 / 自由）
 * 1: 参数 <NUMBER>（tool：工具序号；color：方向）/ <STRING>（accessCycle：玩家 UID）
 */

params [["_action", "", [""]], ["_arg", 0, [0, ""]]];

// 指挥官标注只能用画图相关的操作
if (BRF_role == "commander" && {!(_action in ["tool", "color", "iconKind", "arrow", "undo", "close", "follow"])}) exitWith {};

private _display = uiNamespace getVariable ["BRF_presenter", displayNull];
if (isNull _display) exitWith {};
private _map = _display displayCtrl IDC_BRF_MAP;

switch (_action) do {
    case "tool": {
        if (BRF_role == "commander" && {_arg == TOOL_POINTER}) exitWith {};
        BRF_tool = _arg max TOOL_LINE min TOOL_RULER;
        BRF_drawing = false;
        BRF_pts = [];
        BRF_areaPts = [];
        BRF_rulerA = [];
        BRF_rulerB = [];
        BRF_hoverId = "";
        ["set", []] call BRF_fnc_pointer;
    };
    case "color": {
        private _n = count BRF_palette;
        BRF_color = (BRF_color + _arg + _n) mod _n;
    };
    case "iconKind": {
        BRF_iconKind = (BRF_iconKind + 1) mod (count BRF_iconKinds);
    };
    case "arrow": {
        BRF_arrow = !BRF_arrow;
    };
    case "focus": {
        // 立即把当前视角推给所有人（不受节流限制）
        if (call BRF_fnc_isHost) then {
            [_map, true] call BRF_fnc_syncView;
            [localize "STR_BRF_MsgFocus", [0.55, 1, 0.9, 1]] call BRF_fnc_presenterMessage;
        } else {
            [localize "STR_BRF_MsgNotRunning", [1, 0.85, 0.4, 1]] call BRF_fnc_presenterMessage;
        };
    };
    case "undo": {
        if (BRF_planEdit) then {["undo"] call BRF_fnc_plan} else {[] call BRF_fnc_undo};
    };
    case "clear": {
        if (BRF_planEdit) then {["clear"] call BRF_fnc_plan} else {[] call BRF_fnc_clear};
    };
    case "plan": {
        ["toggleEdit"] call BRF_fnc_plan;
    };
    case "session": {
        if (call BRF_fnc_isHost) then {
            ["session", false, name player, clientOwner] call BRF_fnc_send;
            [] call BRF_fnc_musicStop;
            [localize "STR_BRF_MsgEnded", [0.55, 1, 0.9, 1]] call BRF_fnc_presenterMessage;
        } else {
            ["session", true, name player, clientOwner] call BRF_fnc_send;
            [_map, true] call BRF_fnc_syncView;
            private _bgm = _display displayCtrl IDC_BRF_P_BGM;
            [_bgm lbData (lbCurSel _bgm)] call BRF_fnc_musicPlayAll;
            [localize "STR_BRF_MsgStarted", [0.55, 1, 0.9, 1]] call BRF_fnc_presenterMessage;
        };
    };
    case "takeover": {
        // 接管：先发一次新的 session 事件，之后的视角、激光笔都由本机发出
        ["session", true, name player, clientOwner] call BRF_fnc_send;
        [_map, true] call BRF_fnc_syncView;
        [localize "STR_BRF_MsgTakenOver", [0.55, 1, 0.9, 1]] call BRF_fnc_presenterMessage;
    };
    case "watch": {
        _display closeDisplay 2;
        [] call BRF_fnc_openViewer;
    };
    case "rebuild": {
        ["sync"] call BRF_fnc_onEvent;
        private _count = ["rebuild"] call BRF_fnc_mirror;
        [format [localize "STR_BRF_MsgRebuilt", _count], [0.55, 1, 0.9, 1]] call BRF_fnc_presenterMessage;
    };
    case "access": {
        BRF_accessOpen = !BRF_accessOpen;
        if (BRF_accessOpen) then {[] call BRF_fnc_presenterAccess};
    };
    case "accessCycle": {
        // 自动 → 授权 → 禁止 → 自动
        private _uid = _arg;
        private _state = if (_uid in BRF_drawGrants) then {1} else {[0, 2] select (_uid in BRF_drawDenied)};
        BRF_drawGrants = BRF_drawGrants - [_uid];
        BRF_drawDenied = BRF_drawDenied - [_uid];
        switch (_state) do {
            case 0: {BRF_drawGrants pushBack _uid};
            case 1: {BRF_drawDenied pushBack _uid};
        };
        publicVariable "BRF_drawGrants";
        publicVariable "BRF_drawDenied";
        [] call BRF_fnc_presenterAccess;
    };
    case "follow": {
        BRF_follow = !BRF_follow;
        if (BRF_follow && {BRF_view isNotEqualTo []}) then {
            BRF_view params ["_cx", "_cy", "_scale"];
            ctrlMapAnimClear _map;
            _map ctrlMapAnimAdd [0.3, _scale, [_cx, _cy]];
            ctrlMapAnimCommit _map;
        };
    };
    case "close": {
        _display closeDisplay 2;
    };
};

[] call BRF_fnc_presenterUpdate;
