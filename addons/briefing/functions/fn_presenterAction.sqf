#include "..\script_component.hpp"
/*
 * 主持界面的操作（工具栏按钮和快捷键共用）。
 *
 * Arguments:
 * 0: 操作 <STRING>
 *    "tool" 1-6 / "color" ±1 / "iconKind" / "arrow" / "focus" / "undo" / "clear"
 *    "session" / "toMarkers" / "clearMarkers" / "close" / "takeover" / "watch"
 * 1: 参数 <NUMBER>（tool：工具序号；color：方向）
 */

params [["_action", "", [""]], ["_arg", 0, [0]]];

private _display = uiNamespace getVariable ["BRF_presenter", displayNull];
if (isNull _display) exitWith {};
private _map = _display displayCtrl IDC_BRF_MAP;

switch (_action) do {
    case "tool": {
        BRF_tool = _arg max TOOL_LINE min TOOL_ERASER;
        BRF_drawing = false;
        BRF_pts = [];
        BRF_areaPts = [];
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
        [] call BRF_fnc_undo;
    };
    case "clear": {
        [] call BRF_fnc_clear;
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
    case "toMarkers": {
        private _count = ["create"] call BRF_fnc_toMarkers;
        [format [localize "STR_BRF_MsgMarkers", _count], [0.55, 1, 0.9, 1]] call BRF_fnc_presenterMessage;
    };
    case "clearMarkers": {
        ["clear"] call BRF_fnc_toMarkers;
        [localize "STR_BRF_MsgMarkersCleared", [0.55, 1, 0.9, 1]] call BRF_fnc_presenterMessage;
    };
    case "close": {
        _display closeDisplay 2;
    };
};

[] call BRF_fnc_presenterUpdate;
