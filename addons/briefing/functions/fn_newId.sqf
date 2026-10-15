#include "..\script_component.hpp"
/*
 * 生成一个新的元素 id：clientOwner_序号（带上 clientOwner 是为了换主持人时不撞号）。
 *
 * Return Value:
 * id <STRING>
 */

private _id = "";
while {_id == "" || {_id in BRF_elMap}} do {
    BRF_seq = BRF_seq + 1;
    _id = format ["%1_%2", clientOwner, BRF_seq];
};
_id
