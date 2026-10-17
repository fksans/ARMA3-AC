#include "..\script_component.hpp"
/*
 * 生成一个新的元素 id：clientOwner_随机数_序号。
 * clientOwner 让不同机器不撞号；随机数防止中途加入的人拿到别人掉线前用过的 clientOwner、序号又从头数。
 *
 * Return Value:
 * id <STRING>
 */

if (isNil "BRF_idSalt") then {BRF_idSalt = floor random 100000};
private _id = "";
while {_id == "" || {_id in BRF_elMap}} do {
    BRF_seq = BRF_seq + 1;
    _id = format ["%1_%2_%3", clientOwner, BRF_idSalt, BRF_seq];
};
_id
