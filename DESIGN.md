# AC 风格 Zeus 实时简报系统 — 设计文档

Oct 15, 2026 · @紫伊

## 概述

**目标**：做一个由 Zeus 实时主持的作战简报工具。Zeus 在暗色战术地图上画线、标点，所有玩家全屏观看，同时在语音里听 Zeus 讲解。每一笔都以 Ace Combat 风格的动画呈现：线条延伸、图标弹出闪烁、威胁圈扩散。

**使用场景**：导演任务开打前全队集合。Zeus 打开主持界面，点「开始简报」，所有玩家弹出观看界面，视角跟着 Zeus 走。讲完点「结束简报」，可以一键把画过的内容转成普通地图标记，打的时候按 M 还能看。

**一句话方案**：作为客户端 mod 实现，和 Zeus 音乐播放器放在同一个 mod 里。Zeus 端采集笔画并修线，通过 `publicVariable` 广播；各客户端在地图控件的 Draw 事件里，以本机收到的时刻为起点播放动画。服务器不需要装任何代码。

**不在本期范围**：预制时间轴简报、3D 镜头飞越、语音录制。语音照常走 TS / Discord / 游戏内语音。

## 总体架构与关键决策

整个系统由三个决策撑起来：逻辑全在客户端，用公共变量同步，一笔画完再发。下表是每个决策的理由，后面各章都按这些前提展开。

| 决策 | 选择 | 理由 |
| --- | --- | --- |
| 代码跑在哪 | 纯客户端 mod，服务器不加载 | 腐竹已经放行客户端 mod；服务器零改动，也就零风险 |
| 怎么同步 | `publicVariable` + `addPublicVariableEventHandler` | `remoteExec` 在服务器转发前会检查函数是否存在、是否被 `CfgRemoteExec` 允许，服务器没装 mod 时有被拦的风险；公共变量由引擎直接转发，服务器不需要知道函数；变量值会留在服务器上，中途加入的人自动拿到 |
| 发送粒度 | 松开鼠标后整笔发送 | 带宽小；客户端用画线动画回放，正好盖住零点几秒的延迟 |
| 动画时钟 | 每台机器以本机收到事件的 `diag_tickTime` 为起点 | 不需要跨机器对时，也不会因为时钟偏差错位 |
| 渲染方式 | 自定义 `RscMapControl` 子类 + Draw 事件 | 引擎原生地图，缩放、平移、地形都是现成的 |
| 主持权 | 同一时间只有一个主持人 | 避免两个 Zeus 同时改完整状态时互相覆盖 |

```text
主持端 Zeus ──publicVariable──▶ 服务器（只转发，保留最后的值）──▶ 在线玩家：收到事件播放动画
                                                         └──▶ 中途加入：读最后的值直接显示结果
```

服务器上没有任何简报代码，它只是把公共变量原样转发，并保留最后的值给中途加入的人。

注意：官方 wiki 把 `addPublicVariableEventHandler` 标为「已弃用」（推荐 remoteExec），但它仍然能用，而且是本方案不依赖服务器的关键。如果以后服务器愿意加载这个 mod，可以平滑换成 remoteExec + JIP 队列，数据格式不用改。

## mod 结构、依赖与命名

简报工具作为音乐播放器 mod 里的第二个 addon，共用同一把签名密钥。文中统一用 `BRF_` 作为前缀占位，实际换成你们组的缩写，并让腐竹在 BattlEye 过滤里按这个前缀加白名单。

**依赖**

- Arma 3 2.18 及以上（`drawLine` 的线宽参数从 2.18 开始才有；当前正式版是 2.22）
- CBA\_A3：快捷键注册和初始化框架（ACE 本来就依赖它）
- ZEN：可选，用来在 Zeus 右键菜单里加入口。代码里先判断 `isClass (configFile >> "CfgPatches" >> "zen_main")` 再注册，不要写进 `requiredAddons`

**目录**

```text
addons/brf_briefing/
  config.cpp          CfgPatches、CfgFunctions、界面类、暗色地图类、CfgSounds
  functions/          每个函数一个文件 fn_xxx.sqf
  sounds/             draw_start.ogg、ping.ogg、ring.ogg、open.ogg、close.ogg
  ui/                 自制图标 .paa（可选，见渲染章节）
```

**函数清单**

| 函数 | 运行端 | 职责 |
| --- | --- | --- |
| `fn_init` | 全部（postInit） | 注册快捷键、ZEN 菜单、公共变量监听；中途加入检查 |
| `fn_openPresenter` | 主持端 | 打开主持界面，挂鼠标和键盘事件；界面回调 presenterOnLoad / presenterOnUnload 也归这里 |
| `fn_input` | 主持端 | 按当前工具处理按下、移动、松开 |
| `fn_simplify` | 主持端 | Douglas-Peucker 简化 |
| `fn_smooth` | 主持端 | Chaikin 平滑 |
| `fn_commit` | 主持端 | 把一笔组装成元素并发送 |
| `fn_send` | 主持端 | 写公共变量 + 本机立即处理 |
| `fn_syncView` | 主持端 | 节流发送视角 |
| `fn_pointer` | 主持端 | 节流发送激光笔位置 |
| `fn_undo` / `fn_clear` | 主持端 | 撤销最后一个元素 / 清屏 |
| `fn_toMarkers` | 主持端 | 简报结束后转成地图标记 |
| `fn_onEvent` | 全部 | 处理 add / del / clear / session，去重 |
| `fn_openViewer` / `fn_closeViewer` | 观看端 | 打开、关闭观看界面；界面回调 viewerOnLoad / viewerOnUnload 也归这里 |
| `fn_render` | 全部 | Draw 事件主体，主持端和观看端共用 |
| `fn_drawLine` | 全部 | 粗线 + 发光 + 进度截断 + 箭头 |
| `fn_ease` | 全部 | 缓动函数 |

主持端也调用 `fn_render`，所以 Zeus 看到的动画和玩家看到的完全一致。

## 数据模型

所有画面内容都是「元素」，所有变化都是「事件」，网络上只传这两种东西加上两个高频变量。

**元素**：`[id, 类型, 颜色序号, 数据]`

| 类型 | 数据 | 说明 |
| --- | --- | --- |
| `"line"` | `[点数组, 带箭头, 虚线, 线宽]` | 点为 `[x, y]`，坐标取整到 1 米以缩小数据量 |
| `"icon"` | `[位置, 图标种类, 标签]` | 图标种类：`"tgt"` 目标、`"lz"` 着陆区、`"ip"` 起始点、`"wp"` 航点 |
| `"ring"` | `[圆心, 半径米]` | 威胁圈（SAM、防空、炮兵射程） |
| `"area"` | `[顶点数组]` | 作战区域、禁飞区，至少 3 个点 |

