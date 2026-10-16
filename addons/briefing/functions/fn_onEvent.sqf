#include "..\script_component.hpp"
/*
 * 处理一个简报事件（主持端和观看端共用）。动画时钟以本机收到事件的 diag_tickTime 为起点，
 * 不需要跨机器对时。按 id 去重：重复收到、乱序收到都不会出错。
 * 每次 add / del / clear 都同步更新 BRF_state（本机的当前元素表，和各个 BRF_el_<id> 公共变量对应，见 BRF_fnc_send）。
 *
 * Arguments（_this 就是事件数组）:
 * ["add", 元素, 立即(可选，默认 false)]  元素 = [id, 类型, 颜色序号, 数据, 作者 UID]；立即 = 不播动画、不出声
 * ["del", id]
 * ["clear"]
 * ["session", 开关, 主持人名字, 主持人 clientOwner]
 * ["sync"]   本机专用：从公共变量重新收集 BRF_state，再把本地元素表对齐过去（中途加入 / 重新打开界面）
 */

params [["_type", "", [""]]];

private _now = diag_tickTime;

switch (_type) do {
    case "add": {
        params ["", ["_el", [], [[]]], ["_instant", false, [false]]];
        _el params [["_id", "", [""]], ["_elType", "", [""]], ["_color", 0, [0]], ["_data", [], [[]]], ["_author", "", [""]], ["_destroyed", false, [false]]];
        if (_id == "") exitWith {};
        private _old = BRF_elMap getOrDefault [_id, []];
        if (_old isNotEqualTo [] && {(_old select E_T1) < 0}) exitWith {};
        if (_old isNotEqualTo []) then {
            // 同一个 id 删掉后又被用上（很少见）：旧记录直接丢掉
            BRF_els deleteAt (BRF_els find _old);
            BRF_elMap deleteAt _id;
        };

        private _cache = [_elType, _data] call BRF_fnc_buildCache;
        if (_cache isEqualTo []) exitWith {}; // 数据不合法

        _color = (round _color) max 0 min (count BRF_palette - 1);
        private _record = [_id, _elType, _color, _data, [_now, -1e6] select _instant, -1, _cache, _author, [-1, -1e6] select _destroyed];
        BRF_els pushBack _record;
        BRF_elMap set [_id, _record];

        if (BRF_state findIf {(_x select 0) == _id} == -1) then {
            BRF_state pushBack [_id, _elType, _color, _data, _author, _destroyed];
        };

        // 原版标记由本机画原样式代替：标记已经到了的话立即隐藏（还没到的由 BRF_fnc_mirrorSweep 补）
        ["hide", _id] call BRF_fnc_mirror;

        // 音效只在界面打开时播放（图标的「滴滴」在 BRF_fnc_renderIcon 里随闪烁播放）
        if (!_instant && {
            !isNull (uiNamespace getVariable ["BRF_viewer", displayNull])
            || {!isNull (uiNamespace getVariable ["BRF_presenter", displayNull])}
        }) then {
            switch (_elType) do {
                case "line";
                case "area": {playSoundUI [SOUND_DRAW, SOUND_VOLUME]};
                case "ring": {playSoundUI [SOUND_RING, SOUND_VOLUME]};
            };
        };

        // 删除后已经淡完、但界面没开（没人渲染）的元素顺便清掉
        if (count BRF_els > MAX_ELEMENTS) then {[] call BRF_fnc_purge};
    };

    case "del": {
        params ["", ["_id", "", [""]]];
        private _record = BRF_elMap getOrDefault [_id, []];
        if (_record isEqualTo [] || {(_record select E_T1) >= 0}) exitWith {};

        _record set [E_T1, _now];
        private _index = BRF_state findIf {(_x select 0) == _id};
        if (_index != -1) then {
            BRF_state deleteAt _index;
        };
        if (BRF_hoverId == _id) then {BRF_hoverId = ""};
    };

    case "destroy": {
        // 摧毁 / 恢复：闪两下 → 画叉 → 变灰（见 BRF_fnc_renderElement）；恢复时直接回到原样
        params ["", ["_id", "", [""]], ["_on", true, [true]]];
        private _record = BRF_elMap getOrDefault [_id, []];
        if (_record isEqualTo [] || {(_record select E_T1) >= 0}) exitWith {};
        if (((_record param [E_DESTROYED, -1]) != -1) isEqualTo _on) exitWith {};
        _record set [E_DESTROYED, [-1, _now] select _on];
        private _index = BRF_state findIf {(_x select 0) == _id};
        if (_index != -1) then {
            (BRF_state select _index) set [5, _on];
        };
        if (_on && {
            !isNull (uiNamespace getVariable ["BRF_viewer", displayNull])
            || {!isNull (uiNamespace getVariable ["BRF_presenter", displayNull])}
        }) then {
            playSoundUI [SOUND_DESTROY, SOUND_VOLUME];
        };
    };
    case "clear": {
        {
            if ((_x select E_T1) < 0) then {
                _x set [E_T1, _now];
            };
        } forEach BRF_els;
        BRF_state = [];
        BRF_hoverId = "";
    };

    case "session": {
        params ["", ["_active", false, [false]], ["_name", "", [""]], ["_owner", -1, [0]]];
        BRF_session = [_active, _name, _owner];

        if (_active) then {
            if (_owner == clientOwner) then {
                [false] call BRF_fnc_closeViewer;
            } else {
                [true] call BRF_fnc_openViewer;
            };
        } else {
            BRF_ptrTarget = [];
            [true] call BRF_fnc_closeViewer;
            // 指挥官的标注界面跟着关
            if (BRF_role == "commander") then {
                (uiNamespace getVariable ["BRF_presenter", displayNull]) closeDisplay 2;
            };
        };

        [] call BRF_fnc_viewerUpdate;
        [] call BRF_fnc_presenterUpdate;
    };

    case "sync": {
        BRF_state = [] call BRF_fnc_collectState;
        // 本地有、BRF_state 里没有的：立即移除（不播淡出）
        private _ids = createHashMapFromArray (BRF_state apply {[_x select 0, true]});
        {
            if ((_x select E_T1) < 0 && {!((_x select E_ID) in _ids)}) then {
                _x set [E_T1, _now - FADE_OUT_TIME];
            };
        } forEach BRF_els;
        [] call BRF_fnc_purge;

        // BRF_state 里有、本地没有的：直接设为「已播完」
        {
            ["add", _x, true] call BRF_fnc_onEvent;
            // 已经有的元素：摧毁状态对齐（不播动画）
            private _record = BRF_elMap getOrDefault [_x select 0, []];
            private _on = _x param [5, false];
            if (_record isNotEqualTo [] && {((_record param [E_DESTROYED, -1]) != -1) isNotEqualTo _on}) then {
                _record set [E_DESTROYED, [-1, -1e6] select _on];
            };
        } forEach +BRF_state;
    };
};
