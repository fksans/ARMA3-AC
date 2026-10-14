#include "..\script_component.hpp"
/*
 * 关闭观看界面。
 *
 * Arguments:
 * 0: 淡出 <BOOL>（true：画面淡出 1 秒后关闭；false：立即关闭）
 */

params [["_fade", true, [false]]];

private _display = uiNamespace getVariable ["BRF_viewer", displayNull];
if (isNull _display) exitWith {};

if (!_fade) exitWith {
    _display closeDisplay 2;
};

if (BRF_viewerFadeStart >= 0) exitWith {}; // 已经在淡出

BRF_viewerFadeStart = diag_tickTime;
{
    _x ctrlSetFade 1;
    _x ctrlCommit VIEWER_FADE_TIME;
} forEach (allControls _display);

[{
    params ["_display"];
    if (isNull _display) exitWith {};
    // 淡出期间又开始了新的简报：恢复
    if (BRF_session select 0) exitWith {
        BRF_viewerFadeStart = -1;
        {
            _x ctrlSetFade 0;
            _x ctrlCommit 0.2;
        } forEach (allControls _display);
    };
    _display closeDisplay 2;
}, [_display], VIEWER_FADE_TIME] call CBA_fnc_waitAndExecute;