**颜色序号**（调色板写在一处，方便统一调）

| 序号 | 用途 | RGBA |
| --- | --- | --- |
| 0 | 友军 | `[0.30, 0.75, 1.00, 1]` |
| 1 | 敌军 | `[1.00, 0.30, 0.25, 1]` |
| 2 | 中立 / 注意 | `[1.00, 0.80, 0.20, 1]` |
| 3 | 目标 / 强调 | `[0.40, 1.00, 0.60, 1]` |

**id**：`format ["%1_%2", clientOwner, 序号]`。序号由主持端自增；带上 `clientOwner` 是为了以后换主持人时不撞号。

**事件**

| 事件 | 格式 | 含义 |
| --- | --- | --- |
| 新增 | `["add", 元素]` | 播放该元素的出场动画 |
| 删除 | `["del", id]` | 播放淡出，结束后移除 |
| 清屏 | `["clear"]` | 全部淡出 |
| 会话 | `["session", 开关, 主持人名字]` | 打开或关闭所有人的观看界面 |

**公共变量清单**（全部以 `BRF_` 开头，方便 BattlEye 加白名单）

| 变量 | 内容 | 什么时候发 |
| --- | --- | --- |
| `BRF_evt` | 最近一个事件 | 每次增删、清屏、开关会话 |
| `BRF_state` | 当前全部元素数组 | 每次增删、清屏之后 |
| `BRF_session` | `[是否进行中, 主持人名字, 主持人 clientOwner]` | 开关会话时 |
| `BRF_view` | `[中心x, 中心y, 缩放]` | 主持端视角变化时，最多每秒 5 次 |
| `BRF_ptr` | `[x, y]`，松开时为 `[]` | 激光笔按住时，最多每秒 10 次 |

## 网络同步

事件靠 `BRF_evt` 实时推送，完整状态靠 `BRF_state` 兜底，两者配合覆盖「在线的人看动画」和「中途加入的人看结果」两种情况。

**发送（主持端）**

1. 先在本机执行一次 `fn_onEvent`。公共变量的监听不会在发送者本机触发，不手动执行的话 Zeus 自己看不到。
2. `BRF_evt = _evt; publicVariable "BRF_evt";`
3. 对新增、删除、清屏：更新本地 `BRF_state`，然后 `publicVariable "BRF_state"`。

```sqf
// fn_send
params ["_evt"];
_evt call BRF_fnc_onEvent;          // 本机先处理
BRF_evt = _evt;
publicVariable "BRF_evt";
if ((_evt select 0) in ["add", "del", "clear"]) then {
    publicVariable "BRF_state";     // BRF_state 已在 onEvent 里更新
};
```

**接收（所有客户端）**

- 在 postInit 里注册：`"BRF_evt" addPublicVariableEventHandler { (_this select 1) call BRF_fnc_onEvent };`。wiki 说明这个监听在 preInit 阶段不生效。
- `"BRF_view"` 和 `"BRF_ptr"` 各自单独注册监听，不走事件分发。
- **按 id 去重**：收到 `add` 时，如果这个 id 已经存在就忽略；收到 `del` 时，不存在的 id 也忽略。这样重复收到、乱序收到都不会出错。

**中途加入**

公共变量的值会留在服务器上，并且在中途加入的客户端跑 init 脚本之前就送达。所以 postInit 里只需要：

1. 读 `BRF_session`，如果简报正在进行就打开观看界面。
2. 读 `BRF_state`，把所有元素直接设为「已播完」（动画起点设成很久以前），或者用 2 倍速快速重放一遍。
3. 读 `BRF_view`，直接跳到主持人当前视角。

**频率与数据量**

- `BRF_view`：只在中心或缩放变化时发，两次之间至少隔 0.2 秒。
- `BRF_ptr`：只在激光笔按住时发，两次之间至少隔 0.1 秒。
- `BRF_state`：只在增删时发。一条线简化后通常 20 到 60 个点，几十个元素也就几千个数字。wiki 提醒过频繁发大数据会拖累整体网络，所以绝不能把视角或激光笔塞进这个变量。

**主持权与掉线**

- 同一时间只允许一个主持人。`BRF_session` 记录主持人；别的 Zeus 打开主持界面时显示「接管 / 只看」两个选项，接管时先发一次新的 session 事件。
- 主持人掉线后，公共变量的值仍在服务器上，画面不会丢。玩家可以自己关掉观看界面；另一个 Zeus 接管后可以继续画，或者直接结束简报。

## 主持端（Zeus）

Zeus 在 Zeus 界面上方叠一个全屏主持界面：左键画，右键拖动平移，滚轮缩放，数字键切换工具。

**入口**

- CBA 快捷键（默认 Ctrl+B）：`CBA_fnc_addKeybind`。只有 Zeus 界面（display 312）打开时才响应，打开方式为 `(findDisplay 312) createDisplay "BRF_Presenter"`。
- ZEN 右键菜单「开简报主持」：`zen_context_menu_fnc_addAction`，只在检测到 ZEN 时注册。
- 同一个快捷键在非 Zeus 玩家那里用来重新打开观看界面（见观看端）。

**界面布局**：全屏暗色地图；顶部工具栏（工具按钮、颜色、开始/结束简报、转标记）；底部状态栏（当前工具、颜色、简报状态）。

**工具与操作**

| 键 | 工具 | 操作 |
| --- | --- | --- |
| 1 | 航线 | 左键拖拽画线；按住 Shift 只保留首尾成直线；按住 Alt 提交为虚线 |
| 2 | 目标点 | 左键单击放点，弹出输入框填标签，回车确认；Tab 切换图标种类 |
| 3 | 威胁圈 | 左键按下定圆心，拖动定半径（实时显示米数），松开提交 |
| 4 | 区域 | 逐点单击，回车或双击闭合，Esc 取消 |
| 5 | 激光笔 | 按住左键，所有人看到红点跟随 |
| 6 | 橡皮 | 单击元素删除；命中判断为点到线段的屏幕距离小于 8 像素 |
| Q / E | 颜色 | 在 4 种颜色之间切换 |
| F | 聚焦 | 立即把当前视角推给所有人（不受节流限制） |
| Ctrl+Z | 撤销 | 删除自己最后一个元素 |
| Ctrl+Shift+Del | 清屏 | 二次确认后清空 |

**画线输入**

