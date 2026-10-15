#include "..\script_component.hpp"
/*
 * 刷新观看界面左上角的主持人名字、右上角的「跟随 / 自由」模式和底部提示（有标注权限的人多一条「D 进入标注」）。
 */

private _display = uiNamespace getVariable ["BRF_viewer", displayNull];
if (isNull _display) exitWith {};

(_display displayCtrl IDC_BRF_V_HOST) ctrlSetText format [localize "STR_BRF_ViewerHost", BRF_session select 1];
(_display displayCtrl IDC_BRF_V_MODE) ctrlSetText localize (["STR_BRF_ViewerFree", "STR_BRF_ViewerFollow"] select BRF_follow);
(_display displayCtrl IDC_BRF_V_HINT) ctrlSetText localize (["STR_BRF_ViewerHint", "STR_BRF_ViewerHintDraw"] select ([player] call BRF_fnc_canDraw));
