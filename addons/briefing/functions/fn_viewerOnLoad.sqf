#include "..\script_component.hpp"
/*
 * 观看界面 onLoad：挂 Draw 事件，跳到主持人当前视角，补齐当前状态。
 * Space 切换「跟随 / 自由」；Esc 关闭（简报还在进行时按 Ctrl+B 重新打开）。
 *
 * Arguments:
 * 0: Display <DISPLAY>
 */

params ["_display"];

uiNamespace setVariable ["BRF_viewer", _display];
BRF_outroStart = -1;

private _map = _display displayCtrl IDC_BRF_MAP;
// 动态创建的地图控件第一次动画时目标位置可能偏移，先执行一次
_map ctrlMapSetPosition [];
_map ctrlAddEventHandler ["Draw", {
    params ["_map"];
    [_map, false] call BRF_fnc_render;
    [ctrlParent _map] call BRF_fnc_viewerIntro;
    [ctrlParent _map] call BRF_fnc_viewerOutro;
}];

// 直接跳到主持人当前视角
if (BRF_view isNotEqualTo []) then {
    BRF_view params ["_cx", "_cy", "_scale"];
    _map ctrlMapAnimAdd [0, _scale, [_cx, _cy]];
    ctrlMapAnimCommit _map;
};

_display displayAddEventHandler ["KeyDown", {
    params ["_display", "_key"];
    if (_key == 0x01) exitWith { // DIK_ESCAPE
        _display closeDisplay 2;
        true
    };
    if (_key != 0x39) exitWith {false}; // DIK_SPACE

    BRF_follow = !BRF_follow;
    if (BRF_follow && {BRF_view isNotEqualTo []}) then {
        BRF_view params ["_cx", "_cy", "_scale"];
        private _map = _display displayCtrl IDC_BRF_MAP;
        ctrlMapAnimClear _map;
        _map ctrlMapAnimAdd [0.3, _scale, [_cx, _cy]];
        ctrlMapAnimCommit _map;
    };
    [] call BRF_fnc_viewerUpdate;
    true
}];

// 中途打开 / 重新打开：元素直接显示为「已播完」
["sync"] call BRF_fnc_onEvent;
[] call BRF_fnc_viewerUpdate;

// 开场动画：只在开始简报时播放（见 BRF_fnc_openViewer），否则直接显示
private _introControls = [
    IDC_BRF_V_INTRO_TOP, IDC_BRF_V_INTRO_BOTTOM,
    IDC_BRF_V_INTRO_LINE_A, IDC_BRF_V_INTRO_GLOW_A, IDC_BRF_V_INTRO_LINE_B, IDC_BRF_V_INTRO_GLOW_B,
    IDC_BRF_V_INTRO_MARK, IDC_BRF_V_INTRO_TEXT
];
if (missionNamespace getVariable ["BRF_viewerIntroPending", false]) then {
    BRF_viewerIntroPending = false;
    BRF_introStart = diag_tickTime;
    BRF_introTitleShown = false;
    // 标题等先隐藏，张开后再淡入
    {
        private _ctrl = _display displayCtrl _x;
        _ctrl ctrlSetFade 1;
        _ctrl ctrlCommit 0;
    } forEach [IDC_BRF_V_TITLE, IDC_BRF_V_HOST, IDC_BRF_V_MODE, IDC_BRF_V_HINT, IDC_BRF_V_TOP_BAR, IDC_BRF_V_BOTTOM_BAR];
    [_display] call BRF_fnc_viewerIntro;
    playSoundUI [SOUND_INTRO, SOUND_VOLUME];
} else {
    BRF_introStart = -1;
    {(_display displayCtrl _x) ctrlShow false} forEach _introControls;
    playSoundUI [SOUND_OPEN, SOUND_VOLUME];
};
