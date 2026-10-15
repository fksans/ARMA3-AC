#include "..\script_component.hpp"
/*
 * 从公共变量收集当前所有元素。每个元素各自存在一个公共变量 BRF_el_<id> 里（删除后是 []），
 * 谁画的谁发，多人同时画也不会互相覆盖；中途加入的人在 init 之前就已经收到这些变量。
 *
 * Return Value:
 * 元素列表 [[id, 类型, 颜色序号, 数据, 作者], ...] <ARRAY>
 */

private _out = [];
{
    // allVariables 返回的名字都是小写
    if (_x select [0, 7] == "brf_el_") then {
        private _el = missionNamespace getVariable [_x, []];
        if (_el isEqualType [] && {count _el >= 4} && {(_el select 0) isEqualType ""}) then {
            _out pushBack _el;
        };
    };
} forEach allVariables missionNamespace;
_out
