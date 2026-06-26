/**
 * ProfilePage — 个人中心 / 设置页面
 * ==================================
 * 功能：
 *   - 用户信息展示（头像/姓名/学号）
 *   - 偏好设置（KV Store 主题切换 + 字号滑块）
 *   - 系统设置菜单
 *   - 开发调试工具（学生管理入口 + 首次启动标记重置）
 *   - 退出登录
 *
 * 同时作为 HomePage「我的」Tab 组件和独立 Ability 页面使用。
 */
import common from '@ohos.app.ability.common';
import Want from '@ohos.app.ability.Want';
import promptAction from '@ohos.promptAction';
import dataPreferences from '@ohos.data.preferences';
import { StorageManager } from '../utils/StorageManager';
import { BackgroundTaskManager, ContinuousTaskState, ReminderItem, ReminderResult } from '../utils/BackgroundTaskManager';

@Entry
@Component
export struct ProfilePage {
  // 实时响应全局状态机的用户信息
  @StorageProp('userName') userName: string = '甘凯洋';
  @StorageProp('userId') userId: string = '2301130077';

  // 🛠️ 核心修复：状态统一双向绑定到 AppStorage，冷启动默认值彻底设为 'light'（浅色模式）
  @StorageLink('appTheme') appTheme: string = 'light';
  @StorageLink('appFontSize') appFontSize: number = 17;

  private storage = StorageManager.getInstance();
  private btm = BackgroundTaskManager.getInstance();

  // 实验5：后台自习计时（长时任务 TASK_KEEPING）
  @State isStudying: boolean = false;
  @State studyStatusText: string = '未开始';
  @State studyStartTimestamp: number = 0;
  @State studyElapsedText: string = '00:00';
  private timerId: number = -1;
  // 实验5：倒计时提醒（代理提醒 + 本地实时倒计时）
  @State reminderSeconds: number = 60;
  @State reminderInput: string = '60';
  @State activeReminderCount: number = 0;
  @State activeReminders: ReminderItem[] = [];
  @State reminderFeedback: string = '';
  private countdownTimerId: number = -1;

  // 页面生命周期：异步初始化拉取 KV Store 缓存数据并安全注入 AppStorage
  async aboutToAppear() {
    try {
      const savedTheme = await this.storage.getSetting('theme_mode', 'light');
      AppStorage.set('appTheme', savedTheme);

      const savedFontSize = await this.storage.getSetting('font_size', '17');
      AppStorage.set('appFontSize', Number(savedFontSize));
    } catch (e) {
      console.error('读取 KV Store 偏好设置失败: ' + JSON.stringify(e));
    }

    // 实验5：初始化时查询有效提醒数量
    try {
      const stats = await this.btm.getReminderStats();
      this.activeReminderCount = stats.total;
    } catch (e) {
      console.error('查询提醒统计失败: ' + JSON.stringify(e));
    }

    // 实验5：恢复自习计时——从 Preferences 读取持久化的计时状态
    try {
      const ctx = getContext(this) as common.UIAbilityContext;
      const pref = await dataPreferences.getPreferences(ctx.getApplicationContext(), 'AppLaunchPreferences');
      const savedStudying = await pref.get('study_is_running', false) as boolean;
      const savedTimestamp = await pref.get('study_start_timestamp', 0) as number;
      if (savedStudying && savedTimestamp > 0) {
        // 恢复计时状态（进程被杀后重新进入）
        this.isStudying = true;
        this.studyStartTimestamp = savedTimestamp;
        this.refreshStudyElapsed();
        // 重新启动定时器
        this.timerId = setInterval(() => {
          this.refreshStudyElapsed();
        }, 1000);
        // 重新申请长时任务
        const ctx = getContext(this);
        const state: ContinuousTaskState = await this.btm.startContinuousTask(ctx);
        this.studyStatusText = state.message;
      }
    } catch (e) {
      console.error('自习状态恢复失败: ' + JSON.stringify(e));
    }
  }

