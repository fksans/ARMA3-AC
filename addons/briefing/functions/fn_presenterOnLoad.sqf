#include "..\script_component.hpp"
/*
 * 主持界面 onLoad：挂鼠标 / 键盘 / 按钮事件，初始化输入状态。
 * 左键画，右键拖动平移，滚轮缩放，数字键切换工具。
 *
 * Arguments:
 * 0: Display <DISPLAY>
 */

params ["_display"];

uiNamespace setVariable ["BRF_presenter", _display];

// ---- 输入状态 ----
BRF_drawing = false;
BRF_pts = [];
BRF_ringCenter = [];
BRF_ringRadius = 0;
BRF_areaPts = [];
BRF_iconPending = [];
BRF_cursor = [];
BRF_hoverId = "";
BRF_locked = false;
BRF_lastKey = [];
BRF_lastKeyResult = false;
BRF_modShift = false;
BRF_modAlt = false;
BRF_lastView = [];

private _map = _display displayCtrl IDC_BRF_MAP;
// 动态创建的地图控件第一次动画时目标位置可能偏移，先执行一次
_map ctrlMapSetPosition [];

// 从当前简报视角开始（接管、重新打开时画面不跳）
if (BRF_view isNotEqualTo []) then {
    BRF_view params ["_cx", "_cy", "_scale"];
    _map ctrlMapAnimAdd [0, _scale, [_cx, _cy]];
    ctrlMapAnimCommit _map;
};

// ---- 地图：鼠标 + 每帧绘制 ----
_map ctrlAddEventHandler ["MouseButtonDown", {["down", _this] call BRF_fnc_input}];
_map ctrlAddEventHandler ["MouseMoving", {["move", _this] call BRF_fnc_input}];
_map ctrlAddEventHandler ["MouseButtonUp", {["up", _this] call BRF_fnc_input}];
_map ctrlAddEventHandler ["MouseButtonDblClick", {["dbl", _this] call BRF_fnc_input}];
_map ctrlAddEventHandler ["Draw", {
    params ["_map"];
    [_map, true] call BRF_fnc_render;
    [_map] call BRF_fnc_syncView;
    ["tick"] call BRF_fnc_pointer;
}];

// 鼠标在地图外（工具栏上）松开时，地图控件可能收不到 MouseButtonUp：在整个界面上补一个。
// 推迟到下一帧，地图控件自己的松开事件（带修饰键）先处理；已经处理过的话这里什么都不做。
_display displayAddEventHandler ["MouseButtonUp", {
    params ["_display", "_btn"];
    getMousePosition params ["_mx", "_my"];
    [{
        ["up", _this] call BRF_fnc_input;
    }, [_display displayCtrl IDC_BRF_MAP, _btn, _mx, _my, false, false, false]] call CBA_fnc_execNextFrame;
}];

// ---- 键盘：界面 + 标签输入框（同一按键只处理一次，见 BRF_fnc_input） ----
_display displayAddEventHandler ["KeyDown", {["key", _this] call BRF_fnc_input}];
_display displayAddEventHandler ["KeyUp", {["keyUp", _this] call BRF_fnc_input; false}];
private _label = _display displayCtrl IDC_BRF_P_LABEL;
_label ctrlShow false;
_label ctrlAddEventHandler ["KeyDown", {["key", _this] call BRF_fnc_input}];

// ---- 工具栏按钮 ----
{
    _x params ["_idc", "_action", ["_arg", 0]];
    private _ctrl = _display displayCtrl _idc;
    _ctrl setVariable ["BRF_action", [_action, _arg]];
    _ctrl ctrlAddEventHandler ["ButtonClick", {
        params ["_ctrl"];
        (_ctrl getVariable "BRF_action") call BRF_fnc_presenterAction;
        // 焦点还给地图：否则之后按回车 / 空格会再次触发刚点过的按钮（例如开始 / 结束简报）
        private _display = uiNamespace getVariable ["BRF_presenter", displayNull];
        if (!isNull _display) then {
            ctrlSetFocus (_display displayCtrl IDC_BRF_MAP);
        };
    }];
} forEach [
    [IDC_BRF_P_TOOL + TOOL_LINE, "tool", TOOL_LINE],
    [IDC_BRF_P_TOOL + TOOL_ICON, "tool", TOOL_ICON],
    [IDC_BRF_P_TOOL + TOOL_RING, "tool", TOOL_RING],
    [IDC_BRF_P_TOOL + TOOL_AREA, "tool", TOOL_AREA],
    [IDC_BRF_P_TOOL + TOOL_POINTER, "tool", TOOL_POINTER],
    [IDC_BRF_P_TOOL + TOOL_ERASER, "tool", TOOL_ERASER],
    [IDC_BRF_P_COLOR, "color", 1],
    [IDC_BRF_P_ARROW, "arrow"],
    [IDC_BRF_P_UNDO, "undo"],
    [IDC_BRF_P_CLEAR, "clear"],
    [IDC_BRF_P_SESSION, "session"],
    [IDC_BRF_P_MARKERS, "toMarkers"],
    [IDC_BRF_P_CLEAR_MARKERS, "clearMarkers"],
    [IDC_BRF_P_CLOSE, "close"],
    [IDC_BRF_P_TAKEOVER, "takeover"],
    [IDC_BRF_P_WATCH, "watch"]
];

// ---- BGM 下拉框：列出音乐播放器的收藏曲目（没加载播放器时禁用） ----
private _bgm = _display displayCtrl IDC_BRF_P_BGM;
_bgm lbAdd localize "STR_BRF_BgmNone";
_bgm lbSetData [0, ""];
if (!isNil "zmp_fnc_getFavorites" && {!isNil "zmp_fnc_getLibrary"}) then {
    private _library = (call zmp_fnc_getLibrary) select 1;
    private _last = profileNamespace getVariable ["BRF_bgm", ""];
    {
        private _class = _x select 0;
        private _entry = _library getOrDefault [toLower _class, []];
        if (_entry isEqualTo []) then {continue}; // 当前服务器没加载这首
        private _index = _bgm lbAdd (_entry select 2);
        _bgm lbSetData [_index, _class];
        _bgm lbSetTooltip [_index, _class];
        if (_class == _last) then {_bgm lbSetCurSel _index};
    } forEach (call zmp_fnc_getFavorites);
} else {
    _bgm ctrlEnable false;
    _bgm ctrlSetTooltip localize "STR_BRF_BgmUnavailable";
};
if (lbCurSel _bgm < 0) then {_bgm lbSetCurSel 0};
_bgm ctrlAddEventHandler ["LBSelChanged", {
    params ["_ctrl", "_index"];
    profileNamespace setVariable ["BRF_bgm", _ctrl lbData _index];
    ctrlSetFocus ((ctrlParent _ctrl) displayCtrl IDC_BRF_MAP);
}];

// 已有元素补齐（不播动画）
["sync"] call BRF_fnc_onEvent;
[] call BRF_fnc_presenterUpdate;

// 打开期间失去 curator 身份（被收回 Zeus）则关闭
[{
    params ["", "_handle"];
    private _display = uiNamespace getVariable ["BRF_presenter", displayNull];
    if (isNull _display) exitWith {
        [_handle] call CBA_fnc_removePerFrameHandler;
    };
    if !(call BRF_fnc_canPresent) exitWith {
        _display closeDisplay 2;
        [_handle] call CBA_fnc_removePerFrameHandler;
    };
}, 0.5] call CBA_fnc_addPerFrameHandler;

ctrlSetFocus _map;
