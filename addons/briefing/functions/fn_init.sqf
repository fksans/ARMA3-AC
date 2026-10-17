#include "..\script_component.hpp"
/*
 * postInit（所有机器）：注册快捷键、ZEN 右键菜单、公共变量监听；中途加入检查。
 * 服务器 / 无头客户端没有界面，直接退出——服务器上不需要任何简报代码。
 *
 * 公共变量（全部以 BRF_ 开头，方便 BattlEye 加白名单）：
 *   BRF_evt      最近一个事件            ["add", 元素] / ["del", id] / ["destroy", id, 开关] / ["clear"] / ["session", 开关, 名字, clientOwner]
 *   BRF_el_<id>  一个元素                 [id, 类型, 颜色序号, 数据, 作者 UID, 已摧毁]，删除后为 []（中途加入靠它）
 *   BRF_drawGrants / BRF_drawDenied  Zeus 授权 / 禁止标注的玩家 UID 列表（见 BRF_fnc_canDraw）
 *   BRF_session  [是否进行中, 主持人名字, 主持人 clientOwner]
 *   BRF_view     [中心x, 中心y, 缩放, 补间秒数(可选)]
 *   BRF_ptr      激光笔 [x, y]，松开时为 []
 * 原版地图标记：每个元素对应全局标记 acb_<id>（见 BRF_fnc_mirror）
 */

if (!hasInterface) exitWith {};

// ---- 调色板：颜色序号 0 友军 / 1 敌军 / 2 中立·注意 / 3 目标·强调 / 4 起为通用颜色 ----
// 每项：[名字 stringtable 键, 暗色地图用的亮色, 原版地图（白底）用的深色, 原版标记颜色 CfgMarkerColors]
// 原版地图上用深色版本 + 深色描边，见 BRF_fnc_mapDraw；简报界面的暗色地图用亮色
// 序号就是元素里的颜色序号，只能往后加，不能改顺序（旧元素、中途加入都靠它）
private _colors = [
    ["STR_BRF_ColorFriendly", [0.30, 0.75, 1.00, 1], [0.00, 0.33, 0.95, 1], "ColorBLUFOR"],
    ["STR_BRF_ColorEnemy",    [1.00, 0.30, 0.25, 1], [0.90, 0.00, 0.00, 1], "ColorOPFOR"],
    ["STR_BRF_ColorNeutral",  [1.00, 0.80, 0.20, 1], [0.95, 0.52, 0.00, 1], "ColorYellow"],
    ["STR_BRF_ColorTarget",   [0.40, 1.00, 0.60, 1], [0.00, 0.58, 0.15, 1], "ColorGreen"],
    ["STR_BRF_ColorWhite",    [0.95, 0.95, 0.95, 1], [1.00, 1.00, 1.00, 1], "ColorWhite"],
    ["STR_BRF_ColorOrange",   [1.00, 0.55, 0.15, 1], [0.85, 0.35, 0.00, 1], "ColorOrange"],
    ["STR_BRF_ColorPink",     [1.00, 0.50, 0.80, 1], [0.85, 0.10, 0.55, 1], "ColorPink"],
    ["STR_BRF_ColorBrown",    [0.80, 0.55, 0.35, 1], [0.45, 0.25, 0.10, 1], "ColorBrown"],
    ["STR_BRF_ColorKhaki",    [0.85, 0.80, 0.55, 1], [0.50, 0.45, 0.20, 1], "ColorKhaki"],
    ["STR_BRF_ColorGrey",     [0.60, 0.65, 0.65, 1], [0.35, 0.35, 0.35, 1], "ColorGrey"],
    ["STR_BRF_ColorGuer",     [0.25, 0.80, 0.25, 1], [0.00, 0.45, 0.00, 1], "ColorGUER"],
    ["STR_BRF_ColorCiv",      [0.75, 0.45, 1.00, 1], [0.45, 0.10, 0.65, 1], "ColorCIV"]
];
BRF_colorNames = _colors apply {localize (_x select 0)};
BRF_palette = _colors apply {_x select 1};
BRF_paletteLight = _colors apply {_x select 2};
BRF_markerColors = _colors apply {
    private _name = _x select 3;
    if (!isClass (configFile >> "CfgMarkerColors" >> _name)) then {
        diag_log text format ["[BRF] marker color '%1' is not in CfgMarkerColors, using ColorBlack", _name];
        _name = "ColorBlack";
    };
    _name
};
BRF_lightMap = false;           // 正在原版地图上画（BRF_fnc_mapDraw 期间为 true）
// ---- 程序图形：从配置 BRF_Shapes 读取（CfgShapes.hpp，由 tools/make_shapes.py 生成） ----
// 形状名 -> [[[闭合, [[x, y], ...]], ...], [[x, y, 边长, 角度], ...]]，单位是图标半边长，y 向上（见 BRF_fnc_renderIcon）
BRF_shapeDefs = createHashMap;
{
    private _lines = getArray (_x >> "lines") apply {
        _x params ["_closed", "_flat"];
        private _pts = [];
        for "_i" from 0 to (count _flat - 2) step 2 do {
            _pts pushBack [_flat select _i, _flat select (_i + 1)];
        };
        [_closed == 1, _pts]
    };
    BRF_shapeDefs set [configName _x, [_lines, getArray (_x >> "fills")]];
} forEach ("true" configClasses (configFile >> "BRF_Shapes"));

