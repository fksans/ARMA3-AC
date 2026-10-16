#include "..\script_component.hpp"
/*
 * 主持界面 onLoad：挂鼠标 / 键盘 / 按钮事件，初始化输入状态。
 * 左键画，右键拖动平移，滚轮缩放，数字键切换工具。
 * 指挥官标注（BRF_role == "commander"）时隐藏只有主持人能用的按钮。
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
    [IDC_BRF_P_ARROW, "arrow"],
    [IDC_BRF_P_UNDO, "undo"],
    [IDC_BRF_P_CLEAR, "clear"],
    [IDC_BRF_P_SESSION, "session"],
    [IDC_BRF_P_REBUILD, "rebuild"],
    [IDC_BRF_P_ACCESS, "access"],
    [IDC_BRF_P_PLAN, "plan"],
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

// ---- 颜色下拉框：每行「■ 名字」，文字就是这个颜色；Q / E 仍然循环切换（选中项由 BRF_fnc_presenterUpdate 同步） ----
private _colorBox = _display displayCtrl IDC_BRF_P_COLOR;
{
    private _index = _colorBox lbAdd format ["■ %1", _x];
    _colorBox lbSetColor [_index, BRF_palette select _forEachIndex];
    _colorBox lbSetSelectColor [_index, BRF_palette select _forEachIndex];
} forEach BRF_colorNames;
_colorBox lbSetCurSel BRF_color;
_colorBox ctrlAddEventHandler ["LBSelChanged", {
    params ["_ctrl", "_index"];
    if (uiNamespace getVariable ["BRF_suppressColorSel", false]) exitWith {};
    if (_index >= 0) then {
        BRF_color = _index;
        [] call BRF_fnc_presenterUpdate;
    };
    ctrlSetFocus ((ctrlParent _ctrl) displayCtrl IDC_BRF_MAP);
}];

// ---- 图标面板：类别标题行（值 -1，不能选）+ 图标行（值 = BRF_iconKinds 里的序号） ----
private _iconList = _display displayCtrl IDC_BRF_P_ICON_LIST;
BRF_iconRows = createHashMap;
{
    private _category = _forEachIndex;
    private _header = _iconList lbAdd format ["— %1 —", localize _x];
    _iconList lbSetValue [_header, -1];
    _iconList lbSetColor [_header, [0.40, 0.90, 0.80, 0.6]];
    {
        _x params ["_kind", "_name", "_abbr", "_texture", "", "_cat"];
        if (_cat != _category) then {continue};
        private _row = _iconList lbAdd format ["%1  %2", _name, _abbr];
        _iconList lbSetValue [_row, _forEachIndex];
        if (_texture != "") then {
            _iconList lbSetPicture [_row, _texture];
        };
        BRF_iconRows set [_forEachIndex, _row];
    } forEach BRF_iconTable;
} forEach BRF_iconCategories;
_iconList ctrlAddEventHandler ["LBSelChanged", {
    params ["_ctrl", "_row"];
    if (uiNamespace getVariable ["BRF_suppressIconSel", false]) exitWith {};
    private _index = _ctrl lbValue _row;
    if (_index >= 0) then {
        BRF_iconKind = _index;
    };
    [] call BRF_fnc_presenterUpdate;
    ctrlSetFocus ((ctrlParent _ctrl) displayCtrl IDC_BRF_MAP);
}];

// ---- 标注权限面板：每行 lbData = UID；点一下切换 自动 → 授权 → 禁止 ----
private _accessList = _display displayCtrl IDC_BRF_P_ACCESS_LIST;
_accessList ctrlAddEventHandler ["LBSelChanged", {
    params ["_ctrl", "_row"];
    if (uiNamespace getVariable ["BRF_suppressAccessSel", false]) exitWith {};
    private _uid = _ctrl lbData _row;
    if (_uid != "") then {["accessCycle", _uid] call BRF_fnc_presenterAction};
    ctrlSetFocus ((ctrlParent _ctrl) displayCtrl IDC_BRF_MAP);
}];

// ---- 指挥官标注：只留画图工具、橡皮、颜色、箭头、撤销、关闭 ----
if (BRF_role == "commander") then {
    {
        (_display displayCtrl _x) ctrlShow false;
    } forEach [
        IDC_BRF_P_TOOL + TOOL_POINTER, IDC_BRF_P_CLEAR, IDC_BRF_P_BGM, IDC_BRF_P_SESSION,
        IDC_BRF_P_REBUILD, IDC_BRF_P_ACCESS, IDC_BRF_P_PLAN, IDC_BRF_P_PLAN_BANNER
    ];
    BRF_accessOpen = false;
    BRF_planEdit = false;
    if (BRF_tool == TOOL_POINTER) then {BRF_tool = TOOL_LINE};
    // 进来是为了画，先停在当前位置；Space 可以重新跟随主持人
    BRF_follow = false;
    [localize "STR_BRF_MsgCommanderOn", [0.55, 1, 0.9, 1]] call BRF_fnc_presenterMessage;
};

// 已有元素补齐（不播动画）
["sync"] call BRF_fnc_onEvent;
[] call BRF_fnc_presenterUpdate;

// 打开期间失去资格（被收回 Zeus / 被取消标注权限）则关闭
[{
    params ["", "_handle"];
    private _display = uiNamespace getVariable ["BRF_presenter", displayNull];
    if (isNull _display) exitWith {
        [_handle] call CBA_fnc_removePerFrameHandler;
    };
    private _allowed = if (BRF_role == "commander") then {
        (BRF_session select 0) && {[player] call BRF_fnc_canDraw}
    } else {
        call BRF_fnc_canPresent
    };
    if (!_allowed) exitWith {
        _display closeDisplay 2;
        [_handle] call CBA_fnc_removePerFrameHandler;
    };
}, 0.5] call CBA_fnc_addPerFrameHandler;

ctrlSetFocus _map;
