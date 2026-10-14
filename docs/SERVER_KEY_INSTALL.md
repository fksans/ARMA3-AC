# AC Briefing：服务器设置说明（给腐竹）

**AC Briefing** 是**客户端模组**：所有玩家（包括 Zeus）自己加载，服务器**不需要**加载它（不要写进 `-mod` / `-serverMod`），服务器上也没有任何简报代码。
服务器只需要做两件事：信任它的签名 key，以及（如果开了的话）在 BattlEye 过滤里放行 `BRF_` 开头的公共变量。

## 1. 放 key

把发布包里的 `.bikey` 复制到 **Arma 3 服务器根目录**下的 `keys` 文件夹（和 `a3.bikey` 放在一起），然后**重启服务器**（重开任务不够）：

```
Arma 3 Server/
├── keys/
│   ├── a3.bikey
│   ├── cba_a3.bikey
│   └── brf.bikey            ← 固定 key 时的文件名
│       （或 brf_0.1.0.0.bikey，默认方式下每个版本一把）
```

`server.cfg` 里 `verifySignatures = 2;` 保持不变即可。

## 2. BattlEye 公共变量过滤（只有开了 `publicvariable.txt` 才需要）

简报通过 `publicVariable` 同步，变量名全部以 `BRF_` 开头：

| 变量 | 内容 |
| --- | --- |
| `BRF_evt` | 最近一个简报事件 |
| `BRF_state` | 当前全部简报元素 |
| `BRF_session` | 简报是否进行中、主持人 |
| `BRF_view` | 主持人的地图视角（最多每秒 5 次） |
| `BRF_ptr` | 激光笔位置（最多每秒 10 次） |

如果服务器的 BattlEye 目录里有 `publicvariable.txt` 并且第一行是踢人 / 记录的规则（例如 `5 ""`），在那一行末尾加上例外：

```
5 "" !="BRF_evt" !="BRF_state" !="BRF_session" !="BRF_view" !="BRF_ptr"
```

（如果已经有 `!="..."` 例外，接在后面即可。）没有 `publicvariable.txt` 就什么都不用做。

## 3. 验证

- 玩家带着 `@ac_briefing`（+ CBA）进服，没有被踢 = key 放对了。
- Zeus 开始简报后，其他玩家弹出全屏「BRIEFING」画面 = 公共变量没被拦。被拦的话 BattlEye 日志里会有 `PublicVariable Restriction` 之类的记录。
