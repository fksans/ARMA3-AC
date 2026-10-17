#include "..\script_component.hpp"
/*
 * 主持界面 onUnload：松开激光笔、丢掉没提交的笔画。简报不会因为关掉主持界面而结束，
 * 主持人可以回 Zeus 界面操作，再按 Ctrl+B 回来。
 */

["set", []] call BRF_fnc_pointer;
BRF_drawing = false;
BRF_pts = [];
BRF_areaPts = [];
BRF_iconPending = [];
BRF_hoverId = "";
uiNamespace setVariable ["BRF_presenter", displayNull];

// 指挥官标注：Esc 关掉后回到观看界面（简报已经结束时不回）
if (BRF_role == "commander") then {
    BRF_role = "zeus";
    BRF_follow = true;
    if (BRF_session select 0) then {
        [] call BRF_fnc_openViewer;
    };
};
