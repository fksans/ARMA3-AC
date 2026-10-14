# 项目规则
- 语言：SQF + config.cpp，目标 Arma 3 2.18 及以上，依赖 CBA，ZEN 为可选
- 设计以 DESIGN.md 为准；需要偏离设计时先问我，不要自己改。已经确认的实现差异记在 DESIGN.md 末尾「实现说明」
- 全局变量和函数一律用 BRF_ 前缀，不新增其他前缀的公共变量
- 不确定的脚本命令或参数，先查 community.bistudio.com/wiki 再用，不凭印象写
- 每次只做当前里程碑的范围；完成后输出：改了哪些文件、进游戏的测试步骤、每一步应看到的现象
- 不修改音乐播放器（fksans/ARMA3-ZUSE）的内部代码，只通过它的公开函数（zmp_fnc_play / zmp_fnc_stop / zmp_fnc_getFavorites / zmp_fnc_getLibrary）调用
- 打包沿用 HEMTT：提交前跑 `hemtt check -p`，不能有 error / warning