// ---- 图标库：从配置 BRF_Icons 读取（CfgIcons.hpp），没有合法原版标记映射的不注册 ----
// 每项：[id, 显示名, 缩写, 贴图, 原版标记类型, 分组, 原版标记颜色, 基础图形, 音效, 缩略图]
// 缩略图：有贴图用贴图；程序图形用 ui\shapes\<形状>_ca.paa（tools/make_shapes.py 生成）
BRF_iconTable = [];
{
    private _cfg = _x;
    private _id = configName _cfg;
    private _fnc_text = {
        private _t = getText (_cfg >> _this);
        if (_t select [0, 1] == "$") then {_t = localize (_t select [1])};
        _t
    };
    private _markerType = getText (_cfg >> "markerType");
    private _markerColor = getText (_cfg >> "markerColor");
    private _error = "";
    if (_markerType == "") then {_error = "missing markerType"};
    if (_error == "" && {!isClass (configFile >> "CfgMarkers" >> _markerType)}) then {
        _error = format ["markerType '%1' is not in CfgMarkers", _markerType];
    };
    if (_error == "" && {_markerColor == ""}) then {_error = "missing markerColor"};
    if (_error == "" && _markerColor != "palette" && {!isClass (configFile >> "CfgMarkerColors" >> _markerColor)}) then {
        _error = format ["markerColor '%1' is not in CfgMarkerColors", _markerColor];
    };
    private _texture = getText (_cfg >> "texture");
    private _shape = getText (_cfg >> "shape");
    if (_error == "" && {_texture == ""} && {_shape != "none"} && {!(_shape in BRF_shapeDefs)}) then {
        _error = format ["shape '%1' is not in BRF_Shapes", _shape];
    };
    if (_error != "") then {
        diag_log text format ["[BRF] icon '%1' NOT registered: %2", _id, _error];
        continue;
    };
    private _thumb = switch (true) do {
        case (_texture != ""): {_texture};
        case (_shape in BRF_shapeDefs): {format ["\z\brf\addons\briefing\ui\shapes\%1_ca.paa", _shape]};
        default {""};
    };
    BRF_iconTable pushBack [
        _id,
        "displayName" call _fnc_text,
        getText (_cfg >> "abbr"),
        _texture,
        _markerType,
        getNumber (_cfg >> "category"),
        _markerColor,
        _shape,
        getText (_cfg >> "sound"),
        _thumb
    ];
} forEach ("true" configClasses (configFile >> "BRF_Icons"));
BRF_iconKinds = BRF_iconTable apply {_x select 0};
BRF_iconDefs = createHashMapFromArray (BRF_iconTable apply {[_x select 0, _x]});
BRF_iconCategories = ["STR_BRF_IconCatBasic", "STR_BRF_IconCatGround", "STR_BRF_IconCatAirSea", "STR_BRF_IconCatFacility", "STR_BRF_IconCatTactical", "STR_BRF_IconCatGeneral"];

// 程序纹理（不需要贴图）
BRF_texWhite = "#(rgb,8,8,3)color(1,1,1,1)";
BRF_texClear = "#(rgb,8,8,3)color(0,0,0,0)";
// drawTriangle 填充：不透明白色，颜色和透明度由 color 参数决定（wiki 说明）
BRF_texFill = "#(rgb,1,1,1)color(1,1,1,1)";
BRF_texDot = "\A3\ui_f\data\map\markers\military\dot_CA.paa";

// ---- 本机状态 ----
BRF_els = [];                   // 元素记录 [id, 类型, 颜色, 数据, t0, t1, 缓存, 作者 UID]，按绘制顺序
BRF_elMap = createHashMap;      // id -> 元素记录（同一个数组），用于去重
BRF_mpp = 1;                    // 当前地图上 1 像素 = 多少米（每帧在 BRF_fnc_render 里更新）
BRF_viewBox = [0, 0, 0, 0];     // 当前可见范围 [minX, minY, maxX, maxY]
BRF_follow = true;              // 观看端：跟随主持人视角
BRF_ptrTarget = [];             // 激光笔目标位置（收到的）
BRF_ptrPos = [];                // 激光笔显示位置（每帧向目标移动 30%）
BRF_outroStart = -1;            // 结束动画开始时间，-1 = 不在播放
BRF_outroFaded = false;
BRF_viewerIntroPending = false; // 下一次打开观看界面时播放开场动画
BRF_introStart = -1;            // 开场动画开始时间，-1 = 不在播放
BRF_introTitleShown = false;
BRF_hoverId = "";               // 主持端橡皮悬停的元素
BRF_houseCache = [];            // 房屋缓存 [中心, 半径, 三角形, 查询时间]（BRF_fnc_renderOverlay）
BRF_locCache = nil;             // 地名缓存，第一次渲染时查一次
BRF_sweepTicks = 0;             // BRF_fnc_mirrorSweep 计数
BRF_role = "zeus";              // 标注界面的身份："zeus" 主持 / "commander" 指挥官标注（见 BRF_fnc_openPresenter）
BRF_accessOpen = false;         // 主持端：权限面板开着

