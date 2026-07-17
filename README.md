<img width="100%" height="100%" alt="image" src="https://github.com/user-attachments/assets/16f35967-8770-41d7-80a3-d88571e6ae2b" />

这是一个服务器内地面掉落物管理的小模组喵。

当前功能：
- 房间内所有安装了模组的玩家都可以按 `N` 打开 `GIM` 面板。
- `GIM` 只会在面板打开时才开始扫描玩家当前所在 shard 里的地面掉落物。
- 如果扫描过程中再次按 `N` 关闭面板，会立刻中断当前扫描，不会继续后台扫完。
- 列表会把当前 shard 内所有地面掉落物按总数量从高到低排序。
- 每一行都可以直接点 `Take` 把该 prefab 的地面物品往玩家物品栏和背包里塞。
- 如果背包空间不够，就只拿得下当前实际还能装进去的那部分，不会溢出。
- 兼容常见的大堆叠环境，像 `99 stack` 这类改堆叠上限的服里，会按服务器当前真实堆叠规则判断还能拿多少。

说明：
- 这里只统计“当前玩家所在 shard”里的地面掉落物，也就是主世界只看主世界，洞穴只看洞穴。
- 统计单位按真实物品数量算，不是按地上实体个数算；所以一组 `wood x80` 会按 `80` 计入排序。
- 拾取时不会走人物跑过去捡的动作，而是直接按服务端库存规则塞进玩家主背包和溢出容器。
- 当前 UI 故意做得很朴素，没有额外贴图资源，重点是稳定和够用。
- 当前版本没有做外部配置文件开关。
- 已记录：dedicated server 不该去 `require("widgets/...")` 这类本地 HUD 脚本；UI 注入逻辑必须先做 `not TheNet:IsDedicated()` 之类的隔离，否则 shard 启动时就可能直接炸在 mod 加载阶段。
- 已记录：被 `require` 的子脚本在 DST strict 环境里不要顶层裸用 `GLOBAL`；像 widget/helper 这种文件更稳的写法是 `local _G = _G`，否则很容易报 `variable 'GLOBAL' is not declared` 并把开房流程打断。
- 已记录：不要默认以为原生 Lua 全局在 mod 环境里都能直接用；这次 `rawget(_G, "TheNet")` 就在启动期报了 `attempt to call global 'rawget' (a nil value)`，所以这类读取优先直接写成 `_G.TheNet` 更稳。
- 已记录：原版 `ScrollableList` 在走 `updatefn + static_widgets` 这套模式时，不会自动把那些行 widget 挂进显示树；如果只传数组不 `AddChild`，就会出现“扫描统计有数，但列表一项都不显示”的假空列表问题。
- 已记录：`images/ui.xml` 里的 `blank.tex` 更接近透明点击占位，不适合拿来做真正可见的面板底板；要做稳定可见的纯色背景，用 `images/global.xml` 的 `square.tex` 这类实心贴图更稳。
- 已记录：这类实时列表里，原版滚动条和默认按钮贴图有时候交互边界不稳，尤其是自定义行内按钮和滚动同时存在时；当前版本已经改成自绘长方形按钮 + 固定行渲染，尽量减少 hover/拖动类崩溃面。
- 已记录：HUD 布局不要把翻页按钮、页码、关闭提示和列表内容混在同一块自由摆放；最好拆成独立 header/list/footer 分区，再做固定列对齐，不然后期很容易互相压住。
- 已记录：DST 这类 HUD widget 不是天然裁剪容器，列表行如果总高度超出预留 viewport，就会直接视觉上盖到状态栏、列头和 footer；行数、行高、间距必须先把几何账算平再摆控件。

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
- 当前 `ScrollableList` 使用的每一行静态 widget 也已经显式挂进 `scroll_list`，避免列表数据正常但行控件根本没显示出来。
- 当前 GIM 面板底板、标题带、状态带、列表底都已经改成 `square.tex` 实心底图，冬季雪地背景下也能稳定看清文字。
- 当前列表已经不再依赖原版滚动条，而是改成固定 8 行渲染加上下翻页按钮，按钮也换成了自绘长方形样式。
- 当前扫描完成后会在状态行直接显示本次扫描耗时秒数。
- 当前 HUD 布局已经固定成 `header / status / column / list / footer` 五段，行数和间距按真实 viewport 几何对齐，不再靠碰运气摆坐标。
- `modmain.lua` 入口先 `modimport("scripts/gim.lua")`，服务端扫描和 RPC 都从这里挂起。
- HUD 注入走 `AddClassPostConstruct("screens/playerhud", ...)`，`N` 键切换则是包一层 `PlayerHUD:OnRawKey`。
- 客户端发请求用 `SendModRPCToServer(GetModRPC(...))`，当前有 `request_scan`、`cancel_scan`、`request_pickup` 三个入口。
- 服务端注册入口用 `AddModRPCHandler(...)`，结果回客户端则走 `SendModRPCToClient(GetClientModRPC(...), userid, ...)`。
- 客户端接回包用 `AddClientModRPCHandler(...)`，然后把 `scan_begin / scan_chunk / scan_complete / pickup_result` 转给 `widgets/gimwidget.lua`。
- 分帧扫描依赖 `player:DoTaskInTime(0, ...)`，每次只处理 `SCAN_BATCH_SIZE` 个 `Ents`，避免开面板瞬间卡死。
- 掉落物判定目前看 `inventoryitem.owner == nil`，并排除 `INLIMBO`、`NOCLICK`、`FX`、`DECOR` 这些不该进列表的实体。
- 拾取链路核心接口是 `inventory:CanAcceptCount(inst, stack_size)`、`stackable:Get(accept_count)`、`inventory:GiveItem(...)`，兼容大堆叠也主要靠这套真实库存规则。
- 玩家扫描状态缓存挂在 `player._gim_scan_open / _gim_scan_serial / _gim_scan_state / _gim_scan_task`，下次回看扫描取消或重扫逻辑先找这几个字段。

