#include "..\script_component.hpp"
/*
 * 观看界面 onUnload。
 */

uiNamespace setVariable ["BRF_viewer", displayNull];
BRF_viewerFadeStart = -1;
playSoundUI [SOUND_CLOSE, 0.8];
