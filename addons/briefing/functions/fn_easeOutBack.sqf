#include "..\script_component.hpp"
/*
 * 缓动：easeOutBack（先冲过头一点再回来，用于「弹出」）。
 *
 * Arguments（_this）: 进度 0..1 <NUMBER>
 * Return Value: 缓动后的进度 <NUMBER>（中途会略大于 1）
 */

private _c = 1.70158;
1 + (_c + 1) * ((_this - 1) ^ 3) + _c * ((_this - 1) ^ 2)
