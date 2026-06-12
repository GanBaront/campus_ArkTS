# 校园通Plus (Campus)

基于 **HarmonyOS ArkTS** 开发的校园综合助手应用，采用 Stage 模式 + ArkUI 声明式框架构建。

## 基本信息

| 项目 | 说明 |
|------|------|
| 包名 | `com.example.campus` |
| 版本 | 1.0.0 (versionCode: 1000000) |
| 目标 SDK | 6.0.2(22) (HarmonyOS API 6) |
| 运行环境 | HarmonyOS |
| 开发框架 | ArkTS + ArkUI |
| 构建系统 | Hvigor |
| 设备类型 | phone |

## 功能模块

### 1. 用户认证
- **登录页** (`LoginPage`) — 账号密码登录，支持默认测试账号（2301130077 / 123456）和新注册用户
- **注册页** (`RegisterPage`) — 手机号、姓名、学号、密码注册
- **引导页** (`Onboarding`) — 首次启动 3 页滑动引导

### 2. 首页 (`HomePage`)
- 动态日期 + 用户问候语
- 校园搜索栏
- Banner 活动推广
- 8 宫格快捷入口（课表、食堂人流、空教室、校园集市、校园卡、成绩查询、社团招新、更多服务）
- 今日课程卡片展示

### 3. 学习助手 (`StudyAssistantPage`)
- **课表管理** — 日视图时间轴 + 周视图矩阵网格双模式切换，支持增/删/改课程
- **空教室查询** — 建设中
- **成绩查询** — 绩点与成绩列表展示
- **考试安排** — 建设中

### 4. 个人中心 (`ProfilePage`)
- 用户头像与学籍信息
- 深色/浅色主题切换（全局联动）
- 字体大小滑块调节（14~24px，全局联动）
- 学籍卡包、校历、成绩单入口
- 隐私安全、帮助反馈、通用设置
- 退出登录

### 5. 社区互动
- 热门话题标签
- 推荐/找队友/匿名树洞/社团子 Tab

### 6. 校园集市
- 二手交易、失物招领、快递代取、兼职分类
- 商品卡片展示

## 项目结构

```
Campus/
├── AppScope/                    # 应用级资源
│   ├── app.json5                # 应用清单
│   └── resources/base/media/    # 图标、Banner 等媒体资源 (40+ SVG)
├── entry/                       # 主模块 (HAP)
│   └── src/main/
│       ├── module.json5         # 模块清单 (3 个 Ability)
│       ├── ets/
│       │   ├── entryability/    # EntryAbility / MainAbility / ProfileAbility
│       │   ├── pages/           # 所有页面组件
│       │   │   ├── Index.ets              # 首次启动主页面 (Tab 导航)
│       │   │   ├── HomePage.ets           # 首页内容
│       │   │   ├── StudyAssistantPage.ets # 学习助手
│       │   │   ├── ProfilePage.ets        # 个人中心
│       │   │   ├── LoginPage.ets          # 登录
│       │   │   ├── RegisterPage.ets       # 注册
│       │   │   └── Onboarding.ets         # 引导页
│       │   └── utils/
│       │       └── StorageManager.ets     # 三合一存储引擎
│       └── resources/           # 模块资源
├── hvigor/                      # Hvigor 构建配置
├── oh_modules/                  # ohpm 依赖
├── build-profile.json5          # 项目构建配置
└── oh-package.json5             # 根包清单
```

## 技术要点

### 全局状态管理

通过 `AppStorage` 实现跨组件/跨 Ability 的响应式状态同步：

```typescript
// 双向绑定（读写）
@StorageLink('appTheme') appTheme: string = 'light'
@StorageLink('appFontSize') appFontSize: number = 16

// 单向绑定（只读）
@StorageProp('appTheme') appTheme: string = 'light'
```

- **主题切换** — 任意页面修改 `appTheme`（`'light'` / `'dark'`），全部Tab 导航栏、内容区、子页面即时联动
- **字号调节** — 滑块拖动修改 `appFontSize`（14~24px），所有页面文字同步缩放

### 三合一存储引擎 (`StorageManager`)

单例模式统一管理三种 HarmonyOS 数据持久化方式：

| 存储方式 | 用途 |
|----------|------|
| `dataPreferences` | 首次启动标记 (`is_first_launch`) |
| `distributedKVStore` | 用户偏好设置（主题模式 `theme_mode`、字体大小 `font_size`） |
| `relationalStore` (SQLite) | 学生信息 CRUD + 日程数据管理 |

### 页面路由架构

```
EntryAbility (启动页) ───→ Index.ets / LoginPage
                                │
MainAbility (主窗口) ───→ HomePage.ets (Tab 容器)
                                │
          ┌─────────────────────┼─────────────────────┐
      首页 Tab            学习 Tab            我的 Tab
    HomePageView    StudyAssistantView     ProfilePage
```

### Ability 设计

| Ability | 类型 | 说明 |
|---------|------|------|
| `EntryAbility` | 主入口 | 加载启动页/登录页，初始化存储引擎，强制浅色默认 |
| `MainAbility` | 内部 | 接收登录参数，注入用户信息到 AppStorage，加载主 Tab 页 |
| `ProfileAbility` | 导出 | 支持从通知等入口直接深链跳转个人中心 |
| `EntryBackupAbility` | 扩展 | 数据备份与恢复 |

## 快速开始

### 环境要求

- DevEco Studio 4.0+
- HarmonyOS SDK API 6+
- ohpm 包管理器

### 构建运行

```bash
# 安装依赖
ohpm install

# 调试构建
hvigorw assembleHap --mode module -p product=default -p buildMode=debug

# 或在 DevEco Studio 中直接 Run
```

### 测试账号

| 字段 | 值 |
|------|-----|
| 学号 | `2301130077` |
| 密码 | `123456` |

## License

Internal educational project.