```sqf
_map ctrlAddEventHandler ["MouseButtonDown", {
    params ["_map", "_btn", "_mx", "_my"];
    if (_btn != 0) exitWith {};
    BRF_drawing = true;
    BRF_pts = [_map ctrlMapScreenToWorld [_mx, _my]];
}];

_map ctrlAddEventHandler ["MouseMoving", {
    params ["_map", "_mx", "_my"];
    if (!BRF_drawing) exitWith {};
    private _p = _map ctrlMapScreenToWorld [_mx, _my];
    private _last = BRF_pts select (count BRF_pts - 1);
    if (_p distance2D _last > BRF_minStep) then { BRF_pts pushBack _p };
}];

_map ctrlAddEventHandler ["MouseButtonUp", {
    params ["_map", "_btn"];
    if (_btn != 0 || {!BRF_drawing}) exitWith {};
    BRF_drawing = false;
    [BRF_pts] call BRF_fnc_commit;
}];
```

`ctrlMapScreenToWorld` 返回的是二维坐标 `[x, y]`。`BRF_minStep` 要跟着缩放变，每次缩放后重新算「屏幕上 4 像素对应多少米」：

```sqf
BRF_minStep = (_map ctrlMapScreenToWorld [0.5, 0.5]) distance2D (_map ctrlMapScreenToWorld [0.5 + 4 * pixelW, 0.5]);
```

画的过程中，主持端用细线、半透明实时显示原始轨迹；松开后原始轨迹消失，换成修好的线播放动画。

**修线（`fn_commit` 里依次执行）**

1. **Douglas-Peucker 简化**：容差取「屏幕 3 像素对应的米数」。用迭代（栈）实现，不要递归，避免长线堆栈过深。
2. **Chaikin 平滑**：迭代 2 次，每次把每段替换成 1/4 和 3/4 处的两个点，首尾点保留。
3. **点数上限**：平滑后超过 200 个点时，提高容差重新简化。
4. **取整**：坐标四舍五入到 1 米。
5. 按住 Shift 时跳过以上步骤，只保留首尾两点。

**视角同步（`fn_syncView`）**：在主持端 Draw 事件里每帧读取地图中心（控件中心点用 `ctrlMapScreenToWorld` 换算）和缩放（`ctrlMapScale`）。和上次发出的值相比有变化，并且距上次发送超过 0.2 秒，就发一次 `BRF_view`。按 F 时无视节流立即发。

**激光笔（`fn_pointer`）**：工具 5 下按住左键时，每 0.1 秒发一次光标世界坐标；松开时发 `[]`。

## 观看端

玩家这边只做三件事：收到开始就打开全屏地图，收到事件就播放动画，收到视角就平滑跟过去。

**打开与关闭**

- 收到 `["session", true, 名字]` 时，如果本机不是主持人，执行 `findDisplay 46 createDisplay "BRF_Viewer"`。这个界面会接管键盘鼠标，看简报期间人物不会乱动。
- 左上角显示「BRIEFING」和主持人名字，打开时播放 `open.ogg`。
- Esc 可以关掉；简报还在进行时，按同一个快捷键（Ctrl+B）重新打开，并立即补齐当前状态。
- 收到 `["session", false]` 时，画面淡出 1 秒后自动关闭。

**事件处理（`fn_onEvent`，主持端和观看端共用）**

- `add`：把元素放进本地表 `BRF_els`，同时记下 `t0 = diag_tickTime`。如果是线，提前算好每段的累计长度和总长，存在元素缓存里，渲染时不重复算。播放对应音效。
- `del`：给元素记 `t1 = diag_tickTime`，渲染时按 0.4 秒淡出，淡完再从表里移除。
- `clear`：所有元素同时记 `t1`。
- 每次 add / del / clear 都同步更新 `BRF_state`，但只有主持端会把它发出去。

**视角跟随**

```sqf
"BRF_view" addPublicVariableEventHandler {
    (_this select 1) params ["_cx", "_cy", "_scale"];
    if (!BRF_follow) exitWith {};
    private _map = (findDisplay 88100) displayCtrl 1000;
    if (isNull _map) exitWith {};
    ctrlMapAnimClear _map;
    _map ctrlMapAnimAdd [0.3, _scale, [_cx, _cy]];
    ctrlMapAnimCommit _map;
};
```

0.3 秒的补间正好填平 0.2 秒一次的发送间隔。wiki 提到动态创建的地图控件做动画时目标位置可能偏移，解决办法是在第一次动画前执行一次 `_map ctrlMapSetPosition []`。玩家屏幕比例和 Zeus 不同时，看到的范围会略有差异，这是可以接受的。

**自由查看**：观看端按 Space 切换「跟随 / 自由」。自由模式下玩家可以自己拖地图看细节，再按一次回到 Zeus 的视角。左上角显示当前模式。

**激光笔**：收到 `BRF_ptr` 只更新目标位置，渲染时每帧把显示位置向目标移动差距的 30%，看起来是顺滑的移动而不是一跳一跳。

## 渲染与动画规格

所有绘制都在地图控件的一个 Draw 事件里完成，每帧遍历 `BRF_els`。粗线直接用 `drawLine` 的线宽参数（2.18 起支持，默认值 3）；发光效果是同一条路径先用 3 倍宽、低透明度画一遍，再画本体。

**每帧通用量**

```sqf
private _now = diag_tickTime;
// 屏幕 1 像素对应多少米：箭头、标签偏移这类「固定屏幕大小」的东西都靠它换算
private _mpp = (_map ctrlMapScreenToWorld [0.5, 0.5]) distance2D (_map ctrlMapScreenToWorld [0.5 + pixelW, 0.5]);
```

**线条延伸（`fn_drawLine`）**

点在收到时转成三维 `[x, y, 0]` 存放，方便做向量运算。`_cum` 是累计长度数组，`_cum select 0` 为 0，`_L` 是总长。

```sqf
private _f = (((_now - _t0) / _dur) min 1) max 0;
private _target = _L * (_f call BRF_fnc_easeOutCubic);
private _glow = +_col; _glow set [3, 0.25 * (_col select 3)];
private _head = _pts select 0;
for "_i" from 1 to (count _pts - 1) do {
    private _a = _pts select (_i - 1);
    private _b = _pts select _i;
    if ((_cum select _i) > _target) exitWith {
        // 最后一段：按比例截断
        private _seg = ((_cum select _i) - (_cum select (_i - 1))) max 0.001;
        private _k = (_target - (_cum select (_i - 1))) / _seg;
        _head = _a vectorAdd ((_b vectorDiff _a) vectorMultiply _k);
        _map drawLine [_a, _head, _glow, _w * 3];
        _map drawLine [_a, _head, _col, _w];
    };
    _map drawLine [_a, _b, _glow, _w * 3];
    _map drawLine [_a, _b, _col, _w];
    _head = _b;
};
// 线头发光点：只在动画进行中画
if (_f < 1) then {
    _map drawIcon ["#(rgb,8,8,3)color(1,1,1,1)", _col, _head, 10, 10, 45];
};
```

