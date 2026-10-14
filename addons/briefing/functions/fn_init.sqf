#include "..\script_component.hpp"
/*
 * postInit（所有机器）：注册快捷键、ZEN 右键菜单、公共变量监听；中途加入检查。
 * 服务器 / 无头客户端没有界面，直接退出——服务器上不需要任何简报代码。
 *
 * 公共变量（全部以 BRF_ 开头，方便 BattlEye 加白名单）：
 *   BRF_evt      最近一个事件            ["add", 元素] / ["del", id] / ["clear"] / ["session", 开关, 名字, clientOwner]
 *   BRF_state    当前全部元素             [[id, 类型, 颜色序号, 数据], ...]
 *   BRF_session  [是否进行中, 主持人名字, 主持人 clientOwner]
 *   BRF_view     [中心x, 中心y, 缩放]
 *   BRF_ptr      激光笔 [x, y]，松开时为 []
 */

if (!hasInterface) exitWith {};

// ---- 调色板：颜色序号 0 友军 / 1 敌军 / 2 中立·注意 / 3 目标·强调 ----
BRF_palette = [
    [0.30, 0.75, 1.00, 1],
    [1.00, 0.30, 0.25, 1],
    [1.00, 0.80, 0.20, 1],
    [0.40, 1.00, 0.60, 1]
];
// 转地图标记时对应的 CfgMarkerColors
BRF_markerColors = ["ColorBLUFOR", "ColorOPFOR", "ColorYellow", "ColorGreen"];
// 图标种类
BRF_iconKinds = ["tgt", "lz", "ip", "wp"];

// 程序纹理（不需要贴图）
BRF_texWhite = "#(rgb,8,8,3)color(1,1,1,1)";
BRF_texClear = "#(rgb,8,8,3)color(0,0,0,0)";
// drawTriangle 填充：不透明白色，颜色和透明度由 color 参数决定（wiki 说明）
BRF_texFill = "#(rgb,1,1,1)color(1,1,1,1)";
BRF_texDot = "\A3\ui_f\data\map\markers\military\dot_CA.paa";

// ---- 本机状态 ----
BRF_els = [];                   // 元素记录 [id, 类型, 颜色, 数据, t0, t1, 缓存]，按绘制顺序
BRF_elMap = createHashMap;      // id -> 元素记录（同一个数组），用于去重
BRF_mpp = 1;                    // 当前地图上 1 像素 = 多少米（每帧在 BRF_fnc_render 里更新）
BRF_viewBox = [0, 0, 0, 0];     // 当前可见范围 [minX, minY, maxX, maxY]
BRF_follow = true;              // 观看端：跟随主持人视角
BRF_ptrTarget = [];             // 激光笔目标位置（收到的）
BRF_ptrPos = [];                // 激光笔显示位置（每帧向目标移动 30%）
BRF_viewerFadeStart = -1;       // 观看界面淡出开始时间，-1 = 不在淡出
BRF_viewerIntroPending = false; // 下一次打开观看界面时播放开场动画
BRF_introStart = -1;            // 开场动画开始时间，-1 = 不在播放
BRF_introTitleShown = false;
BRF_hoverId = "";               // 主持端橡皮悬停的元素
BRF_houseCache = [];            // 房屋缓存 [中心, 半径, 三角形, 查询时间]（BRF_fnc_renderOverlay）
BRF_locCache = nil;             // 地名缓存，第一次渲染时查一次

// ---- 主持端状态（跨多次打开主持界面保留） ----
BRF_seq = 0;
BRF_undoStack = [];
BRF_tool = TOOL_LINE;
BRF_color = 0;
BRF_arrow = true;
BRF_iconKind = 0;
BRF_lastView = [];
BRF_lastViewTime = 0;
BRF_ptrWanted = [];
BRF_ptrSent = [];
BRF_ptrLastTime = 0;
BRF_bgmPlaying = false;

// ---- 中途加入：公共变量的值在 init 之前就已经送达 ----
if (isNil "BRF_state" || {!(BRF_state isEqualType [])}) then {BRF_state = []};
if (isNil "BRF_session" || {!(BRF_session isEqualTypeArray [false, "", 0])}) then {BRF_session = [false, "", -1]};
if (isNil "BRF_view" || {!(BRF_view isEqualTypeArray [0, 0, 0])}) then {BRF_view = []};

// 已有元素直接设为「已播完」
["sync"] call BRF_fnc_onEvent;

// ---- 公共变量监听（必须在 postInit 注册；不会在发送者本机触发） ----
"BRF_evt" addPublicVariableEventHandler {
    private _evt = _this select 1;
    if (_evt isEqualType [] && {_evt isNotEqualTo []}) then {
        _evt call BRF_fnc_onEvent;
    };
};

"BRF_view" addPublicVariableEventHandler {
    private _view = _this select 1;
    if !(_view isEqualTypeArray [0, 0, 0]) exitWith {};
    if (!BRF_follow) exitWith {};
    private _map = (uiNamespace getVariable ["BRF_viewer", displayNull]) displayCtrl IDC_BRF_MAP;
    if (isNull _map) exitWith {};
    _view params ["_cx", "_cy", "_scale"];
    // 0.3 秒的补间正好填平 0.2 秒一次的发送间隔
    ctrlMapAnimClear _map;
    _map ctrlMapAnimAdd [0.3, _scale, [_cx, _cy]];
    ctrlMapAnimCommit _map;
};

"BRF_ptr" addPublicVariableEventHandler {
    private _ptr = _this select 1;
    BRF_ptrTarget = if (_ptr isEqualTypeArray [0, 0]) then {[_ptr select 0, _ptr select 1, 0]} else {[]};
};

// ---- 入口 1：CBA 快捷键（默认 Ctrl+B）----
// Zeus：在 Zeus 界面里打开主持界面；其他玩家：简报进行中时重新打开观看界面。
[
    "AC Briefing",
    "BRF_open",
    [localize "STR_BRF_Keybind", localize "STR_BRF_KeybindTooltip"],
    {
        if ((call BRF_fnc_canPresent) && {!isNull findDisplay 312 || {call BRF_fnc_isHost}}) exitWith {
            [] call BRF_fnc_openPresenter;
            true
        };
        if (BRF_session select 0) exitWith {
            [] call BRF_fnc_openViewer;
            true
        };
        false
    },
    "",
    [0x30, [false, true, false]] // DIK_B, [Shift, Ctrl, Alt]
] call CBA_fnc_addKeybind;

// ---- 入口 2：ZEN 右键菜单（可选，只在检测到 ZEN 时注册）----
if (isClass (configFile >> "CfgPatches" >> "zen_context_menu")) then {
    private _action = [
        "BRF_openPresenter",
        localize "STR_BRF_ContextMenu",
        "\a3\ui_f\data\igui\cfg\simpleTasks\types\map_ca.paa",
        {[] call BRF_fnc_openPresenter},
        {call BRF_fnc_canPresent}
    ] call zen_context_menu_fnc_createAction;
    [_action, [], 0] call zen_context_menu_fnc_addAction;
};

// ---- 中途加入：简报正在进行就打开观看界面 ----
if ((BRF_session select 0) && {!(call BRF_fnc_isHost)}) then {
    [] call BRF_fnc_openViewer;
};
