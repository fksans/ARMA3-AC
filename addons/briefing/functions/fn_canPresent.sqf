#include "..\script_component.hpp"
/*
 * 当前玩家能不能打开主持界面（必须是 curator）。
 *
 * Return Value:
 * 可以 <BOOL>
 */

hasInterface && {!isNull getAssignedCuratorLogic player}
