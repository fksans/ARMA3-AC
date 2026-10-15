#include "..\script_component.hpp"
/*
 * 这个玩家能不能在简报上标注（非 Zeus 的指挥官）。按顺序判断：
 * 1. Zeus（curator）：能
 * 2. 被 Zeus 在「权限」面板里禁止（BRF_drawDenied）：不能
 * 3. 被 Zeus 授权（BRF_drawGrants），或者编辑器里给单位设了 BRF_canDraw = true：能
 * 4. 小队长（队里不止他一个人）：能
 * 其他人只能看。
 *
 * 编辑器用法（单位的初始化栏）：this setVariable ["BRF_canDraw", true];
 *
 * Arguments:
 * 0: 单位 <OBJECT> (default: player)
 * 1: 只看自动规则，忽略授权 / 禁止 <BOOL> (default: false)（权限面板显示「自动」时的结果用）
 *
 * Return Value:
 * 能 <BOOL>
 */

params [["_unit", player, [objNull]], ["_autoOnly", false, [false]]];

if (isNull _unit) exitWith {false};
if (!isNull getAssignedCuratorLogic _unit) exitWith {true};

private _uid = getPlayerUID _unit;
if (!_autoOnly && {_uid in BRF_drawDenied}) exitWith {false};
if (!_autoOnly && {_uid in BRF_drawGrants}) exitWith {true};
if (_unit getVariable ["BRF_canDraw", false]) exitWith {true};

leader group _unit == _unit && {count units group _unit > 1}
