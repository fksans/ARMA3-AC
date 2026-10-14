#include "..\script_component.hpp"
/*
 * 观看界面开场动画（每帧在观看端地图的 Draw 事件里调用，和 intro.ogg 对齐）：
 * 1. 0 – 1.5 秒：黑屏，中心小方块随每声「嘀」亮一下，下面打出 DATA LINK 和逐个增加的点
 * 2. 1.55 秒起：一道亮线从中心向左右拉满屏幕
 * 3. 亮线一分为二，上下张开（上下两块黑幕滑走），地图从中间露出来，两条亮边淡出
 * 4. 张开后标题、主持人名字、上下暗边淡入
 *
 * Arguments:
 * 0: 观看界面 <DISPLAY>
 */

params ["_display"];

if (BRF_introStart < 0) exitWith {};

private _t = diag_tickTime - BRF_introStart;
private _fnc_ease = {(((_this min 1) max 0)) call BRF_fnc_easeOutCubic};

private _x0 = safeZoneXAbs;
private _w = safeZoneWAbs;
private _half = safeZoneH / 2;
private _mid = safeZoneY + _half;

// ---- 1. 嘀嘀嘀 ----
private _ctrlMark = _display displayCtrl IDC_BRF_V_INTRO_MARK;
private _ctrlText = _display displayCtrl IDC_BRF_V_INTRO_TEXT;
if (_t < INTRO_UNFOLD_AT) then {
    _ctrlMark ctrlShow ((_t mod INTRO_BEEP_INTERVAL) < INTRO_BEEP_LEN);
    private _beeps = (floor (_t / INTRO_BEEP_INTERVAL) + 1) min INTRO_BEEPS;
    private _dots = "";
    for "_i" from 1 to _beeps do {_dots = _dots + "."};
    _ctrlText ctrlSetText (localize "STR_BRF_IntroDataLink" + _dots);
} else {
    _ctrlMark ctrlShow false;
    _ctrlText ctrlShow false;
};

// ---- 3. 上下黑幕张开 ----
private _open = ((_t - INTRO_UNFOLD_AT - INTRO_LINE_TIME) / INTRO_OPEN_TIME) call _fnc_ease;
private _top = _display displayCtrl IDC_BRF_V_INTRO_TOP;
private _bottom = _display displayCtrl IDC_BRF_V_INTRO_BOTTOM;
_top ctrlSetPosition [_x0, safeZoneY - _half * _open, _w, _half];
_top ctrlCommit 0;
_bottom ctrlSetPosition [_x0, _mid + _half * _open, _w, _half];
_bottom ctrlCommit 0;

// ---- 2. 亮线：先从中心向左右拉开，张开时分成上下两条跟着黑幕的边，然后淡出 ----
private _lineW = _w * (((_t - INTRO_UNFOLD_AT) / INTRO_LINE_TIME) call _fnc_ease);
private _edgeAlpha = 1 - ((((_t - INTRO_UNFOLD_AT - INTRO_LINE_TIME) / INTRO_EDGE_FADE) min 1) max 0);
private _visible = _t >= INTRO_UNFOLD_AT && {_edgeAlpha > 0};
{
    _x params ["_idcLine", "_idcGlow", "_y"];
    private _line = _display displayCtrl _idcLine;
    private _glow = _display displayCtrl _idcGlow;
    _line ctrlShow _visible;
    _glow ctrlShow _visible;
    if (_visible) then {
        private _lx = _x0 + (_w - _lineW) / 2;
        _line ctrlSetPosition [_lx, _y - pixelH, _lineW, 2 * pixelH];
        _line ctrlSetBackgroundColor [0.63, 1, 0.92, _edgeAlpha];
        _line ctrlCommit 0;
        _glow ctrlSetPosition [_lx, _y - 6 * pixelH, _lineW, 12 * pixelH];
        _glow ctrlSetBackgroundColor [0.40, 0.90, 0.80, 0.15 * _edgeAlpha];
        _glow ctrlCommit 0;
    };
} forEach [
    [IDC_BRF_V_INTRO_LINE_A, IDC_BRF_V_INTRO_GLOW_A, _mid - _half * _open],
    [IDC_BRF_V_INTRO_LINE_B, IDC_BRF_V_INTRO_GLOW_B, _mid + _half * _open]
];

// ---- 4. 张开后标题淡入 ----
if (_t >= INTRO_UNFOLD_AT + INTRO_LINE_TIME + INTRO_OPEN_TIME && {!BRF_introTitleShown}) then {
    BRF_introTitleShown = true;
    {
        private _ctrl = _display displayCtrl _x;
        _ctrl ctrlSetFade 0;
        _ctrl ctrlCommit INTRO_TITLE_TIME;
    } forEach [IDC_BRF_V_TITLE, IDC_BRF_V_HOST, IDC_BRF_V_MODE, IDC_BRF_V_HINT, IDC_BRF_V_TOP_BAR, IDC_BRF_V_BOTTOM_BAR];
};

// 结束：隐藏开场控件
if (_t > INTRO_UNFOLD_AT + INTRO_LINE_TIME + (INTRO_OPEN_TIME max INTRO_EDGE_FADE) + INTRO_TITLE_TIME) then {
    BRF_introStart = -1;
    {
        (_display displayCtrl _x) ctrlShow false;
    } forEach [
        IDC_BRF_V_INTRO_TOP, IDC_BRF_V_INTRO_BOTTOM,
        IDC_BRF_V_INTRO_LINE_A, IDC_BRF_V_INTRO_GLOW_A, IDC_BRF_V_INTRO_LINE_B, IDC_BRF_V_INTRO_GLOW_B,
        IDC_BRF_V_INTRO_MARK, IDC_BRF_V_INTRO_TEXT
    ];
};