// ---- 主持端状态（跨多次打开主持界面保留） ----
BRF_seq = 0;
BRF_undoStack = [];
BRF_tool = TOOL_LINE;
BRF_ctrlLine = false;
BRF_rulerA = [];                // 测量尺起点 / 终点（只在本机，见 BRF_fnc_renderPreview）
BRF_rulerB = [];
BRF_color = 0;
BRF_arrow = true;
BRF_iconKind = 0;
BRF_lastView = [];
BRF_lastViewTime = 0;
BRF_ptrWanted = [];
BRF_ptrSent = [];
BRF_ptrLastTime = 0;
BRF_bgmPlaying = false;

// ---- 预案（只在主持人本机、只在这一局有效，见 BRF_fnc_plan）----
BRF_plan = [];                  // [[元素记录, 视角, 是否用镜头], ...]
BRF_planEdit = false;           // 编排模式
BRF_planEditStep = 0;           // 正在编辑的步
BRF_planPlayed = [];            // 已播放的步：[[发出的 id...], ...]
BRF_planTokens = [];            // 和 BRF_planPlayed 一一对应，撤回时作废还没出现的元素
BRF_planUndo = [];              // 和 BRF_planPlayed 一一对应，每步动作（摧毁 / 移除）的撤回信息
BRF_planLive = createHashMap;   // 预案元素 id -> 播放出去的元素 id
BRF_planSeq = 0;
BRF_planTokenSeq = 0;
BRF_viewSyncPauseUntil = 0;     // 预案镜头飞行期间不发中间视角

// ---- 中途加入：公共变量的值在 init 之前就已经送达 ----
BRF_state = [];                 // 当前元素 [[id, 类型, 颜色, 数据, 作者], ...]，由 "sync" 从 BRF_el_<id> 公共变量收集
if (isNil "BRF_drawGrants" || {!(BRF_drawGrants isEqualType [])}) then {BRF_drawGrants = []};
if (isNil "BRF_drawDenied" || {!(BRF_drawDenied isEqualType [])}) then {BRF_drawDenied = []};
if (isNil "BRF_session" || {!(BRF_session isEqualTypeArray [false, "", 0])}) then {BRF_session = [false, "", -1]};
BRF_sessionSeen = BRF_session select 0; // 本机处理过的会话状态（只在本机，见 BRF_fnc_onEvent 的 "session"）
if (isNil "BRF_view" || {!(BRF_view isEqualType [])} || {count BRF_view < 3}) then {BRF_view = []};

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
    if (!(_view isEqualType []) || {count _view < 3}) exitWith {};
    if (!BRF_follow) exitWith {};
    private _map = (uiNamespace getVariable ["BRF_viewer", displayNull]) displayCtrl IDC_BRF_MAP;
    if (isNull _map && {BRF_role == "commander"}) then {
        // 指挥官在标注界面里也可以跟随主持人视角（Space 切换）
        _map = (uiNamespace getVariable ["BRF_presenter", displayNull]) displayCtrl IDC_BRF_MAP;
    };
    if (isNull _map) exitWith {};
    // 第 4 项是补间时长：平时 0.3 秒正好填平 0.2 秒一次的发送间隔；预案切换镜头时更长
    _view params ["_cx", "_cy", "_scale", ["_duration", 0.3, [0]]];
    ctrlMapAnimClear _map;
    _map ctrlMapAnimAdd [_duration, _scale, [_cx, _cy]];
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

// ---- 原版地图：画原样式、隐藏本机的 acb_ 标记、Zeus 补建标记（见 BRF_fnc_mirrorSweep）----
if (hasInterface) then {
    [{call BRF_fnc_mirrorSweep}, MIRROR_SWEEP_INTERVAL] call CBA_fnc_addPerFrameHandler;

    // ACE MicroDAGR（可选）：它的地图每帧调用这个数组里的代码，当前地图控件在 _theMap 里
    if (isClass (configFile >> "CfgPatches" >> "ace_microdagr")) then {
        [{!isNil "ace_microdagr_miniMapDrawHandlers"}, {
            ace_microdagr_miniMapDrawHandlers pushBack {
                if (!isNil "_theMap") then {[_theMap] call BRF_fnc_mapDraw};
            };
        }, [], 60] call CBA_fnc_waitUntilAndExecute;
    };
};

// ---- 中途加入：简报正在进行就打开观看界面 ----
if ((BRF_session select 0) && {!(call BRF_fnc_isHost)}) then {
    [] call BRF_fnc_openViewer;
};
