#include "..\script_component.hpp"
/*
 * 每秒一次（装了模组的客户端）：
 * 1. 给新出现的原版地图控件挂 Draw 事件画原样式（M 地图、Zeus 地图、GPS 小地图、cTab 等界面上的地图）
 * 2. 本机已认识的元素，它的 acb_ 标记在本机隐藏（setMarkerAlphaLocal 只影响本机，不会同步出去）
 * 3. Zeus：每 10 秒检查一次，标记不见了的元素补建（建标记的人掉线等情况）
 * ACE MicroDAGR 的地图另外通过 ace_microdagr_miniMapDrawHandlers 挂，见 BRF_fnc_init。
 */

// ---- 1. 挂 Draw ----
// 对话框类界面都在 allDisplays 里（M 地图、Zeus、cTab 平板 / 安卓 / FBCB2 / TAD 对话框等）；
// 叠在画面上的 HUD 类界面（GPS 小地图、cTab 的 TAD / 安卓 / MicroDAGR 屏幕）不在里面，按名字从 uiNamespace 取。
// cTab 的地图控件本身会显示原版标记，但 acb_ 标记在本机隐藏了，所以也要挂上原样式。
private _displays = allDisplays select {!(ctrlIDD _x in [IDD_BRF_VIEWER, IDD_BRF_PRESENTER])};
_displays append (uiNamespace getVariable ["IGUI_displays", []]);
{
    _displays pushBack (uiNamespace getVariable [_x, displayNull]);
} forEach [
    "RscCustomInfoMiniMap",
    "cTab_TAD_dsp", "cTab_Android_dsp", "cTab_microDAGR_dsp",
    "cTab_TAD_dlg", "cTab_Android_dlg", "cTab_microDAGR_dlg", "cTab_Tablet_dlg", "cTab_FBCB2_dlg"
];
{
    private _display = _x;
    if (_display isEqualType displayNull && {!isNull _display}) then {
        {
            if (ctrlType _x == 101 && {!(_x getVariable ["BRF_hooked", false])}) then { // CT_MAP_MAIN
                _x setVariable ["BRF_hooked", true];
                _x ctrlAddEventHandler ["Draw", {[_this select 0] call BRF_fnc_mapDraw}];
            };
        } forEach allControls _display;
    };
} forEach _displays;

// ---- 2. 本机隐藏 ----
{
    if ((_x select E_T1) < 0) then {
        ["hide", _x select E_ID] call BRF_fnc_mirror;
    };
} forEach BRF_els;

// ---- 3. 补建 ----
BRF_sweepTicks = BRF_sweepTicks + 1;
if (BRF_sweepTicks % MIRROR_HEAL_TICKS == 0 && {BRF_state isNotEqualTo []} && {call BRF_fnc_canPresent}) then {
    ["heal"] call BRF_fnc_mirror;
};
