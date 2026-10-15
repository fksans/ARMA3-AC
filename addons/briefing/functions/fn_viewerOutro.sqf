#include "..\script_component.hpp"
/*
 * 观看界面结束动画（结束简报时；每帧在观看端地图的 Draw 事件里调用，和 outro.ogg 对齐）。
 * 和开场成对，反着走：
 * 1. 标题、上下暗边淡出（BRF_fnc_closeViewer 里已经开始）
 * 2. 上下两块黑幕从屏幕边缘向中间合拢，边缘各带一条亮线
 * 3. 合上后两条亮线并成一条，从左右收向中心
 * 4. 中心方块亮起，打出 DATA LINK TERMINATED，随两声渐弱的「嘀……」闪动，然后关闭界面
 *
 * Arguments:
 * 0: 观看界面 <DISPLAY>
 */

params ["_display"];

if (BRF_outroStart < 0) exitWith {};

// 结束动画期间又开始了新的简报：取消，恢复画面
if (BRF_session select 0) exitWith {
    BRF_outroStart = -1;
    {
        (_display displayCtrl _x) ctrlShow false;
    } forEach [
        IDC_BRF_V_INTRO_TOP, IDC_BRF_V_INTRO_BOTTOM,
        IDC_BRF_V_INTRO_LINE_A, IDC_BRF_V_INTRO_GLOW_A, IDC_BRF_V_INTRO_LINE_B, IDC_BRF_V_INTRO_GLOW_B,
        IDC_BRF_V_INTRO_MARK, IDC_BRF_V_INTRO_TEXT
    ];
    {
        private _ctrl = _display displayCtrl _x;
        _ctrl ctrlSetFade 0;
        _ctrl ctrlCommit 0.2;
    } forEach [IDC_BRF_V_TITLE, IDC_BRF_V_HOST, IDC_BRF_V_MODE, IDC_BRF_V_HINT, IDC_BRF_V_TOP_BAR, IDC_BRF_V_BOTTOM_BAR];
    [] call BRF_fnc_viewerUpdate;
};

private _t = diag_tickTime - BRF_outroStart;
// 收拢用 easeInCubic：开头慢、越合越快，和开场的 easeOutCubic 正好相反
private _fnc_easeIn = {((_this min 1) max 0) ^ 3};

private _x0 = safeZoneXAbs;
private _w = safeZoneWAbs;
private _half = safeZoneH / 2;
private _mid = safeZoneY + _half;

// ---- 2. 黑幕合拢 ----
private _close = ((_t - OUTRO_CLOSE_START) / OUTRO_CLOSE_TIME) call _fnc_easeIn;
private _top = _display displayCtrl IDC_BRF_V_INTRO_TOP;
private _bottom = _display displayCtrl IDC_BRF_V_INTRO_BOTTOM;
_top ctrlSetPosition [_x0, safeZoneY - _half + _half * _close, _w, _half];
_top ctrlCommit 0;
_bottom ctrlSetPosition [_x0, safeZoneY + safeZoneH - _half * _close, _w, _half];
_bottom ctrlCommit 0;

// ---- 2/3. 亮线：合拢时跟着两块黑幕的边，合上后并成一条向中心收 ----
private _closedAt = OUTRO_CLOSE_START + OUTRO_CLOSE_TIME;
private _lineAlpha = (((_t - OUTRO_CLOSE_START) / 0.15) min 1) max 0;
private _lineW = _w * (1 - (((_t - _closedAt) / OUTRO_LINE_TIME) call _fnc_easeIn));
private _visible = _t >= OUTRO_CLOSE_START && {_lineW > pixelW};
{
    _x params ["_idcLine", "_idcGlow", "_y"];
    private _line = _display displayCtrl _idcLine;
    private _glow = _display displayCtrl _idcGlow;
    _line ctrlShow _visible;
    _glow ctrlShow _visible;
    if (_visible) then {
        private _lx = _x0 + (_w - _lineW) / 2;
        _line ctrlSetPosition [_lx, _y - pixelH, _lineW, 2 * pixelH];
        _line ctrlSetBackgroundColor [0.63, 1, 0.92, _lineAlpha];
        _line ctrlCommit 0;
        _glow ctrlSetPosition [_lx, _y - 6 * pixelH, _lineW, 12 * pixelH];
        _glow ctrlSetBackgroundColor [0.40, 0.90, 0.80, 0.15 * _lineAlpha];
        _glow ctrlCommit 0;
    };
} forEach [
    [IDC_BRF_V_INTRO_LINE_A, IDC_BRF_V_INTRO_GLOW_A, safeZoneY + _half * _close],
    [IDC_BRF_V_INTRO_LINE_B, IDC_BRF_V_INTRO_GLOW_B, safeZoneY + safeZoneH - _half * _close]
];

// ---- 4. DATA LINK TERMINATED + 两声「嘀」----
private _ctrlMark = _display displayCtrl IDC_BRF_V_INTRO_MARK;
private _ctrlText = _display displayCtrl IDC_BRF_V_INTRO_TEXT;
private _textOn = _t >= _closedAt + OUTRO_LINE_TIME;
_ctrlText ctrlShow _textOn;
if (_textOn) then {
    _ctrlText ctrlSetText localize "STR_BRF_OutroText";
    private _beeping = _t < OUTRO_BEEP_1
        || {_t >= OUTRO_BEEP_1 && {_t < OUTRO_BEEP_1 + OUTRO_BEEP_LEN}}
        || {_t >= OUTRO_BEEP_2 && {_t < OUTRO_BEEP_2 + OUTRO_BEEP_LEN}};
    _ctrlMark ctrlShow _beeping;
} else {
    _ctrlMark ctrlShow false;
};

// 最后文字淡出，然后关闭
if (_t >= OUTRO_END && {!BRF_outroFaded}) then {
    BRF_outroFaded = true;
    {
        private _ctrl = _display displayCtrl _x;
        _ctrl ctrlSetFade 1;
        _ctrl ctrlCommit 0.25;
    } forEach [IDC_BRF_V_INTRO_MARK, IDC_BRF_V_INTRO_TEXT];
};
if (_t >= OUTRO_END + 0.3) then {
    _display closeDisplay 2;
};
