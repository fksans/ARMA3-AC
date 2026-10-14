#include "..\script_component.hpp"
/*
 * 从本地元素表里移除已经淡出完毕的元素。
 */

private _now = diag_tickTime;
private _keep = [];
{
    private _t1 = _x select E_T1;
    if (_t1 < 0 || {_now - _t1 < FADE_OUT_TIME}) then {
        _keep pushBack _x;
    } else {
        BRF_elMap deleteAt (_x select E_ID);
    };
} forEach BRF_els;
BRF_els = _keep;
