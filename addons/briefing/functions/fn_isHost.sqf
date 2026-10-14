#include "..\script_component.hpp"
/*
 * 本机是不是当前进行中的简报的主持人。
 *
 * Return Value:
 * 是 <BOOL>
 */

(BRF_session select 0) && {(BRF_session select 2) == clientOwner}
