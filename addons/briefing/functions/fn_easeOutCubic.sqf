#include "..\script_component.hpp"
/*
 * 缓动：easeOutCubic。
 *
 * Arguments（_this）: 进度 0..1 <NUMBER>
 * Return Value: 缓动后的进度 <NUMBER>
 */

1 - (1 - _this) ^ 3