- **时长**：`_dur = 0.5 + (_L / _mpp) / 1200`，上限 2 秒。也就是屏幕上越长的线画得越久，但不会拖太久。
- **箭头**：线画完后，在末端用 `getDir` 求末段方向，再用 `_head getPos [14 * _mpp, _dir + 150]` 和 `_dir - 150` 两个点画两条短线。长度按 `_mpp` 换算，所以箭头在任何缩放下都是固定的 14 像素。
- **虚线**：按「画 10 像素、空 6 像素」切段，起点偏移量随 `_now` 增加，形成流动的「行军蚂蚁」效果。

**缓动函数（`fn_ease`）**

```sqf
BRF_fnc_easeOutCubic = { 1 - (1 - _this) ^ 3 };
BRF_fnc_easeOutBack  = { private _c = 1.70158; 1 + (_c + 1) * ((_this - 1) ^ 3) + _c * ((_this - 1) ^ 2) };
```

**各元素的动画参数**

| 元素 | 阶段 | 时长 | 缓动 | 做法 |
| --- | --- | --- | --- | --- |
| 线 | 延伸 | 0.5 到 2 秒 | easeOutCubic | 上面的代码；线头带发光点 |
| 线 | 箭头弹出 | 0.15 秒 | easeOutBack | 线画完后箭头长度从 0 到 14 像素 |
| 图标 | 落下 | 0.25 秒 | easeOutBack | 尺寸从 3 倍缩到 1 倍 |
| 图标 | 闪烁 | 1 秒 | 无 | 透明度在 1 和 0.2 之间切换 3 次 |
| 图标 | 标签打字 | 每字 0.04 秒 | 无 | `drawIcon` 的文字参数每帧截取前 n 个字 |
| 图标 | 常驻 | 循环 | 无 | 外圈 4 个角括号缓慢呼吸（透明度 0.5 到 1，周期 2 秒） |
| 威胁圈 | 扩散 | 0.4 秒 | easeOutCubic | `drawEllipse` 半径从 0 到 r |
| 威胁圈 | 脉冲 | 每 2 秒一次 | 线性 | 外圈从 r 扩到 1.15 r，同时淡出 |
| 区域 | 描边 | 0.6 秒 | easeOutCubic | 按周长进度画边，和线条延伸同一套逻辑 |
| 区域 | 填充 | 0.4 秒 | 线性 | 描边完成后填充透明度从 0 升到 0.15 |
| 删除 | 淡出 | 0.4 秒 | 线性 | 所有绘制的透明度乘以 `1 - 进度` |
| 激光笔 | 跟随 | 实时 | 插值 | 红点 + 外圈光晕，每帧向目标移动 30% |

**图标怎么画（不需要贴图）**

- 菱形目标：`drawIcon` 用纯白程序纹理 `"#(rgb,8,8,3)color(1,1,1,1)"`，宽高相同，角度 45°。wiki 说明 `drawIcon` 的尺寸不随地图缩放变化，正好适合 AC 那种固定大小的标记。
- 空心菱形或角括号：用 4 条 `drawLine` 画，长度按 `_mpp` 换算。
- 想要更精致的 AC 风格图标，可以自己做 `.paa` 放进 `ui/` 目录，但不是第一版必须的。

**威胁圈与区域的填充**

- `drawEllipse` 的填充用程序纹理，wiki 建议填充时线条颜色设为白色。做法是填充和描边分两次画：先画一次只带填充的，再画一次只带描边的。
- `drawPolygon` **不支持填充**（wiki 明确说明），只用来描边。填充用 `drawTriangle`：收到区域元素时先把多边形拆成三角形缓存起来（凸多边形用扇形拆分，凹多边形用耳切法），填充纹理用 `"#(rgb,1,1,1)color(1,1,1,1)"`，颜色的透明度设为 0.15。

**性能**：wiki 提醒 draw 系列命令会拖低帧率。上限定为 60 个元素、每条线 200 个点。正常一场简报远远达不到这个量。

## 暗色地图与界面定义

暗色地图就是一个继承 `RscMapControl` 的配置类，把几十个颜色项全部压暗并换成青绿单色调，再关掉卫星图和任务标记。下面的颜色是起点，最终要进游戏边看边调。

```cpp
class RscMapControl;
class BRF_RscMap: RscMapControl {
    idc = 1000;
    x = "safeZoneXAbs"; y = "safeZoneY"; w = "safeZoneWAbs"; h = "safeZoneH";
    showMarkers = 0;              // 隐藏任务里已有的地图标记，需实测是否生效
    maxSatelliteAlpha = 0;        // 放大时不显示卫星图
    alphaFadeStartScale = 0;
    alphaFadeEndScale = 0;
    colorBackground[]          = {0.04, 0.07, 0.09, 1};
    colorOutside[]             = {0, 0, 0, 1};
    colorSea[]                 = {0.02, 0.05, 0.08, 1};
    colorForest[]              = {0.07, 0.13, 0.11, 0.6};
    colorForestBorder[]        = {0, 0, 0, 0};
    colorRocks[]               = {0.20, 0.50, 0.45, 0.2};
    colorCountlines[]          = {0.15, 0.45, 0.40, 0.25};
    colorMainCountlines[]      = {0.15, 0.45, 0.40, 0.45};
    colorCountlinesWater[]     = {0.10, 0.30, 0.45, 0.25};
    colorMainCountlinesWater[] = {0.10, 0.30, 0.45, 0.45};
    colorLevels[]              = {0.15, 0.45, 0.40, 0.35};
    colorGrid[]                = {0.20, 0.60, 0.55, 0.25};
    colorGridMap[]             = {0.20, 0.60, 0.55, 0.15};
    colorRoads[]               = {0.25, 0.55, 0.50, 0.6};
    colorRoadsFill[]           = {0.10, 0.20, 0.20, 1};
    colorMainRoads[]           = {0.35, 0.70, 0.65, 0.8};
    colorMainRoadsFill[]       = {0.12, 0.25, 0.24, 1};
    colorTracks[]              = {0.25, 0.50, 0.45, 0.3};
    colorTracksFill[]          = {0.10, 0.20, 0.20, 1};
    colorTrails[]              = {0.25, 0.50, 0.45, 0.2};
    colorTrailsFill[]          = {0.10, 0.20, 0.20, 0.6};
    colorPowerLines[]          = {0.20, 0.50, 0.45, 0.4};
    colorRailWay[]             = {0.30, 0.60, 0.55, 0.6};
    colorNames[]               = {0.40, 0.90, 0.80, 0.8};
    colorText[]                = {0.40, 0.90, 0.80, 1};
    colorInactive[]            = {0.40, 0.90, 0.80, 0.4};
};
```