  build() {
    Column() {
      // --- 顶部导航栏 ---
      Row() {
        Image($r('app.media.back'))
          .width(24)
          .height(24)
          .onClick(() => {
            const context = getContext(this) as common.UIAbilityContext;
            // 安全判定：只有独立 Ability 视窗存在时才执行终结，防止内嵌 Tab 闪退
            if (context) {
              try {
                context.terminateSelf();
              } catch (e) {
                console.warn('ProfilePage 处于内嵌组件模式，忽略自毁操作');
              }
            }
          })
        Text('个人中心')
          .fontSize(this.appFontSize + 2) // 响应全局字号
          .fontWeight(FontWeight.Bold)
          .margin({ left: 15 })
          .fontColor(this.appTheme === 'dark' ? '#FFFFFF' : '#1A1A1A') // 响应深浅色主题
        Blank()
      }
      .width('100%')
      .height(56)
      .padding({ left: 20, right: 20 })
      .backgroundColor(this.appTheme === 'dark' ? '#1E1E1E' : Color.White)

      // --- 1. 用户信息头部 ---
      Row({ space: 20 }) {
        Stack({ alignContent: Alignment.BottomEnd }) {
          Image($r('app.media.avatar'))
            .width(85)
            .height(85)
            .borderRadius(42.5)

          Stack() {
            Circle({ width: 26, height: 26 })
              .fill('#005DFF')
              .border({ width: 2, color: this.appTheme === 'dark' ? '#1E1E1E' : Color.White })

            Image($r('app.media.camera'))
              .width(14)
              .height(14)
          }
          .offset({ x: 2, y: 2 })
        }
        .width(85)
        .height(85)

        Column({ space: 8 }) {
          Text(this.userName)
            .fontSize(this.appFontSize + 6) // 响应全局字号
            .fontWeight(FontWeight.Bold)
            .fontColor(this.appTheme === 'dark' ? '#FFFFFF' : '#1A1A1A')

          Text('软件工程 · 2023级')
            .fontSize(this.appFontSize - 2) // 响应全局字号
            .fontColor(this.appTheme === 'dark' ? '#AAAAAA' : '#999999')

          Row() {
            Image($r('app.media.id')).width(14).height(14).margin({ right: 6 })
            Text(`学号：${this.userId}`)
              .fontSize(this.appFontSize - 4) // 响应全局字号
              .fontColor('#005DFF')
              .fontWeight(FontWeight.Medium)
          }
          .backgroundColor(this.appTheme === 'dark' ? '#2A3B5C' : '#EBF2FF')
          .padding({ left: 10, right: 10, top: 4, bottom: 4 })
          .borderRadius(6)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')
      .padding({ left: 25, right: 25, top: 20, bottom: 30 })

      // --- 2. 交互数据区 ---
      Row() {
        this.StatItem('12', '我的发布')
        this.StatItem('45', '我的收藏')
        this.StatItem('128', '积分')
      }
      .width('100%')
      .margin({ bottom: 25 })

      // --- 3. 功能列表区域 ---
      Scroll() {
        Column({ space: 16 }) {
          // 学籍与基础数据卡片
          Column() {
            this.MenuRow($r('app.media.user'), '学籍卡包')
            Divider().margin({ left: 50, right: 15 }).color(this.appTheme === 'dark' ? '#2C2C2C' : '#F7F8FA')
            this.MenuRow($r('app.media.calendar'), '2026春季校历')
            Divider().margin({ left: 50, right: 15 }).color(this.appTheme === 'dark' ? '#2C2C2C' : '#F7F8FA')
            this.MenuRow($r('app.media.report'), '我的成绩单')
          }
          .backgroundColor(this.appTheme === 'dark' ? '#1E1E1E' : Color.White)
          .borderRadius(20)
          .shadow({ radius: 10, color: '#0A000000', offsetY: 4 })

          // ⚙️ 实验4 KV Store 要求：应用偏好设置卡片组
          Column({ space: 14 }) {
            Row() {
              Image($r('app.media.setting')).width(20).height(20).margin({ left: 18, right: 15 })
              Text('应用偏好设置 (KV Store)')
                .fontSize(this.appFontSize) // 动态响应全局字号
                .fontColor(this.appTheme === 'dark' ? '#FFFFFF' : '#333333')
                .fontWeight(FontWeight.Bold)
            }
            .width('100%')
            .margin({ top: 16 })

            // 1. 主题切换单选面板
            Row() {
              Text('应用主题模式')
                .fontSize(this.appFontSize - 2)
                .fontColor(this.appTheme === 'dark' ? '#CCCCCC' : '#4A4A4A')
                .margin({ left: 50 })
              Blank()
              Row({ space: 12 }) {
                Row() {
                  Radio({ value: 'light', group: 'themeGroup' }).checked(this.appTheme === 'light')
                    .onChange(async (isChecked: boolean) => {
                      if (isChecked) {
                        this.appTheme = 'light'; // 广播全局更新
                        await this.storage.putSetting('theme_mode', 'light');
                        promptAction.showToast({ message: '主题已切换为: 浅色模式' });
                      }
                    })
                  Text('浅色').fontSize(this.appFontSize - 2).fontColor(this.appTheme === 'dark' ? '#FFF' : '#333').margin({ left: 4 })
                }
                Row() {
                  Radio({ value: 'dark', group: 'themeGroup' }).checked(this.appTheme === 'dark')
                    .onChange(async (isChecked: boolean) => {
                      if (isChecked) {
                        this.appTheme = 'dark'; // 广播全局更新
                        await this.storage.putSetting('theme_mode', 'dark');
                        promptAction.showToast({ message: '主题已切换为: 深色模式' });
                      }
                    })
                  Text('深色').fontSize(this.appFontSize - 2).fontColor(this.appTheme === 'dark' ? '#FFF' : '#333').margin({ left: 4 })
                }
              }
              .margin({ right: 18 })
            }
            .width('100%')

            Divider().margin({ left: 50, right: 15 }).color(this.appTheme === 'dark' ? '#2C2C2C' : '#F7F8FA')

            // 2. 字体大小微调滑块（实验标准范围：14 ~ 24 px）
            Column({ space: 8 }) {
              Row() {
                Text('全局文字预览大小')
                  .fontSize(this.appFontSize - 2)
                  .fontColor(this.appTheme === 'dark' ? '#CCCCCC' : '#4A4A4A')
                  .margin({ left: 50 })
                Blank()
                Text(`${this.appFontSize} px`)
                  .fontSize(this.appFontSize - 2)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#005DFF')
                  .margin({ right: 18 })
              }
              .width('100%')

              Slider({
                value: this.appFontSize,
                min: 14,
                max: 24,
                step: 1,
                style: SliderStyle.InSet // 🛠️ 核心修复：拼写严格对齐为驼峰 InSet，消灭编译错误
              })
                .blockColor('#005DFF')
                .trackColor(this.appTheme === 'dark' ? '#333333' : '#F2F3F5')
                .selectedColor('#005DFF')
                .showTips(true)
                .margin({ left: 45, right: 15, bottom: 16 })
                .onChange(async (value: number) => {
                  this.appFontSize = Math.floor(value); // 广播全局字号
                  await this.storage.putSetting('font_size', this.appFontSize.toString());
                })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
          }
          .backgroundColor(this.appTheme === 'dark' ? '#1E1E1E' : Color.White)
          .borderRadius(20)
          .shadow({ radius: 10, color: '#0A000000', offsetY: 4 })

          // 系统基本设置卡片
          Column() {
            this.MenuRow($r('app.media.privacy'), '隐私与安全')
            Divider().margin({ left: 50, right: 15 }).color(this.appTheme === 'dark' ? '#2C2C2C' : '#F7F8FA')
            this.MenuRow($r('app.media.help'), '帮助与反馈')
            Divider().margin({ left: 50, right: 15 }).color(this.appTheme === 'dark' ? '#2C2C2C' : '#F7F8FA')
            this.MenuRow($r('app.media.setting'), '通用设置')
          }
          .backgroundColor(this.appTheme === 'dark' ? '#1E1E1E' : Color.White)
          .borderRadius(20)
          .shadow({ radius: 10, color: '#0A000000', offsetY: 4 })

          // 调试工具卡片
          Column({ space: 12 }) {
            Row() {
              Image($r('app.media.setting')).width(20).height(20).margin({ right: 10 })
              Text('开发调试工具').fontSize(this.appFontSize - 2).fontWeight(FontWeight.Bold)
                .fontColor(this.appTheme === 'dark' ? '#FFFFFF' : '#333333')
            }.width('100%').margin({ top: 4, left: 4 })

            Button('重置首次启动标记 (调试用)')
              .width('100%').height(42).fontSize(this.appFontSize - 3)
              .backgroundColor('#6B7280')
              .onClick(() => {
                this.resetFirstLaunchFlag();
              })
          }
          .padding(16)
          .backgroundColor(this.appTheme === 'dark' ? '#1E1E1E' : Color.White)
          .borderRadius(20)
          .shadow({ radius: 10, color: '#0A000000', offsetY: 4 })
          .margin({ bottom: 12 })

          // 实验5-1：后台自习计时（长时任务 TASK_KEEPING）卡片
          Column({ space: 12 }) {
            Row() {
              Text('⏱').fontSize(22).fontColor('#2F6BFA').margin({ right: 10 })
              Text('后台自习计时 (长时任务)')
                .fontSize(this.appFontSize - 1)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.appTheme === 'dark' ? '#FFFFFF' : '#333333')
              Blank()
              Toggle({ type: ToggleType.Switch, isOn: this.isStudying })
                .selectedColor('#2F6BFA')
                .onChange(async (isOn: boolean) => {
                  await this.onStudyToggle(isOn);
                })
            }.width('100%')

            Text('开启后即使退到后台，自习计时不中断，进程受保护')
              .fontSize(this.appFontSize - 3)
              .fontColor('#999')
              .width('100%')

            if (this.isStudying) {
              Text(this.studyElapsedText)
                .fontSize(this.appFontSize + 10)
                .fontWeight(FontWeight.Bold)
                .fontColor('#2F6BFA')
                .width('100%')
                .textAlign(TextAlign.Center)
                .margin({ top: 4, bottom: 4 })
            }

            Row({ space: 6 }) {
              Circle({ width: 8, height: 8 })
                .fill(this.isStudying ? '#16A34A' : '#9CA3AF')
              Text(this.studyStatusText)
                .fontSize(this.appFontSize - 4)
                .fontColor(this.isStudying ? '#16A34A' :
                  (this.appTheme === 'dark' ? '#AAAAAA' : '#666'))
            }.width('100%')
          }
          .padding(16)
          .backgroundColor(this.appTheme === 'dark' ? '#1E1E1E' : Color.White)
          .borderRadius(20)
          .shadow({ radius: 10, color: '#0A000000', offsetY: 4 })
          .margin({ bottom: 12 })

          // 实验5-2：倒计时提醒（代理提醒）卡片
          Column({ space: 12 }) {
            Row() {
              Text('◎').fontSize(22).fontColor('#2F6BFA').margin({ right: 10 })
              Text('倒计时提醒 (代理提醒)')
                .fontSize(this.appFontSize - 1)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.appTheme === 'dark' ? '#FFFFFF' : '#333333')
              Blank()
              Text(`${this.activeReminderCount} / 30`)
                .fontSize(this.appFontSize - 3)
                .fontColor(this.activeReminderCount > 0 ? '#2F6BFA' : '#999')
                .fontWeight(FontWeight.Bold)
            }.width('100%')

            Row({ space: 10 }) {
              TextInput({ placeholder: '秒数', text: this.reminderInput })
                .width(100)
                .height(40)
                .fontSize(this.appFontSize - 2)
                .backgroundColor(this.appTheme === 'dark' ? '#2D2D35' : '#F3F4F6')
                .borderRadius(8)
                .onChange((value: string) => {
                  this.reminderInput = value;
                  this.reminderSeconds = parseInt(value) || 60;
                })

              Button('设置提醒')
                .fontSize(this.appFontSize - 3)
                .height(40)
                .backgroundColor('#2F6BFA')
                .borderRadius(8)
                .layoutWeight(1)
                .onClick(async () => {
                  await this.onSetReminder();
                })

              Button('一键撤销')
                .fontSize(this.appFontSize - 3)
                .height(40)
                .backgroundColor(this.appTheme === 'dark' ? '#3D3D45' : '#E5E7EB')
                .fontColor(this.appTheme === 'dark' ? '#CCCCCC' : '#333')
                .borderRadius(8)
                .layoutWeight(1)
                .onClick(async () => {
                  await this.onCancelAllReminders();
                })
            }.width('100%')

            if (this.reminderFeedback) {
              Text(this.reminderFeedback)
                .fontSize(this.appFontSize - 4)
                .fontColor('#2F6BFA')
                .width('100%')
                .padding(8)
                .backgroundColor(this.appTheme === 'dark' ? '#1A2A4E' : '#EBF2FF')
                .borderRadius(6)
            }

            // 有效提醒列表
            if (this.activeReminders.length > 0) {
              Column({ space: 6 }) {
                ForEach(this.activeReminders, (item: ReminderItem) => {
                  Row() {
                    // 动态倒计时：remainingSeconds 每 tick 更新，新数组引用驱动 ForEach 刷新
                    Text(`${item.label}  剩余 ${item.remainingSeconds}s`)
                      .fontSize(this.appFontSize - 3)
                      .fontColor(this.appTheme === 'dark' ? '#CCCCCC' : '#555')
                      .layoutWeight(1)
                    Button('取消')
                      .fontSize(this.appFontSize - 5)
                      .height(26)
                      .backgroundColor('#FEE2E2')
                      .fontColor('#FA5151')
                      .borderRadius(6)
                      .onClick(async () => {
                        await this.onCancelReminder(item.id);
                      })
                  }.width('100%')
                  .padding({ top: 4, bottom: 4 })
                }, (item: ReminderItem) => `${item.id}_${item.remainingSeconds}`)
              }
              .width('100%')
              .padding(10)
              .backgroundColor(this.appTheme === 'dark' ? '#1A1A24' : '#F9FAFB')
              .borderRadius(8)
            }
          }
          .padding(16)
          .backgroundColor(this.appTheme === 'dark' ? '#1E1E1E' : Color.White)
          .borderRadius(20)
          .shadow({ radius: 10, color: '#0A000000', offsetY: 4 })
          .margin({ bottom: 12 })

          // 4. 退出登录按钮
          Button('退出当前账号')
            .width('100%')
            .height(55)
            .fontSize(this.appFontSize)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FA5151')
            .backgroundColor(this.appTheme === 'dark' ? '#311F1F' : '#FFF8F8')
            .borderRadius(20)
            .margin({ top: 10, bottom: 20 })
            .onClick(() => {
              AppStorage.set('userId', '2301130077');
              AppStorage.set('userName', '甘凯洋');

              const context = getContext(this) as common.UIAbilityContext;
              let logoutWant: Want = {
                bundleName: 'com.example.campus',
                abilityName: 'EntryAbility'
              };

              try {
                context.startAbility(logoutWant);
                context.terminateSelf();
              } catch (err) {
                console.error('退出登录能力拉起失败: ' + JSON.stringify(err));
              }
            })

          Text('校通Plus Version 4.2.0')
            .fontSize(this.appFontSize - 5)
            .fontColor('#CCC')
            .width('100%')
            .textAlign(TextAlign.Center)
            .margin({ bottom: 30 })
        }
        .width('92%')
      }
      .edgeEffect(EdgeEffect.Spring)
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.appTheme === 'dark' ? '#121212' : '#F7F8FA') // 顶层大底色联动响应
  }

  // 实验5：后台自习计时切换（长时任务 TASK_KEEPING）
  private async onStudyToggle(isOn: boolean): Promise<void> {
    this.isStudying = isOn;
    if (isOn) {
      // 记录开始时间戳，持久化到 Preferences 防止进程被杀后丢失
      this.studyStartTimestamp = Date.now();
      await this.saveStudyState(true, this.studyStartTimestamp);
      this.refreshStudyElapsed();
      // 启动每秒定时器，驱动 UI 实时刷新
      this.timerId = setInterval(() => {
        this.refreshStudyElapsed();
      }, 1000);
      const ctx = getContext(this);
      const state: ContinuousTaskState = await this.btm.startContinuousTask(ctx);
      this.studyStatusText = state.message;
    } else {
      // 停止定时器
      if (this.timerId !== -1) {
        clearInterval(this.timerId);
        this.timerId = -1;
      }
      // 停止计时，清除持久化状态，释放长时任务
      this.studyStartTimestamp = 0;
      this.studyElapsedText = '00:00';
      await this.saveStudyState(false, 0);
      const ctx = getContext(this);
      const state: ContinuousTaskState = await this.btm.stopContinuousTask(ctx);
      this.studyStatusText = '自习已结束';
    }
  }

  // 实验5：持久化自习状态到 Preferences（进程被杀后恢复用）
  private async saveStudyState(isRunning: boolean, timestamp: number): Promise<void> {
    try {
      const ctx = getContext(this) as common.UIAbilityContext;
      const pref = await dataPreferences.getPreferences(ctx.getApplicationContext(), 'AppLaunchPreferences');
      await pref.put('study_is_running', isRunning);
      await pref.put('study_start_timestamp', timestamp);
      await pref.flush();
    } catch (e) {
      console.error('自习状态持久化失败: ' + JSON.stringify(e));
    }
  }

  // 实验5：刷新自习已用时长
  private refreshStudyElapsed(): void {
    if (!this.isStudying || this.studyStartTimestamp === 0) {
      return;
    }
    const elapsed = Math.floor((Date.now() - this.studyStartTimestamp) / 1000);
    const mins = Math.floor(elapsed / 60);
    const secs = elapsed % 60;
    this.studyElapsedText = `${String(mins).padStart(2, '0')}:${String(secs).padStart(2, '0')}`;
  }

  // 实验5：设置倒计时提醒（本地实时倒计时 + 系统代理双保险）
  private async onSetReminder(): Promise<void> {
    const seconds = this.reminderSeconds;
    if (seconds <= 0) {
      this.reminderFeedback = '请设置大于 0 的秒数';
      return;
    }
    // 1. 发布系统级代理提醒（需 release 签名 + 系统权限，模拟器暂不支持）
    const result: ReminderResult = await this.btm.publishReminder(
      seconds, '校通Plus提醒', `倒计时 ${seconds} 秒已到`
    );
    const now = Date.now();
    const reminderId = result.reminderId || now;
    this.activeReminders = [...this.activeReminders, {
      id: reminderId,
      totalSeconds: seconds,
      startTimestamp: now,
      remainingSeconds: seconds,
      label: `${seconds}s 倒计时`
    }];
    this.reminderFeedback = result.message.includes('真实API') ?
      `已设置 ${seconds}s 提醒（系统级，退后台仍触发）` :
      `已设置 ${seconds}s 提醒（本地计时，仅前台弹窗）`;
    this.activeReminderCount = this.activeReminders.length;

    // 2. 启动本地实时倒计时（每秒刷新 UI）
    this.startCountdownTicker();
  }

  // 实验5：每秒刷新所有倒计时，到期弹 Toast
  private startCountdownTicker(): void {
    if (this.countdownTimerId !== -1) {
      return; // 已有定时器运行
    }
    this.countdownTimerId = setInterval(() => {
      this.tickCountdowns();
    }, 1000);
  }

  private tickCountdowns(): void {
    const now = Date.now();
    // 重新构建整个数组（新引用 → ForEach 检测到变化 → UI 刷新）
    const updated: ReminderItem[] = [];
    let expiredCount = 0;

    for (let i = 0; i < this.activeReminders.length; i++) {
      const r = this.activeReminders[i];
      const elapsed = Math.floor((now - r.startTimestamp) / 1000);
      const remaining = r.totalSeconds - elapsed;

      if (remaining <= 0) {
        // 倒计时到期 → 弹 Toast（仅 foreground 可见），取消系统提醒
        expiredCount++;
        promptAction.showToast({ message: `${r.label} 时间到！` });
        this.btm.cancelReminder(r.id);
      } else {
        // 更新剩余秒数，保留在列表中
        updated.push({
          id: r.id,
          totalSeconds: r.totalSeconds,
          startTimestamp: r.startTimestamp,
          remainingSeconds: remaining,
          label: r.label
        });
      }
    }

    // 赋新数组 → 触发 @State 变更 → ForEach 重建 UI
    this.activeReminders = updated;
    this.activeReminderCount = updated.length;

    if (updated.length === 0) {
      this.stopCountdownTicker();
    }
  }

  private stopCountdownTicker(): void {
    if (this.countdownTimerId !== -1) {
      clearInterval(this.countdownTimerId);
      this.countdownTimerId = -1;
    }
  }

  // 实验5：取消单个提醒
  private async onCancelReminder(reminderId: number): Promise<void> {
    await this.btm.cancelReminder(reminderId);
    this.activeReminders = this.activeReminders.filter(r => r.id !== reminderId);
    this.activeReminderCount = this.activeReminders.length;
    if (this.activeReminders.length === 0) {
      this.stopCountdownTicker();
    }
  }

  // 实验5：一键撤销所有提醒
  private async onCancelAllReminders(): Promise<void> {
    await this.btm.cancelAllReminders();
    this.activeReminders = [];
    this.activeReminderCount = 0;
    this.reminderFeedback = '所有提醒已撤销';
    this.stopCountdownTicker();
  }

  // 调试：重置首次启动标记
  private async resetFirstLaunchFlag() {
    const context = getContext(this) as common.Context;
    let pref = await dataPreferences.getPreferences(context, 'AppLaunchPreferences');
    await pref.put('isFirstLaunch', true);
    await pref.delete('appVersion');
    await pref.flush();
    promptAction.showToast({ message: '已重置，冷启动复现引导页' });
  }

  @Builder StatItem(num: string, label: string) {
    Column({ space: 5 }) {
      Text(num).fontSize(this.appFontSize + 6).fontWeight(FontWeight.Bold).fontColor(this.appTheme === 'dark' ? '#FFF' : '#333')
      Text(label).fontSize(this.appFontSize - 3).fontColor(this.appTheme === 'dark' ? '#AAA' : '#999')
    }.layoutWeight(1)
  }

  @Builder MenuRow(icon: Resource, title: string) {
    Row() {
      Image(icon).width(20).height(20).margin({ left: 18, right: 15 })
      Text(title).fontSize(this.appFontSize).fontColor(this.appTheme === 'dark' ? '#FFF' : '#333').fontWeight(FontWeight.Medium)
      Blank()
      Image($r('app.media.right'))
        .width(14).height(14).margin({ right: 18 }).opacity(0.3)
    }
    .width('100%')
    .height(60)
  }
}