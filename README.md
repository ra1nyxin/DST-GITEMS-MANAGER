这是一个偏向服务器内地面掉落物管理的小模组喵。

当前功能：
- 房间内所有安装了模组的玩家都可以按 `N` 打开 `GIM` 面板。
- `GIM` 只会在面板打开时才开始扫描玩家当前所在 shard 里的地面掉落物。
- 如果扫描过程中再次按 `N` 关闭面板，会立刻中断当前扫描，不会继续后台扫完。
- 列表会把当前 shard 内所有地面掉落物按总数量从高到低排序。
- 每一行都可以直接点 `Take` 把该 prefab 的地面物品往玩家物品栏和背包里塞。
- 如果背包空间不够，就只拿得下当前实际还能装进去的那部分，不会溢出。
- 兼容常见的大堆叠环境，像 `99 stack` 这类改堆叠上限的服里，会按服务器当前真实堆叠规则判断还能拿多少。
- 这是服务端模组，不是 clientOnly；所有客户端都需要安装。

说明：
- 这里只统计“当前玩家所在 shard”里的地面掉落物，也就是主世界只看主世界，洞穴只看洞穴。
- 统计单位按真实物品数量算，不是按地上实体个数算；所以一组 `wood x80` 会按 `80` 计入排序。
- 拾取时不会走人物跑过去捡的动作，而是直接按服务端库存规则塞进玩家主背包和溢出容器。
- 当前 UI 故意做得很朴素，没有额外贴图资源，重点是稳定和够用。
- 当前版本没有做外部配置文件开关。
- 已记录：dedicated server 不该去 `require("widgets/...")` 这类本地 HUD 脚本；UI 注入逻辑必须先做 `not TheNet:IsDedicated()` 之类的隔离，否则 shard 启动时就可能直接炸在 mod 加载阶段。
- 已记录：被 `require` 的子脚本在 DST strict 环境里不要顶层裸用 `GLOBAL`；像 widget/helper 这种文件更稳的写法是 `local _G = _G`，否则很容易报 `variable 'GLOBAL' is not declared` 并把开房流程打断。
- 已记录：不要默认以为原生 Lua 全局在 mod 环境里都能直接用；这次 `rawget(_G, "TheNet")` 就在启动期报了 `attempt to call global 'rawget' (a nil value)`，所以这类读取优先直接写成 `_G.TheNet` 更稳。

实现记录：
- `modmain.lua` 通过 `AddClassPostConstruct("screens/playerhud", ...)` 把 `GIM` 挂到本地 HUD 上，并用 `OnRawKey` 接 `N` 键切换。
- 服务端扫描逻辑集中在 `scripts/gim.lua`，只在收到打开请求后才对当前 shard 的 `Ents` 做分帧扫描。
- 扫描结果会先按 prefab 聚合数量，再按数量从高到低排序，然后通过 `ClientModRPC` 分块发回客户端。
- 关闭面板时会给服务端发取消请求，已经排队的扫描任务会被直接丢掉，不继续结算。
- 拾取逻辑同样在 `scripts/gim.lua`，会对目标 prefab 的所有地面物品逐个按 `inventory:CanAcceptCount(...)` 和 `inventory:GiveItem(...)` 结算。
- 如果遇到大堆叠，只会先拆出当前还能容纳的数量，再塞进背包；这块直接跟随服务器当下的 `stackable.maxsize` 规则，所以能兼容常见 `99 stack` 类改动。
- 客户端列表界面集中在 `scripts/widgets/gimwidget.lua`，使用原版 `ScrollableList`、`ImageButton`、`Text` 做最小可用实现。
- 当前已经专门把 HUD 注入限制在非 dedicated 环境，避免服务端进程误加载本地界面脚本。
- 当前 `scripts/widgets/gimwidget.lua` 也已经避开 strict 环境下对 `GLOBAL` 的顶层裸读写法。
- 当前 `modmain.lua` 里对 `TheNet` 的读取也已经回退成直接 `_G.TheNet`，不再依赖 `rawget` 这种在 mod 环境里不一定存在的全局函数。

Current features:
- Every player with the mod installed can press `N` to open the `GIM` panel.
- `GIM` only starts scanning when the panel is opened.
- The scan is limited to the current shard the player is standing in.
- Pressing `N` again while scanning closes the panel and cancels the active scan immediately.
- The list is sorted by total dropped item count from highest to lowest.
- Each row can directly `Take` that prefab into the player's inventory and overflow container space.
- If the inventory is nearly full, pickup only takes the amount that still fits.
- Common larger-stack environments such as `99 stack` style servers are handled by following the live server inventory and stack rules.
- This is a server-side mod, not a client-only one, so all clients need the mod installed.

Notes:
- The scan covers only the shard the current player is in, so overworld and caves are counted separately.
- Counts are based on real stack size, not just entity count on the ground.
- Pickup does not make the character path over and loot manually; it inserts items directly through normal server inventory rules.
- The UI is intentionally plain and asset-free in this version.
- There are no external configuration options in this build.
- Recorded pitfall: dedicated server shards should not `require` local HUD widget modules. Client UI hooks need an explicit `not TheNet:IsDedicated()` style guard.
- Recorded pitfall: under DST strict mode, required helper/widget files should avoid top-level `GLOBAL` reads; `local _G = _G` is the safer pattern there.
- Recorded pitfall: do not assume every vanilla Lua global is exposed in the mod environment. This build hit `attempt to call global 'rawget' (a nil value)`, so `_G.TheNet` is the safer read pattern here.