地图上的树、灌木、建筑、教堂等图标也有各自的颜色子类（`Tree`、`Bush`、`Church` 等）。可以参照 wiki 上 `RscMapControlEmpty` 的写法逐个重设颜色，或者把不需要的直接设为透明。

**两个界面**

```cpp
class BRF_Viewer {
    idd = 88100;
    movingEnable = 0;
    onLoad   = "_this call BRF_fnc_viewerOnLoad";
    onUnload = "_this call BRF_fnc_viewerOnUnload";
    class controlsBackground {};
    class controls {
        class Map: BRF_RscMap { idc = 1000; };
        // 标题、主持人名字、跟随/自由提示：RscText / RscStructuredText
    };
};
class BRF_Presenter {
    idd = 88200;
    movingEnable = 0;
    onLoad   = "_this call BRF_fnc_presenterOnLoad";
    onUnload = "_this call BRF_fnc_presenterOnUnload";
    class controlsBackground {};
    class controls {
        class Map: BRF_RscMap { idc = 1000; };
        // 工具栏按钮、颜色、开始/结束、转标记、状态栏
    };
};
```

wiki 说明这类地图控件**不能放进 controls group**，所以地图必须直接放在 `controls` 下。`RscText` 等基础类在 addon 里使用前同样要先声明 `class RscText;`。

## 音效、音乐、转标记、撤销

这四项都是在核心流程跑通后再加的，彼此独立，可以按任意顺序做。

**音效**

用 `playSoundUI` 播放 mod 里的文件。它走独立的 UI 声道，不受游戏总音量混音影响。wiki 特别说明：用文件路径时**必须写上扩展名**，否则没声音。

| 文件 | 触发时机 |
| --- | --- |
| `open.ogg` / `close.ogg` | 观看界面打开、关闭 |
| `draw_start.ogg` | 线开始延伸（短促的「嗖」） |
| `ping.ogg` | 图标落下（「滴滴」，每次闪烁响一下更有 AC 味） |
| `ring.ogg` | 威胁圈扩散 |

示例：`playSoundUI ["\brf_briefing\sounds\ping.ogg", 0.8];`。实际路径取决于 pbo 前缀。

**音乐联动**

- 主持界面加一个「BGM」下拉框，列出音乐播放器的收藏曲目。
- 点「开始简报」时可选同时调用音乐播放器的「全队播放」；点「结束简报」时淡出音乐。
- 两个模块之间只通过一个函数接口交互（例如 `[曲目id] call BRF_fnc_musicPlayAll` 和 `BRF_fnc_musicStop`）。具体接口按播放器现有代码定，简报模块不直接碰播放器的内部变量。

**转地图标记（`fn_toMarkers`）**

结束简报时，主持人可以选择把当前元素转成普通的全局地图标记：

| 元素 | 转成 | 做法 |
| --- | --- | --- |
| 线 | 折线标记 | `createMarker`，然后 `setMarkerPolyline`。注意参数是**展平的**数组 `[x1, y1, x2, y2, ...]`，不是点数组 |
| 区域 | 闭合折线 | 同上，末尾补上第一个点 |
| 图标 | 图标标记 | `setMarkerType` + `setMarkerText` 写标签 |
| 威胁圈 | 椭圆标记 | `setMarkerShape "ELLIPSE"` + `setMarkerSize [r, r]` + `setMarkerBrush "Border"` |

标记名统一用 `BRF_mk_` 前缀，方便下一次简报前一键清理。

**撤销**：主持端维护一个自己发出的 id 栈，Ctrl+Z 弹出栈顶并发送 `["del", id]`。删除的元素不进栈，所以不支持「重做」，第一版不需要。

## 已知坑与实测清单

下面这些是文档和 wiki 都确认不了、必须进游戏测一下的点。每测完一项就勾掉，结果写在后面。

**部署前提**

- 所有玩家都要装这个 mod。没装的人收不到画面和音效，但不会报错。
- 用和音乐播放器同一把密钥签名，服务器 `keys` 目录不用再加东西。
- 问腐竹服务器有没有开 BattlEye 的 `publicvariable.txt` 过滤。如果有，给 `BRF_` 开头的变量加白名单，否则可能被拦甚至被踢。

**进游戏实测**

- [ ] `drawLine` 的线宽单位：是不是像素？会不会随界面缩放（UI size）变化？
- [ ] 左键在地图控件上拖拽时，有没有原生行为（框选之类）和画线冲突
- [ ] 鼠标在控件外松开时，`MouseButtonUp` 会不会触发。不触发的话，在整个 display 上补挂一个松开事件
- [ ] `ctrlMapAnimAdd` 第一次动画是否偏移；是否需要先执行 `ctrlMapSetPosition []`
- [ ] `showMarkers = 0` 能不能隐藏任务标记
- [ ] `maxSatelliteAlpha = 0` 放大后还有没有卫星图
- [ ] 中文标签在 `drawIcon` 的文字参数里能不能显示，换哪种字体能显示
- [ ] 主持界面叠在 Zeus 界面上时，Zeus 自己的快捷键会不会被吞掉，关掉主持界面后 Zeus 是否正常
- [ ] 中途加入时 `BRF_evt` 的监听会不会对已有值触发一次（有 id 去重兜底，这里只是确认行为）
- [ ] BattlEye 有没有拦截 `BRF_` 变量（看服务器日志）
- [ ] 20 人以上在线时，画一笔到所有人看到的延迟，以及 `BRF_state` 发送时有没有卡顿
- [ ] 60 个元素同时在屏上时的帧率

**代码层面的坑**

- 公共变量监听不会在发送者本机触发，主持端必须自己先调用一次 `fn_onEvent`（已写进 `fn_send`）。
- 监听要在 postInit 注册，preInit 里直接注册不生效。
- `playSoundUI` 用文件路径时必须带扩展名。
- `setMarkerPolyline` 要的是展平的 `[x1, y1, x2, y2, ...]`。
- `drawPolygon` 不能填充，填充只能靠 `drawTriangle`。
- 地图控件不能放进 controls group。

## 里程碑与验收

分 7 步做，前 3 步完成就已经能拿来开简报。每一步都有明确的「进游戏怎么验」，没验过不进下一步。

1. **M1 渲染原型（单机编辑器）**：暗色地图观看界面 + 一组写死的测试元素（线、虚线、图标、威胁圈、区域各一个）。
   - 验收：在调试控制台执行一行代码打开界面，5 种元素都按动画规格播放；缩放地图时箭头和图标保持固定屏幕大小。
