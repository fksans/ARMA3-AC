#include "..\script_component.hpp"
/*
 * 刷新观看界面左上角的主持人名字和右上角的「跟随 / 自由」模式。
 */

private _display = uiNamespace getVariable ["BRF_viewer", displayNull];
if (isNull _display) exitWith {};

(_display displayCtrl IDC_BRF_V_HOST) ctrlSetText format [localize "STR_BRF_ViewerHost", BRF_session select 1];
(_display displayCtrl IDC_BRF_V_MODE) ctrlSetText localize (["STR_BRF_ViewerFree", "STR_BRF_ViewerFollow"] select BRF_follow);
