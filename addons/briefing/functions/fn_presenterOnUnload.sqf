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