2. **M2 主持输入（单机）**：主持界面、画线、简化平滑、目标点、本机预览。
   - 验收：手抖画出的线变平滑；按住 Shift 画出直线；放点时能输入标签；`fn_commit` 生成的元素格式和数据模型一致。
3. **M3 多人同步**：`fn_send`、监听、去重、会话开关。**到这一步就能用了。**
   - 验收：两台机器（局域网两个实例，或上服务器找一个人）。Zeus 画一笔，另一台在 1 秒内看到动画；开始和结束简报能打开、关闭对方的界面。
4. **M4 视角跟随 + 激光笔**。
   - 验收：Zeus 拖地图时对方画面平滑跟随、不卡顿；按 F 立即同步；观看端按 Space 能切到自由查看再切回来；激光笔红点移动顺滑。
5. **M5 完整工具集**：威胁圈、区域（含填充）、橡皮、撤销、清屏、颜色切换。
   - 验收：每种工具的动画符合规格表；撤销和橡皮删除的元素在所有人那里都淡出。
6. **M6 健壮性**：中途加入、主持权接管、主持人掉线、转地图标记、音乐联动。
   - 验收：简报进行中新加入的玩家能看到完整画面；第二个 Zeus 能接管；转出的标记所有人可见且样式正确。
7. **M7 打磨**：音效、地图配色调参、性能检查、实测清单全部勾完。
   - 验收：全队实际开一次简报，没有报错（查 RPT 日志），大家觉得「有 AC 味」。

## 交给 Claude Code：做法、模型与用量

主力用默认的 Opus 5.5，关键里程碑把思考强度调到 high；整个项目真正的瓶颈是「进游戏测试」这个人工环节，不是模型够不够聪明。

**准备**

1. 把这份文档导出为 Markdown，存成 mod 仓库里的 `DESIGN.md`。
2. 在仓库根目录写一个 `CLAUDE.md`，内容参考下面。
3. 运行 `claude update`，确认 Claude Code 版本支持 Opus 5.5（需要 v2.1.280 或更高）。

```markdown
# 项目规则
- 语言：SQF + config.cpp，目标 Arma 3 2.18 及以上，依赖 CBA，ZEN 为可选
- 设计以 DESIGN.md 为准；需要偏离设计时先问我，不要自己改
- 全局变量和函数一律用 BRF_ 前缀，不新增其他前缀的公共变量
- 不确定的脚本命令或参数，先查 community.bistudio.com/wiki 再用，不凭印象写
- 每次只做当前里程碑的范围；完成后输出：改了哪些文件、进游戏的测试步骤、每一步应看到的现象
- 不修改音乐播放器的内部代码，只通过约定的接口调用
- 打包沿用现有 mod 的构建方式
```

**工作流程**

- **一个里程碑开一个会话**，开头让它先出计划（plan mode），你确认后再写代码。
- 写完你进游戏按它给的步骤测，把 RPT 日志里的报错原样贴回去。
- 实测清单里某一项测出了结果（比如线宽单位），让它顺手更新 `DESIGN.md`，下一个会话就不会再踩。

**模型怎么选**

| 场景 | 建议 | 说明 |
| --- | --- | --- |
| 日常实现（大部分时间） | Opus 5.5，effort `medium` | Pro / Max 套餐的默认模型就是它，默认强度也是 medium |
| M1 渲染、M3 同步、疑难 bug | Opus 5.5，effort `high` | 用 `/effort high` 调高；high 会多测边界情况、多自查 |
| 想省额度 | `/model opusplan` | 计划阶段用 Opus，执行阶段自动切到 Sonnet 5.5 |
| 调配色、改文案这类小改动 | `/model sonnet` | Sonnet 5.5，够用且更省 |
| 卡在某个跨多个会话都没解决的问题 | `/model fable`（Fable 5.1） | 最强的模型，但不是默认模型；根据套餐，可能计入单独的周额度或额外扣用量积分，选之前 `/model` 选单里会标出来 |

关于「燃烧 token」：Fable 5.1 跑这个项目当然没问题，但每个里程碑都要等你进游戏测完才能往下走，模型再强也省不掉这一步。所以性价比最高的还是 Opus 5.5 加上关键处调高强度，Fable 留着攻坚用。

**用量**

- Pro 和 Max 的额度是 Claude 网页/App 和 Claude Code **共用**的，有 5 小时窗口限制和每周限制。
- 随时用 `/status` 看剩余额度。
- Pro 一次连续干一个大里程碑（比如 M1 或 M3）可能会撞到 5 小时上限；Max 5x 跑这种规模的项目会宽松很多。撞到上限可以等窗口恢复，或者开启用量积分继续用（按 API 价格计费）。
- 想严格控制在套餐额度内：登录时只用套餐账号，弹出 API 额度提示时选择拒绝。

## 参考资料

Arma 3 脚本命令（Bohemia Interactive Community wiki）

