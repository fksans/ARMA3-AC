#include "..\script_component.hpp"
/*
 * 主持端：把视角发给所有人。每帧在主持端 Draw 事件里调用；
 * 中心或缩放有变化、并且距上次发送超过 0.2 秒才发。只在自己主持的简报进行中时发。
 *
 * Arguments:
 * 0: 地图控件 <CONTROL>
 * 1: 无视节流立即发（F 键 / 开始简报） <BOOL> (default: false)
 */

params ["_map", ["_force", false]];

if !(call BRF_fnc_isHost) exitWith {};
if !(call BRF_fnc_canPresent) exitWith {};
if (!_force && {diag_tickTime < BRF_viewSyncPauseUntil}) exitWith {};

ctrlPosition _map params ["_x0", "_y0", "_w", "_h"];
private _center = _map ctrlMapScreenToWorld [_x0 + _w / 2, _y0 + _h / 2];
private _view = [round (_center select 0), round (_center select 1), ctrlMapScale _map];

if (!_force && {_view isEqualTo BRF_lastView || {diag_tickTime - BRF_lastViewTime < VIEW_INTERVAL}}) exitWith {};

BRF_lastView = _view;
BRF_lastViewTime = diag_tickTime;
BRF_view = _view;
publicVariable "BRF_view";
