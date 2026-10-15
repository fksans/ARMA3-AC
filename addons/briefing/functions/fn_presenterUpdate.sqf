#include "..\script_component.hpp"
/*
 * 刷新主持界面：工具栏高亮、颜色、简报按钮、状态栏、主持权遮罩。
 */

private _display = uiNamespace getVariable ["BRF_presenter", displayNull];
if (isNull _display) exitWith {};

BRF_session params ["_active", "_hostName", "_hostOwner"];
private _isHost = _active && {_hostOwner == clientOwner};

// ---- 主持权：同一时间只有一个主持人。别人在主持时显示「接管 / 只看」 ----
private _commander = BRF_role == "commander";
BRF_locked = !_commander && {_active} && {!_isHost};
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

// ---- 图标面板：只在目标点工具时显示；选中当前种类，图标按当前颜色着色 ----
private _iconList = _display displayCtrl IDC_BRF_P_ICON_LIST;
private _showIcons = BRF_tool == TOOL_ICON && {!BRF_locked};
_iconList ctrlShow _showIcons;
(_display displayCtrl IDC_BRF_P_ICON_TITLE) ctrlShow _showIcons;
if (_showIcons) then {
    private _row = BRF_iconRows getOrDefault [BRF_iconKind, -1];
    if (_row >= 0 && {lbCurSel _iconList != _row}) then {
        uiNamespace setVariable ["BRF_suppressIconSel", true];
        _iconList lbSetCurSel _row;
        uiNamespace setVariable ["BRF_suppressIconSel", false];
    };
    private _tint = BRF_palette select BRF_color;
    {
        _iconList lbSetPictureColor [_y, _tint];
        _iconList lbSetPictureColorSelected [_y, _tint];
    } forEach BRF_iconRows;
};

// ---- 标注权限面板（只有主持界面有）----
private _showAccess = BRF_accessOpen && {!_commander} && {!BRF_locked};
(_display displayCtrl IDC_BRF_P_ACCESS_LIST) ctrlShow _showAccess;
(_display displayCtrl IDC_BRF_P_ACCESS_TITLE) ctrlShow _showAccess;
(_display displayCtrl IDC_BRF_P_ACCESS) ctrlSetBackgroundColor ([[0.05, 0.16, 0.17, 0.9], [0.15, 0.55, 0.50, 1]] select _showAccess);

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

// ---- 预案：按钮、状态条 ----
private _ctrlPlan = _display displayCtrl IDC_BRF_P_PLAN;
private _banner = _display displayCtrl IDC_BRF_P_PLAN_BANNER;
if (BRF_planEdit) then {
    _ctrlPlan ctrlSetText localize "STR_BRF_PlanEditing";
    _ctrlPlan ctrlSetBackgroundColor [0.55, 0.35, 0.05, 0.95];
    (BRF_plan select BRF_planEditStep) params ["_records", "_view", "_useView"];
    _banner ctrlSetText format [
        localize "STR_BRF_PlanBannerEdit",
        BRF_planEditStep + 1,
        count BRF_plan,
        count _records,
        localize (["STR_BRF_PlanCamOff", "STR_BRF_PlanCamOn"] select (_useView && {_view isNotEqualTo []}))
    ];
    _banner ctrlSetTextColor [1, 0.8, 0.4, 1];
    _banner ctrlSetBackgroundColor [0.25, 0.15, 0, 0.9];
    _banner ctrlShow true;
} else {
    _ctrlPlan ctrlSetText localize "STR_BRF_Plan";
    _ctrlPlan ctrlSetBackgroundColor [0.05, 0.16, 0.17, 0.9];
    private _steps = {(_x select 0) isNotEqualTo []} count BRF_plan;
    _banner ctrlShow (_steps > 0);
    if (_steps > 0) then {
        _banner ctrlSetText format [localize "STR_BRF_PlanBannerPlay", count BRF_planPlayed min count BRF_plan, count BRF_plan];
        _banner ctrlSetTextColor [0.55, 1, 0.9, 1];
        _banner ctrlSetBackgroundColor [0, 0.03, 0.04, 0.85];
    };
};
if (BRF_locked || _commander) then {_banner ctrlShow false};

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
private _kindName = (BRF_iconTable select (BRF_iconKind min (count BRF_iconTable - 1))) select 1;

if (_commander) then {
    _toolHints set [TOOL_ERASER - 1, localize "STR_BRF_HintEraserOwn"];
};
private _sessionText = switch (true) do {
    case (_commander): {
        format [localize "STR_BRF_StatusCommander", _hostName, localize (["STR_BRF_ViewerFree", "STR_BRF_ViewerFollow"] select BRF_follow)]
    };
    case (_active): {format [localize "STR_BRF_StatusRunning", _hostName]};
    default {localize "STR_BRF_StatusIdle"};
};

(_display displayCtrl IDC_BRF_P_STATUS) ctrlSetText format [
    localize "STR_BRF_StatusFormat",
    _toolNames select (BRF_tool - 1),
    _colorName,
    _kindName,
    _sessionText,
    {(_x select E_T1) < 0} count BRF_els,
    MAX_ELEMENTS,
    [_toolHints select (BRF_tool - 1), localize "STR_BRF_HintPlanEdit"] select BRF_planEdit
];
