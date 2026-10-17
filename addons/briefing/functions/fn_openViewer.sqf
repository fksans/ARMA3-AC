#include "..\script_component.hpp"
/*
 * 打开观看界面（全屏暗色地图）。这个界面会接管键盘鼠标，看简报期间人物不会乱动。
 * 主持界面开着时不打开（Zeus 自己用主持界面看）。
 *
 * 玩家正开着别的界面（ACE / 原版军火库、物品栏、暂停菜单、对话框）时先不打开，等关掉再开：
 * 观看界面硬叠上去会把 ACE 军火库界面挤掉而它自己的关闭处理不跑，军火库镜头留着，
 * 人卡在军火库视角里出不来，之后也再打不开军火库（ace_arsenal_camera 一直不是 nil）。
 *
 * Arguments:
 * 0: 播放开场动画 <BOOL> (default: false)。只有开始简报时为 true；中途加入、按 Ctrl+B 重新打开时直接显示
 */

params [["_intro", false, [false]]];

if (!hasInterface) exitWith {};
BRF_viewerIntroPending = _intro;

private _fnc_busy = {
    dialog
    || {!isNil "ace_arsenal_camera"}
    || {!isNull (uiNamespace getVariable ["BIS_fnc_arsenal_cam", objNull])}
    || {!isNull findDisplay 602} // 物品栏
    || {!isNull findDisplay 49}  // 暂停菜单
};

// 简报进行中要等的话不播开场（等到关掉界面时开场已经没意义了），并提示一下。
// 单机 demo 没有简报会话：从调试控制台执行时也要等，关掉控制台后照样打开、照样播开场
private _deferred = call _fnc_busy;
private _wasActive = BRF_session param [0, false];
if (_deferred && _wasActive) then {
    BRF_viewerIntroPending = false;
    systemChat localize "STR_BRF_MsgViewerDeferred";
};

[{!isNull findDisplay 46 && {!(call (_this select 1))}}, {
    params ["_deferred", "", "_wasActive"];
    if (
        !isNull (uiNamespace getVariable ["BRF_viewer", displayNull])
        || {!isNull (uiNamespace getVariable ["BRF_presenter", displayNull])}
    ) exitWith {
        BRF_viewerIntroPending = false; // 没打开新界面，开场标记不留到下一次
    };
    // 等过的话：这期间简报结束了、或者自己成了主持人，就不打开了
    if (_deferred && {_wasActive} && {!(BRF_session param [0, false]) || {(BRF_session param [2, -1]) == clientOwner}}) exitWith {};

    // Zeus 界面开着时叠在它上面，否则叠在游戏画面上
    private _parent = findDisplay 312;
    if (isNull _parent) then {_parent = findDisplay 46};
    _parent createDisplay "BRF_Viewer";
}, [_deferred, _fnc_busy, _wasActive]] call CBA_fnc_waitUntilAndExecute;
