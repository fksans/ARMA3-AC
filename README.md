# AC Briefing（AC 风格 Zeus 实时简报）

Zeus 在暗色战术地图上画线、标点，所有玩家全屏观看，同时在语音里听 Zeus 讲解。每一笔都以 Ace Combat 风格的动画呈现：线条延伸、图标弹出闪烁、威胁圈扩散。

- **客户端模组**：所有玩家（包括 Zeus）都要加载；**服务器不需要加载**，也没有任何服务器代码。没装的人看不到简报，但不会报错。
- 同步只用 `publicVariable`（公共变量由引擎直接转发，不经过 `remoteExec` / `CfgRemoteExec`），中途加入的玩家自动拿到当前画面。
- 依赖：**CBA_A3**。**ZEN** 可选（有的话 Zeus 右键菜单多一个入口）。可选联动 **Zeus 音乐播放器**（[fksans/ARMA3-ZUSE](https://github.com/fksans/ARMA3-ZUSE)）放 BGM。
- 设计文档：[DESIGN.md](DESIGN.md)（实现上的差异见末尾「实现说明」）。

## 怎么用

1. 导演任务开打前全队集合。Zeus 打开 Zeus 界面，按 **Ctrl+B**（或 ZEN 右键菜单「开简报主持」）打开主持界面。
2. 点 **▶ 开始简报**：所有玩家弹出全屏观看界面，先播开场（三声「嘀……」→ 画面从中心铺开），视角跟着 Zeus 走。可以在开始前先画好，开始后玩家直接看到画好的内容。
3. 边讲边画。玩家按 **Space** 在「跟随 / 自由查看」之间切换，Esc 关掉，简报进行中按 **Ctrl+B** 重新打开。
4. 讲完点 **■ 结束简报**，所有人的画面淡出关闭。需要的话点 **转标记**，把画过的内容转成普通地图标记，打的时候按 M 还能看。

### 地图

暗色战术地图上自己画了一层青色的底图信息（主持端和观看端一样）：

- **地名**：首都、城市、村庄、小地名按缩放级别逐级出现
- **房屋**：放大到街区级别（1 像素 < 1.6 米）时显示建筑轮廓块，看巷战、搜房用
- **比例尺**：右下角，长度自动取整（100 M / 500 M / 1 KM ……）

### 主持界面

左键画，右键拖动平移，滚轮缩放。

| 键 | 工具 | 操作 |
| --- | --- | --- |
| 1 | 航线 | 左键拖拽画线；松开时按住 Shift = 只保留首尾成直线；按住 Alt = 虚线（流动的「行军蚂蚁」）。A 切换末端箭头 |
| 2 | 目标点 | 左键单击放点，弹出输入框填标签（可留空），回车确认；Tab 切换图标种类：目标 / 着陆区 / 起始点 / 航点 |
| 3 | 威胁圈 | 左键按下定圆心，拖动定半径（实时显示米数），松开提交 |
| 4 | 区域 | 逐点单击，回车或双击闭合，Esc 取消 |
| 5 | 激光笔 | 按住左键，所有人看到红点跟随 |
| 6 | 橡皮 | 单击元素删除（悬停的元素会闪） |
| Q / E | 颜色 | 友军（蓝）/ 敌军（红）/ 注意（黄）/ 目标（绿） |
| F | 聚焦 | 立即把当前视角推给所有人 |
| Ctrl+Z | 撤销 | 删除自己最后一个元素 |
| Ctrl+Shift+Del | 清屏 | 3 秒内按两次 |

工具栏另外有：**BGM** 下拉框（加载了音乐播放器时列出它的收藏，开始简报时全队淡入播放，结束时淡出）、**转标记** / **清标记**（`BRF_mk_*`）、**X** 关闭（简报不会结束，主持人回 Zeus 界面操作，再按 Ctrl+B 回来）。

**主持权**：同一时间只有一个主持人。别的 Zeus 在简报进行中打开主持界面时，会看到「接管 / 只看」。主持人掉线后画面不会丢，另一个 Zeus 接管后可以继续画，或者直接结束简报。

## 项目结构（HEMTT）

```
.
├── .hemtt/project.toml / launch.toml
├── addons/briefing/                 # → brf_briefing.pbo
│   ├── $PBOPREFIX$                  # z\brf\addons\briefing
│   ├── config.cpp                   # CfgPatches（requiredAddons: cba_main）
│   ├── CfgFunctions.hpp             # BRF_fnc_*（fn_init 为 postInit）
│   ├── gui.hpp                      # 暗色地图 BRF_RscMap、观看界面 BRF_Viewer、主持界面 BRF_Presenter
│   ├── script_component.hpp         # 宏：元素下标、动画时长、上限、音效路径
│   ├── ui_defines.hpp               # IDD / IDC / 布局
│   ├── stringtable.xml              # 中文（默认）+ 英文
│   ├── sounds/                      # intro / open / close / draw_start / ping / ring .ogg（tools/make_sounds.py 生成）
│   └── functions/
│       ├── fn_init.sqf              # 快捷键、ZEN 菜单、公共变量监听、中途加入
│       ├── fn_onEvent.sqf           # add / del / clear / session / sync，按 id 去重
│       ├── fn_send.sqf              # 本机先处理 + publicVariable
│       ├── fn_buildCache.sqf        # 收到元素时预算累计长度、三角形等
│       ├── fn_render.sqf            # Draw 事件主体（主持端、观看端共用）
│       ├── fn_drawLine.sqf          # 粗线 + 发光 + 进度截断 + 虚线 + 箭头
│       ├── fn_renderIcon/Ring/Area/Preview.sqf
│       ├── fn_renderOverlay.sqf     # 地名、房屋、比例尺
│       ├── fn_viewerIntro.sqf       # 开始简报的开场动画
│       ├── fn_input.sqf             # 主持端鼠标 / 键盘
│       ├── fn_commit.sqf            # 修线（简化 + 平滑 + 取整）并发送
│       ├── fn_simplify.sqf / fn_smooth.sqf / fn_triangulate.sqf / fn_hitTest.sqf / fn_segDist.sqf
│       ├── fn_syncView.sqf / fn_pointer.sqf   # 节流发送视角 / 激光笔
│       ├── fn_undo.sqf / fn_clear.sqf / fn_toMarkers.sqf
│       ├── fn_musicPlayAll.sqf / fn_musicStop.sqf   # 只调用音乐播放器的公开函数
│       ├── fn_openPresenter.sqf / fn_presenter*.sqf
│       ├── fn_openViewer.sqf / fn_closeViewer.sqf / fn_viewer*.sqf
│       └── fn_demo.sqf              # 单机测试：一行代码看 5 种元素的动画
├── docs/SERVER_KEY_INSTALL.md       # 给腐竹：key + BattlEye 公共变量过滤
├── DESIGN.md / CLAUDE.md
└── mod.cpp
```

## 构建

和音乐播放器一样用 HEMTT（1.22.0 或更新）：

| 命令 | 作用 |
| --- | --- |
| `hemtt check -p` | 检查配置、SQF、stringtable |
| `hemtt launch` | 开发构建并启动游戏（自动加载 CBA；`hemtt launch zen` 再加 ZEN） |
| `hemtt release` | 正式构建 + 签名 + 打包 `releases/brf-<版本>.zip`（解压为 `@ac_briefing`） |

版本号在 `addons/briefing/script_version.hpp`。GitHub Actions（`.github/workflows/build.yml`）：PR / 推 main 时跑 `hemtt check`；推 `v*` 标签或手动运行时发布 Release（zip + `.bikey`）。签名方式（每版本一把 key / 固定 key）和音乐播放器 README 里「签名与 key」一节完全相同，只是前缀换成 `brf`。

## 进游戏测试步骤

代码已经按 DESIGN.md 的 M1–M7 全部写完，但**还没有进游戏实测过**。建议仍然按里程碑顺序验，前一步没过不往下走。出错时把 RPT 日志里的报错原样贴回来。

**M1 渲染（单机编辑器）**：编辑器里放一个玩家，预览，调试控制台执行 `[] call BRF_fnc_demo`。
应看到：全屏暗色青绿地图，左上角 BRIEFING；每隔 0.8 秒出现一个元素——蓝色曲线从起点延伸、线头有发光点、画完弹出箭头；黄色虚线在流动；绿色菱形从 3 倍大落下、闪 3 次（「滴」3 声）、标签逐字打出、四角括号缓慢呼吸；红色威胁圈从圆心扩散，之后每 2 秒一次脉冲；黄色区域按周长描边，再淡入填充。缩放地图时箭头、图标、标签保持固定屏幕大小。

**M2 主持输入（单机）**：编辑器里放一个 Game Master 模块并把自己设为它的 owner，预览，按 Y 进 Zeus，按 Ctrl+B。
应看到：手抖画出的线松开后变平滑；松开时按住 Shift 变直线、按住 Alt 变虚线；工具 2 放点时出现输入框，回车后图标落下；Q / E 换色、Tab 换图标种类时状态栏变化。

**M3 多人同步（到这一步就能用了）**：两台机器（局域网两个实例，或上服务器找一个人）。Zeus 点「开始简报」。
应看到：对方弹出观看界面并播放 open 音效；Zeus 画一笔，对方 1 秒内看到同样的动画；点「结束简报」，对方画面淡出 1 秒后关闭。

**M4 视角 + 激光笔**：Zeus 右键拖地图、滚轮缩放 → 对方平滑跟随；按 F 立即同步；对方按 Space 切到自由查看能自己拖地图，再按一次回到 Zeus 的视角；工具 5 按住左键 → 对方看到红点顺滑移动，松开消失。

**M5 完整工具集**：威胁圈、区域（含凹多边形的填充）、橡皮、Ctrl+Z、清屏（按两次）、四种颜色。删除的元素在所有人那里都淡出。

**M6 健壮性**：简报进行中让第三个人进服 → 直接看到完整画面并跟随视角；第二个 Zeus 打开主持界面 → 看到「接管 / 只看」，接管后能继续画；主持人退出游戏 → 其他人画面还在；「转标记」后所有人按 M 能看到折线、箭头、图标、椭圆标记；加载了音乐播放器时选一首 BGM，开始简报全队淡入，结束时淡出。

**M7 打磨**：全队实际开一次简报，查 RPT 没有报错，再按 DESIGN.md「已知坑与实测清单」逐项勾掉，结果写回 DESIGN.md。

## 给服务器腐竹

见 [docs/SERVER_KEY_INSTALL.md](docs/SERVER_KEY_INSTALL.md)：放 `.bikey`、重启；如果开了 BattlEye `publicvariable.txt` 过滤，给 `BRF_` 变量加例外。服务器不需要加载本模组。
