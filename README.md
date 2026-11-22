# 轻记清单（QingJi List）

> HarmonyOS 待办事项管理应用 —— 《智能手机软件开发技术》课程终结性考核作品
> 版本 1.0.0　包名 `com.example.qingjilist`

## 一、项目简介

「轻记清单」是一个轻量级待办事项管理应用，围绕“记录—执行—回顾”三个环节设计：

- **记录**：快速新建任务，可设置分类、优先级、截止日期、备注与置顶；
- **执行**：点击圆圈完成、星标置顶、关键字搜索、按状态筛选、左滑删除；
- **回顾**：完成率环形图、任务总数与今日数据、分类完成分布、近七日完成趋势。

数据通过 HarmonyOS Preferences 保存在本机，退出或杀进程后不丢失。

## 二、环境要求

| 项目 | 版本 |
| --- | --- |
| DevEco Studio | 6.0.1（6.0.1.251） |
| HarmonyOS SDK | 6.0.1（API 21） |
| 构建工具 | hvigor 6.21.1 |
| 运行设备 | HarmonyOS 模拟器 / 真机（API 21） |

## 三、运行步骤

1. DevEco Studio 打开本目录（`QingJiList`），等待 Sync 完成；
2. `File → Project Structure → Signing Configs` 勾选自动签名（真机安装必需）；
3. 启动 API 21 模拟器，点击 `Run 'entry'`（`Shift+F10`）；
4. 应用启动后首页显示 9 条示例任务，可直接体验；可在「关于与设置」中重置或清空。

命令行构建（可选）：

```powershell
$env:DEVECO_SDK_HOME = "<DevEco Studio 安装目录>\sdk"
hvigorw --mode module -p product=default -p module=entry@default -p buildMode=debug assembleHap --no-daemon
hdc install -r entry\build\default\outputs\default\entry-default-unsigned.hap
hdc shell aa start -a EntryAbility -b com.example.qingjilist
```

## 四、代码结构

```
entry/src/main/ets/
├─ entryability/EntryAbility.ets   应用入口：初始化 Preferences、加载首页
├─ pages/Index.ets                 首页：列表 / 搜索 / 筛选 / 完成 / 置顶 / 滑动删除
├─ pages/TaskEditPage.ets          新建与编辑（同一页面，按路由参数 id 区分）
├─ pages/StatsPage.ets             统计：完成率、分类分布、近七日趋势
├─ pages/AboutPage.ets             关于与设置：剪贴板导出、示例数据、清空、使用说明
├─ components/TaskCard.ets         任务卡片（@Prop + 回调）
├─ components/EmptyView.ets        空状态
├─ model/TaskItem.ets              任务实体、分类/优先级常量、深拷贝
├─ model/TaskStats.ets             统计模型与计算
├─ model/RouteParams.ets           路由参数类型
├─ common/TaskStore.ets            Preferences 数据仓库（读写/排序/示例数据）
├─ common/DateUtil.ets             日期工具
└─ common/Theme.ets                主题配色
```

## 五、数据与隐私

- 存储：Preferences 文件 `qingji_store`，键 `task_list`（任务数组 JSON）、`seeded`（示例数据标记）；
- 位置：应用沙箱 `/data/storage/el2/base/haps/entry/preferences/`；
- 无网络请求、无第三方 SDK、未申请敏感权限；剪贴板写入仅在用户主动点击时发生。

## 六、已知限制

1. `router`、`promptAction.showToast`、`AlertDialog.show`、`getContext` 在 API 21 中标记为 deprecated，编译仅有告警；
2. 仅本地存储，无云端同步与到期提醒；
3. Preferences 适合轻量数据，建议任务量在数百条以内。

更完整的说明见提交材料中的《运行说明.md》与《课程报告》。
