#include "..\script_component.hpp"
/*
 * 主持端：激光笔。按住时每 0.1 秒最多发一次光标位置，松开时立即发 []。
 *
 * Arguments:
 * 0: 操作 <STRING>
 *    "set"  - 设置位置（[] = 松开），本机立即显示
 *    "tick" - 每帧调用：有没发出去的新位置并且过了节流间隔就发
 * 1: 位置 <ARRAY>（仅 "set"）[x, y, z] 或 []
 */

params ["_mode", ["_pos", []]];

if (_mode == "set") exitWith {
    if (_pos isEqualTo []) then {
        if (BRF_ptrTarget isEqualTo [] && {BRF_ptrSent isEqualTo []}) exitWith {};
        BRF_ptrTarget = [];
        BRF_ptrWanted = [];
        if (BRF_ptrSent isNotEqualTo []) then {
            BRF_ptrSent = [];
            BRF_ptr = [];
            publicVariable "BRF_ptr";
        };
    } else {
        BRF_ptrTarget = [_pos select 0, _pos select 1, 0];
        BRF_ptrWanted = [round (_pos select 0), round (_pos select 1)];
    };
};

// "tick"
if (BRF_ptrWanted isEqualTo [] || {BRF_ptrWanted isEqualTo BRF_ptrSent}) exitWith {};
if (diag_tickTime - BRF_ptrLastTime < PTR_INTERVAL) exitWith {};
if !(call BRF_fnc_isHost) exitWith {};

BRF_ptrLastTime = diag_tickTime;
BRF_ptrSent = +BRF_ptrWanted;
BRF_ptr = BRF_ptrSent;
publicVariable "BRF_ptr";
