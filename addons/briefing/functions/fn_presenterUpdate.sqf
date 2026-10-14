#include "..\script_component.hpp"
/*
 * 刷新主持界面：工具栏高亮、颜色、简报按钮、状态栏、主持权遮罩。
 */

private _display = uiNamespace getVariable ["BRF_presenter", displayNull];
if (isNull _display) exitWith {};

BRF_session params ["_active", "_hostName", "_hostOwner"];
private _isHost = _active && {_hostOwner == clientOwner};

// ---- 主持权：同一时间只有一个主持人。别人在主持时显示「接管 / 只看」 ----
BRF_locked = _active && {!_isHost};
{
    (_display displayCtrl _x) ctrlShow BRF_locked;
} forEach [IDC_BRF_P_LOCK_BG, IDC_BRF_P_LOCK_TEXT, IDC_BRF_P_TAKEOVER, IDC_BRF_P_WATCH];
if (BRF_locked) then {
    BRF_drawing = false;
    BRF_iconPending = [];
    (_display displayCtrl IDC_BRF_P_LABEL) ctrlShow false;
    (_display displayCtrl IDC_BRF_P_LOCK_TEXT) ctrlSetStructuredText parseText format [
        localize "STR_BRF_LockText",
        _hostName
    ];
};

// ---- 工具按钮：当前工具高亮 ----
for "_tool" from TOOL_LINE to TOOL_ERASER do {
    private _ctrl = _display displayCtrl (IDC_BRF_P_TOOL + _tool);
    if (_tool == BRF_tool) then {
        _ctrl ctrlSetBackgroundColor [0.15, 0.55, 0.50, 1];
        _ctrl ctrlSetTextColor [1, 1, 1, 1];
    } else {
        _ctrl ctrlSetBackgroundColor [0.05, 0.16, 0.17, 0.9];
        _ctrl ctrlSetTextColor [0.55, 1, 0.9, 1];
    };
};

private _colorNames = [
    localize "STR_BRF_ColorFriendly",
    localize "STR_BRF_ColorEnemy",
    localize "STR_BRF_ColorNeutral",
    localize "STR_BRF_ColorTarget"
];
private _colorName = _colorNames select BRF_color;
private _ctrlColor = _display displayCtrl IDC_BRF_P_COLOR;
_ctrlColor ctrlSetText format ["■ %1", _colorName];
_ctrlColor ctrlSetTextColor (BRF_palette select BRF_color);

private _arrowText = localize (["STR_BRF_Off", "STR_BRF_On"] select BRF_arrow);
(_display displayCtrl IDC_BRF_P_ARROW) ctrlSetText format [localize "STR_BRF_ArrowFormat", _arrowText];

private _ctrlSession = _display displayCtrl IDC_BRF_P_SESSION;
if (_isHost) then {
    _ctrlSession ctrlSetText localize "STR_BRF_SessionEnd";
    _ctrlSession ctrlSetBackgroundColor [0.45, 0.10, 0.08, 0.95];
} else {
    _ctrlSession ctrlSetText localize "STR_BRF_SessionStart";
    _ctrlSession ctrlSetBackgroundColor [0.10, 0.30, 0.15, 0.95];
};

// ---- 状态栏 ----
private _toolNames = [
    "STR_BRF_ToolLine",
    "STR_BRF_ToolIcon",
    "STR_BRF_ToolRing",
    "STR_BRF_ToolArea",
    "STR_BRF_ToolPointer",
    "STR_BRF_ToolEraser"
] apply {localize _x};
private _toolHints = [
    "STR_BRF_HintLine",
    "STR_BRF_HintIcon",
    "STR_BRF_HintRing",
    "STR_BRF_HintArea",
    "STR_BRF_HintPointer",
    "STR_BRF_HintEraser"
] apply {localize _x};
private _kindNames = [
    "STR_BRF_KindTgt",
    "STR_BRF_KindLz",
    "STR_BRF_KindIp",
    "STR_BRF_KindWp"
] apply {localize _x};

private _sessionText = if (_active) then {
    format [localize "STR_BRF_StatusRunning", _hostName]
} else {
    localize "STR_BRF_StatusIdle"
};

(_display displayCtrl IDC_BRF_P_STATUS) ctrlSetText format [
    localize "STR_BRF_StatusFormat",
    _toolNames select (BRF_tool - 1),
    _colorName,
    _kindNames select BRF_iconKind,
    _sessionText,
    {(_x select E_T1) < 0} count BRF_els,
    MAX_ELEMENTS,
    _toolHints select (BRF_tool - 1)
];