- [drawLine](https://community.bistudio.com/wiki/drawLine)：线宽参数从 2.18 开始支持
- [drawIcon](https://community.bistudio.com/wiki/drawIcon)：参数顺序，图标尺寸不随缩放变化
- [drawEllipse](https://community.bistudio.com/wiki/drawEllipse)：填充纹理
- [drawPolygon](https://community.bistudio.com/wiki/drawPolygon)：不支持填充
- [drawTriangle](https://community.bistudio.com/wiki/drawTriangle)：填充三角形
- [ctrlMapAnimAdd](https://community.bistudio.com/wiki/ctrlMapAnimAdd)：动态地图的偏移问题
- [ctrlMapScreenToWorld](https://community.bistudio.com/wiki/ctrlMapScreenToWorld)：返回二维坐标
- [CT\_MAP\_MAIN](https://community.bistudio.com/wiki/CT_MAP_MAIN)：地图控件全部配置项，包括 `showMarkers`
- [publicVariable](https://community.bistudio.com/wiki/publicVariable)：中途加入行为和带宽提醒
- [addPublicVariableEventHandler](https://community.bistudio.com/wiki/addPublicVariableEventHandler)：不在发送者本机触发，需在 postInit 注册
- [Arma 3: Remote Execution](https://community.bistudio.com/wiki/Arma_3:_Remote_Execution)：remoteExec 的校验规则
- [playSoundUI](https://community.bistudio.com/wiki/playSoundUI)：文件路径必须带扩展名
- [setMarkerPolyline](https://community.bistudio.com/wiki/setMarkerPolyline)：展平的点数组
- [SPOTREP #00120](https://dev.arma3.com/post/spotrep-00120)：Arma 3 2.22 更新

Claude Code

- [Model configuration](https://code.claude.com/docs/en/model-config)：模型别名、默认模型、effort 强度、Fable 计费
- [Use Claude Code with your Pro or Max plan](https://support.claude.com/en/articles/11145838-use-claude-code-with-your-pro-or-max-plan)：额度共用和用量积分

## 实现说明（和上文不同的地方）

第一版实现时做的取舍，都已经写进代码；如果不同意哪一条，改回设计即可。

| 项 | 设计 | 实现 | 原因 |
| --- | --- | --- | --- |
| 放在哪 | 音乐播放器 mod 里的第二个 addon | 独立仓库 / 独立 mod `@ac_briefing`（`fksans/ARMA3-AC`），前缀 `brf`，pbo 为 `brf_briefing.pbo` | 音乐播放器只给 Zeus 装，而且 `requiredAddons` 写死了 ZEN；简报要求**所有玩家**加载，放在一起会让没装 ZEN 的玩家报缺少 addon。独立 mod 只依赖 CBA。签名方式沿用播放器的 HEMTT 配置（换前缀） |
| 会话事件 | `["session", 开关, 名字]` | `["session", 开关, 名字, clientOwner]` | 接收端要据此判断「本机是不是主持人」，同时写入 `BRF_session` |
| 本机事件 | — | 增加 `["sync"]`（不上网） | 中途加入、重新打开界面时把本地元素表对齐到 `BRF_state`，元素直接显示为「已播完」 |
| 威胁圈填充 | `drawEllipse` + 程序纹理 | 扇形三角形 + `drawTriangle`（纹理 `#(rgb,1,1,1)color(1,1,1,1)`，颜色由 color 参数决定） | wiki 说 `drawEllipse` 用填充纹理时线条颜色要设为白色，填充颜色不好控制；`drawTriangle` 的填充规则 wiki 写得很明确，和区域填充同一套 |
| 缓动函数 | `fn_ease` | `fn_easeOutCubic` / `fn_easeOutBack` 两个文件 | 用法和文中的 `_f call BRF_fnc_easeOutCubic` 一致 |
| 箭头开关 | — | 主持端 A 键 / 工具栏「箭头」切换，默认开 | 元素数据里有「带箭头」字段，需要一个入口 |
| 清屏确认 | 二次确认 | 3 秒内再按一次 | 不弹对话框，不打断讲解 |
| 转标记 | — | v2 起取消「转标记 / 清标记」按钮，改为每个元素自动镜像成原版标记（见下面「原版标记镜像」） | 用户 v2 需求 R1 |
| 鼠标松开兜底 | 在 display 上补挂松开事件 | 补挂的事件推迟到下一帧处理，修饰键（Shift / Alt）用键盘事件记下的状态兜底 | 避免和地图控件自己的松开事件重复处理、丢失修饰键 |
| 地图放哪一层 | 地图直接放在 `controls` 下（不能进 controls group） | 两个界面的地图都放在 `controlsBackground`（同样不是 group） | 0.1.0 实测：地图控件获得焦点后画到同层其他控件上面，盖住了工具栏（开始 / 结束简报按钮）、状态栏和标签输入框。原版主地图也是放在背景层。点完工具栏按钮后焦点还给地图，避免回车 / 空格再次触发按钮 |
| 开场动画 | 收到开始事件后打开观看界面，播放 `open.ogg` | 开始简报时先播开场：三声沉闷拖长的「嘀……」+ 中心方块闪烁 + `DATA LINK...`，然后一道亮线从中心拉开、上下张开露出地图，标题淡入（`fn_viewerIntro`，音效 `intro.ogg`，时间轴在 `INTRO_*` 宏）。中途加入 / Ctrl+B 重新打开不播，仍用 `open.ogg` | 用户要求：「从中心铺开的感觉」 |
| 结束动画 | 收到 `["session", false]` 后画面淡出 1 秒关闭 | 和开场成对反着走：标题淡出 → 上下黑幕合拢 → 亮线收向中心 → `DATA LINK TERMINATED` + 两声渐弱的「嘀……」→ 关闭（`fn_viewerOutro`，音效 `outro.ogg`，时间轴在 `OUTRO_*` 宏，约 2.2 秒）。结束动画期间又开始简报会取消动画恢复画面；玩家自己按 Esc 仍然立即关闭 | 用户要求：退出太生硬，需要过渡 |
| 图标库 | 图标种类 `"tgt"` / `"lz"` / `"ip"` / `"wp"` | 另加 30 个图标（地面单位 9、空中 / 海上 5、设施 8、战术标记 8）和「纯文字」。图形来自 game-icons.net（CC BY 3.0，作者见 `docs/CREDITS.md`），`tools/fetch_icons.py` 下载、去底、转成白色贴图 `ui\icons\*_ca.paa`，按元素颜色着色。v2 起图标定义放在 config 注册表 `CfgIcons.hpp`（`class BRF_Icons`：中文名、缩写、贴图、形状、类别、音效、**原版标记类型和颜色**，颜色可写 `palette` 表示跟元素颜色），`fn_init` 读取并校验，标记类型 / 颜色缺失或不存在的不注册并写 RPT。北约兵种标记按颜色换阵营前缀 | 用户要求：图标太单一；自绘图标不好看，改用现成图标库；v2 要求加图标只改注册表 |
| 预案 | — | 编排模式（P）：画的内容进预案的当前步、只有主持人看得到；一步可含多个元素，每步可记录镜头（默认开，C 开关，V 重新记录）。播放：→ 下一步（开了镜头且和当前视角差得多时，所有人地图先飞过去，再逐个出元素），← 撤回上一步（只移除元素，镜头不动），Home 全部撤回。只在这一局有效，不存档。`fn_plan`；`BRF_view` 增加可选的第 4 项补间时长 | 用户要求：Zeus 现场放图标手忙脚乱，需要像 PPT 一样按键展示预制内容 |
| 地名、房屋、图例 | 暗色地图沿用原版绘制 | 自己在 Draw 事件里画（`fn_renderOverlay`）：地名按缩放分级显示（等宽字体 `EtelkaMonospacePro`、全大写、青色）；放大到 1 像素 < 1.6 米时画房屋（`nearestTerrainObjects` 查询并缓存，包围盒画成半透明块）；右下角画比例尺 | 0.1.x 实测：原版地名和房屋是深色的，在暗色底图上看不见，原版图例也没有了 |
| 测试入口 | 调试控制台一行代码 | `[] call BRF_fnc_demo`（只能单机 / 编辑器） | M1 验收用 |
| HEMTT lint | — | `.hemtt/project.toml` 里忽略 `addPublicVariableEventHandler` 的 broken 提示 | wiki 把它归到 Broken Commands 是因为**替代语法**不能用，本模组只用主语法 |
| 元素同步 | 主持端广播完整状态 `BRF_state` | 每个元素一个公共变量 `BRF_el_<id>`（删除写 `[]`），中途加入时扫描 `allVariables missionNamespace` 收集（`fn_collectState`）；`BRF_state` 只是本机缓存。元素多了第 5 项「作者 UID」，id 改为 `clientOwner_随机数_序号` | v2 允许多人同时画，单个 `BRF_state` 会被不同机器互相覆盖 |
| 原版标记镜像 | — | 画元素的那台机器同时创建全局标记 `acb_<id>`（线 / 区域 → POLYLINE，圈 → ELLIPSE Border，图标 → 注册表里的类型和颜色 + 标签文字，带箭头的线另加 `acb_<id>_arrow`），删除、清屏同步删除，简报结束后保留。原版标记做不出虚线、线宽和填充。Zeus 每 10 秒补建丢失的标记（不确定建标记的人掉线后标记会不会留下），另有「重建标记」按钮。只动 `acb_` 前缀（一键清除额外清旧版 `BRF_mk_`） | 用户 v2 需求 R1、R3 |
| 原版地图原样式 | — | 装了模组的客户端每秒检查一次：给 M 地图（display 12）、Zeus 地图（312）、`IGUI_displays` / `RscCustomInfoMiniMap` 里的地图控件挂 Draw 事件画静态原样式（`fn_mapDraw`），ACE MicroDAGR 通过 `ace_microdagr_miniMapDrawHandlers` 挂；同时 `setMarkerAlphaLocal 0` 在本机隐藏对应的 `acb_` 标记 | 用户 v2 需求 R1.5。GPS 小地图控件的位置没有官方文档，按「找所有 CT_MAP_MAIN 控件」的方式挂，需要实测 |
| 指挥官标注 | — | 观看界面按 D 进入（简报进行中、有权限）：同一个标注界面去掉激光笔、BGM、开始 / 结束、重建、权限、预案、一键清除，橡皮只擦自己的；Space 跟随 / 自由，Esc 回观看。权限：Zeus；小队长（队里不止一人）；编辑器变量 `BRF_canDraw`；Zeus 在「权限」面板授权（`BRF_drawGrants`）；禁止（`BRF_drawDenied`）优先于其他规则 | 用户 v2 需求 R2 |
| 一键清除 | 清屏 | 「清屏」改名「一键清除」：3 秒内按两次，清掉所有元素（所有人画的）和所有 `acb_` / `BRF_mk_` 标记 | 用户 v2 需求 |
| 原版地图配色与 cTab（0.3.2） | — | 原版地图（白底）上画原样式时换深色调色板 `BRF_paletteLight`，发光改为深色描边、线条加粗 1 像素，贴图图标四向偏移画深色描边，实心菱形垫深色底；简报界面的暗色样式不变。挂 Draw 的范围扩大到 `allDisplays`（除简报自己的两个界面）和 cTab 的 HUD / 对话框（`cTab_TAD_dsp` 等 uiNamespace 变量） | 0.3.0 实测：白底地图上亮色线条不显眼；cTab 的地图上看不到（`acb_` 标记本机被隐藏，又没挂上原样式） |
| 颜色（0.4.0） | 4 种颜色，Q / E 切换 | 颜色按钮改成下拉框，12 种：原 4 种 + 白 / 橙 / 粉 / 棕 / 卡其 / 灰 / 独立 / 平民，每种带白底地图用的深色版和原版标记颜色（`fn_init` 里一张表，启动时用 `isClass CfgMarkerColors` 校验，不存在的退回 ColorBlack 并写 RPT）。北约兵种标记：友军 b_、敌军 o_、其他 n_。颜色序号只能往后加 | 用户要求：会混着用颜色。旧版客户端不认识 4 号以上的颜色，全队要一起升级 |
| 通用标记与缩略图（0.4.0） | — | 新增 15 个和原版 `mil_*` 对应的「通用标记」，**程序绘制**（不用原版贴图）。所有程序图形（含原来的 4 种基础图形）的形状统一写在 `tools/make_shapes.py`，它生成 `CfgShapes.hpp`（`class BRF_Shapes`：线段 + 实心块，单位是半边长）和白色缩略图 `ui/shapes/*_ca.paa`；`fn_renderIcon` 按形状表通用绘制。图标面板、标签输入框左边显示缩略图，待确认的点显示真实图标 | 用户要求：原版贴图和我们的颜色、风格对不上；程序图形自动适配所有颜色、发光、白底描边和动画 |
| 原版地图习惯（0.4.0） | 只有当前工具的操作 | 任何工具下：双击地图放标记（区域工具双击仍是闭合，橡皮不放；目标点工具双击的第二下不会把刚弹出的标签框按空标签提交）、Ctrl+左键拖拽画线（Ctrl+Shift 直线）、悬停按 Del 删除（指挥官只限自己画的）。画线时按住 Shift / Alt，预览就是直线 / 虚线 | 用户要求：贴合原版地图的操作习惯 |
| 测量尺（0.4.0） | — | 工具 7：拖动显示距离、方位（度 + 北约密位）和整数步长刻度；只在本机显示，不广播、不生成标记。工具栏多一格，按钮略窄 | 用户要求 |
| 摧毁（0.4.0） | — | 悬停按 X 切换「已摧毁」：闪两下 → 图标 / 威胁圈上画红叉 → 渐变成灰色并保持，威胁圈不再脉冲，音效 `destroy.ogg`（`DESTROY_*` 宏和 make_sounds.py 对齐）。网络元素加第 6 项「已摧毁」、新事件 `["destroy", id, 开关]`，`BRF_el_<id>` 带状态，中途加入直接显示摧毁后的样子；原版标记重建为灰色，图标文字加「（已摧毁）」 | 用户要求：目标被摧毁 / 消失要有提示 |
| 预案互动（0.4.0） | — | 一步变为 `[元素, 视角, 镜头, 动作]`，动作是 `[destroy / remove, 预案元素 id]`，只能指向前面的步。编排时悬停前面步的元素按 X = 本步摧毁它，橡皮点它 = 本步移除它；编排视图直接显示效果。播放时先出元素再按顺序执行动作；`BRF_planLive`（预案 id → 实时 id）和 `BRF_planUndo` 让 ← 撤回时恢复被摧毁 / 移除的元素 | 用户要求：后面的步骤能影响前面步骤摆放的元素 |
| 其他（0.4.0） | 元素上限 60 | 上限 120；状态栏各项前加「当前」 | 用户要求 |