Current features:
- Every player with the mod installed can press `N` to open the `GIM` panel.
- `GIM` only starts scanning when the panel is opened.
- The scan is limited to the current shard the player is standing in.
- Pressing `N` again while scanning closes the panel and cancels the active scan immediately.
- The list is sorted by total dropped item count from highest to lowest.
- Each row can directly `Take` that prefab into the player's inventory and overflow container space.
- If the inventory is nearly full, pickup only takes the amount that still fits.
- Common larger-stack environments such as `99 stack` style servers are handled by following the live server inventory and stack rules.

Notes:
- The scan covers only the shard the current player is in, so overworld and caves are counted separately.
- Counts are based on real stack size, not just entity count on the ground.
- Pickup does not make the character path over and loot manually; it inserts items directly through normal server inventory rules.
- The UI is intentionally plain and asset-free in this version.
- There are no external configuration options in this build.
- Recorded pitfall: dedicated server shards should not `require` local HUD widget modules. Client UI hooks need an explicit `not TheNet:IsDedicated()` style guard.
- Recorded pitfall: under DST strict mode, required helper/widget files should avoid top-level `GLOBAL` reads; `local _G = _G` is the safer pattern there.
- Recorded pitfall: do not assume every vanilla Lua global is exposed in the mod environment. This build hit `attempt to call global 'rawget' (a nil value)`, so `_G.TheNet` is the safer read pattern here.
- Recorded pitfall: vanilla `ScrollableList` does not automatically parent `static_widgets` into the visible widget tree. If you only pass the row array without `AddChild`, the scan can report valid counts while the list still renders as empty.
- Recorded pitfall: `images/ui.xml` `blank.tex` behaves more like a transparent placeholder than a real visible panel fill, so stable opaque UI backgrounds should use a solid texture such as `images/global.xml` `square.tex`.
- Recorded pitfall: stock scrollbars and default button skins can become brittle in custom live-updating row lists. This build now uses drawn rectangular buttons plus fixed-row paging to reduce hover and drag failure cases.
- Recorded pitfall: do not let paging buttons, page text, close hints, and row content float in the same loose layout block. A separate header/list/footer split with fixed columns stays far more stable.
- Recorded pitfall: DST HUD widgets are not automatic clipping containers. If the total row stack exceeds the real viewport, rows will visually cover the status line, column labels, and footer, so row count, row height, and spacing need to fit the geometry before any fine-tuning.
- `modmain.lua` is the bootstrap. It `modimport`s `scripts/gim.lua`, injects the HUD widget through `AddClassPostConstruct("screens/playerhud", ...)`, and wraps `PlayerHUD:OnRawKey` to toggle the panel with `N`.
- Client requests go up through `SendModRPCToServer(GetModRPC(...))` with `request_scan`, `cancel_scan`, and `request_pickup`.
- Server request handlers are registered through `AddModRPCHandler(...)` in `scripts/gim.lua`.
- Server responses go back through `SendModRPCToClient(GetClientModRPC(...), userid, ...)`, and the client receives them through `AddClientModRPCHandler(...)`.
- The live result flow is `scan_begin -> scan_chunk -> scan_complete`, with `pickup_result` sent after a take action.
- Shard scanning is sliced with `player:DoTaskInTime(0, ...)` and `SCAN_BATCH_SIZE` so opening the panel does not try to process all `Ents` in one frame.
- Ground-item filtering currently checks `components.inventoryitem.owner == nil` and excludes `INLIMBO`, `NOCLICK`, `FX`, and `DECOR`.
- Pickup capacity follows the real inventory API chain: `inventory:CanAcceptCount(inst, stack_size)`, optional `stackable:Get(accept_count)`, then `inventory:GiveItem(...)`.
- Per-player scan state lives on `player._gim_scan_open`, `_gim_scan_serial`, `_gim_scan_state`, and `_gim_scan_task`, which is the first place to inspect when scan cancel or rescan behavior looks wrong.
