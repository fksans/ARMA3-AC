#include "..\script_component.hpp"
/*
 * 观看界面 onUnload。
 */

uiNamespace setVariable ["BRF_viewer", displayNull];
// 播过结束动画的话 outro.ogg 已经响过了，不再叠一声关闭音
if (BRF_outroStart < 0) then {
    playSoundUI [SOUND_CLOSE, SOUND_VOLUME];
};
BRF_outroStart = -1;
