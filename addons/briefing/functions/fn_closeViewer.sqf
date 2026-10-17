#include "..\script_component.hpp"
/*
 * 关闭观看界面。
 *
 * Arguments:
 * 0: 播放结束动画 <BOOL>（true：结束简报时用，播完结束动画再关，见 BRF_fnc_viewerOutro；false：立即关闭）
 */

params [["_animate", true, [false]]];

private _display = uiNamespace getVariable ["BRF_viewer", displayNull];
if (isNull _display) exitWith {};

if (!_animate) exitWith {
    _display closeDisplay 2;
};

if (BRF_outroStart >= 0) exitWith {}; // 已经在播

// 开场还没播完就结束了：直接接到结束动画
BRF_introStart = -1;
BRF_outroStart = diag_tickTime;
BRF_outroFaded = false;

// 黑幕放回「全开」的位置并显示，亮线、方块、文字先隐藏，每帧由 BRF_fnc_viewerOutro 驱动
{
    (_display displayCtrl _x) ctrlShow false;
} forEach [
    IDC_BRF_V_INTRO_LINE_A, IDC_BRF_V_INTRO_GLOW_A, IDC_BRF_V_INTRO_LINE_B, IDC_BRF_V_INTRO_GLOW_B,
    IDC_BRF_V_INTRO_MARK, IDC_BRF_V_INTRO_TEXT
];
{
    private _ctrl = _display displayCtrl _x;
    _ctrl ctrlSetFade 0;
    _ctrl ctrlCommit 0;
} forEach [IDC_BRF_V_INTRO_MARK, IDC_BRF_V_INTRO_TEXT];
[_display] call BRF_fnc_viewerOutro;
(_display displayCtrl IDC_BRF_V_INTRO_TOP) ctrlShow true;
(_display displayCtrl IDC_BRF_V_INTRO_BOTTOM) ctrlShow true;

// 标题、主持人名字、上下暗边淡出
{
    private _ctrl = _display displayCtrl _x;
    _ctrl ctrlSetFade 1;
    _ctrl ctrlCommit OUTRO_FADE_TIME;
} forEach [IDC_BRF_V_TITLE, IDC_BRF_V_HOST, IDC_BRF_V_MODE, IDC_BRF_V_HINT, IDC_BRF_V_TOP_BAR, IDC_BRF_V_BOTTOM_BAR];

playSoundUI [SOUND_OUTRO, SOUND_VOLUME];

// 兜底：万一 Draw 事件没跑（界面被别的东西盖住等），到时间也要关
[{
    params ["_display"];
    if (!isNull _display && {BRF_outroStart >= 0}) then {
        _display closeDisplay 2;
    };
}, [_display], OUTRO_END + 1] call CBA_fnc_waitAndExecute;
