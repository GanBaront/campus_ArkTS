// entry/src/main/ets/pages/Index.ets
import promptAction from '@ohos.promptAction';
import common from '@ohos.app.ability.common';
import dataPreferences from '@ohos.data.preferences';
import { StorageManager, ScheduleItem } from '../utils/StorageManager';
import { ProfilePage } from './ProfilePage';

@Entry
@Component
struct Index {
  @State currentIndex: number = 0; // 默认选中第 1 个 Tab（工作台）

  // Preferences 状态响应
  @State isFirstTime: boolean = false;

  // RelationalStore 复杂关系型列表状态响应
  @State scheduleList: Array<ScheduleItem> = [];

  // 临时表单状态数据
  @State newTitle: string = '';
  @State newContent: string = '';

  // 🛠️ 深度绑定：双向全局状态机，拉动滑块或切换单选框时，全项目关联组件毫秒级重绘
  @StorageLink('appTheme') appTheme: string = 'light';       // 'light' 浅色 / 'dark' 深色
  @StorageLink('appFontSize') appFontSize: number = 16;       // 14 ~ 24 像素范围

  async aboutToAppear() {
    // 1. 拦截盘查 Preferences 首次启动状态
    this.isFirstTime = await StorageManager.getInstance().checkIsFirstLaunch();
    if (this.isFirstTime) {
      this.showWelcomeDialog();
    }

    // 2. 将 Key 严格对齐为课程报告要求的 'theme_mode' 和 'font_size' 字段 [cite: 36, 46]
    const savedTheme = await StorageManager.getInstance().getSetting('theme_mode', 'light');
    AppStorage.setOrCreate('appTheme', savedTheme);

    const savedFontSize = await StorageManager.getInstance().getSetting('font_size', '16');
    AppStorage.setOrCreate('appFontSize', Number(savedFontSize));

    // 3. 从 RelationalStore 读取数据库离线日程单列表
    await this.refreshSchedules();
  }

  // 刷新日程列表数据
  async refreshSchedules() {
    this.scheduleList = await StorageManager.getInstance().queryAllSchedules();
  }

  // 首次进入欢迎弹窗 [cite: 25, 41]
  showWelcomeDialog() {
    promptAction.showDialog({
      title: '欢迎使用',
      message: '感谢您首次开启智能小助手！我们将使用结构化 RelationalStore 数据库为您守护每一项核心数据安全。',
      buttons: [{ text: '进入应用', color: '#2F6BFA' }]
    }).then(async () => {
      await StorageManager.getInstance().disableFirstLaunchFlag();
      this.isFirstTime = false;
    })
  }

  // 切换主题模式 (KV Store) [cite: 26]
  async toggleTheme() {
    this.appTheme = this.appTheme === 'light' ? 'dark' : 'light';
    await StorageManager.getInstance().putSetting('theme_mode', this.appTheme);
  }

  // 切换字号 (KV Store) [cite: 26]
  async toggleFontSize() {
    this.appFontSize = this.appFontSize === 16 ? 20 : 16;
    await StorageManager.getInstance().putSetting('font_size', this.appFontSize.toString());
  }

  // 新增日程插入到数据库 (RelationalStore) [cite: 29]
  async addSchedule() {
    if (!this.newTitle.trim()) {
      promptAction.showToast({ message: '请输入日程标题' });
      return;
    }

    let now = new Date();
    let timeStr = `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}`;

    let item: ScheduleItem = {
      title: this.newTitle,
      time: timeStr,
      content: this.newContent
    };

    await StorageManager.getInstance().insertSchedule(item);
    promptAction.showToast({ message: '成功写入关系型数据库' });

    this.newTitle = '';
    this.newContent = '';
    await this.refreshSchedules();
  }

  // 从数据库中抹除某条日程 (RelationalStore) [cite: 29]
  async deleteSchedule(id: number) {
    await StorageManager.getInstance().deleteScheduleById(id);
    promptAction.showToast({ message: '已从数据库中安全擦除' });
    await this.refreshSchedules();
  }

  build() {
    // 🛠️ 容器层：外层包裹 Column 确保大底座完全统一，拒绝任何系统边框带来的漏光
    Column() {
      Tabs({ barPosition: BarPosition.End, index: this.currentIndex }) {

        // ===== TAB 1: 综合数据工作台 =====
        TabContent() {
          Column() {
            // 顶通标题导航栏
            Row() {
              Text('综合数据工作台')
                .fontSize(this.appFontSize + 2)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.appTheme === 'dark' ? '#FFFFFF' : '#1F2937')
            }
            .width('100%')
            .padding(16)
            .backgroundColor(this.appTheme === 'dark' ? '#1E1E24' : '#FFFFFF')
            .shadow({ radius: 2, color: '#10000000', offsetY: 1 })

            Scroll() {
              Column({ space: 16 }) {
                // 偏好设置仓 (KV Store 驱动) [cite: 26]
                Column({ space: 12 }) {
                  Text('偏好设置舱 (KV Store)')
                    .fontSize(this.appFontSize - 3)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#2F6BFA')
                    .width('100%')

                  Row() {
                    Text(`当前主题模式: ${this.appTheme === 'dark' ? '深色' : '浅色'}`)
                      .fontSize(this.appFontSize - 2)
                      .fontColor(this.appTheme === 'dark' ? '#E5E7EB' : '#374151')
                    Blank()
                    Button('切换')
                      .fontSize(this.appFontSize - 4)
                      .height(28)
                      .onClick(() => this.toggleTheme())
                  }.width('100%')

                  Row() {
                    Text(`全局字体大小: ${this.appFontSize === 20 ? '放大' : '标准'} (${this.appFontSize}px)`)
                      .fontSize(this.appFontSize - 2)
                      .fontColor(this.appTheme === 'dark' ? '#E5E7EB' : '#374151')
                    Blank()
                    Button('微调')
                      .fontSize(this.appFontSize - 4)
                      .height(28)
                      .backgroundColor('#16A34A')
                      .onClick(() => this.toggleFontSize())
                  }.width('100%')
                }
                .padding(14)
                .borderRadius(12)
                .backgroundColor(this.appTheme === 'dark' ? '#2D2D35' : '#FFFFFF')

                // 数据表单录入区 (RelationalStore 写入端) [cite: 29]
                Column({ space: 10 }) {
                  Text('新建日程数据 (RelationalStore 写入)')
                    .fontSize(this.appFontSize - 3)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#F59E0B')
                    .width('100%')

                  TextInput({ text: this.newTitle, placeholder: '输入日程事项标题...' })
                    .placeholderColor('#9CA3AF')
                    .fontColor(this.appTheme === 'dark' ? '#FFFFFF' : '#000000')
                    .backgroundColor(this.appTheme === 'dark' ? '#3E3E4A' : '#F3F4F6')
                    .onChange((val) => this.newTitle = val)

                  TextArea({ text: this.newContent, placeholder: '补充备注细节描述（可选）...' })
                    .placeholderColor('#9CA3AF')
                    .fontColor(this.appTheme === 'dark' ? '#FFFFFF' : '#000000')
                    .backgroundColor(this.appTheme === 'dark' ? '#3E3E4A' : '#F3F4F6')
                    .height(70)
                    .onChange((val) => this.newContent = val)

                  Button('将本条记录提交通道落盘')
                    .width('100%')
                    .height(38)
                    .fontSize(this.appFontSize - 2)
                    .backgroundColor('#2F6BFA')
                    .onClick(() => this.addSchedule())
                }
                .padding(14)
                .borderRadius(12)
                .backgroundColor(this.appTheme === 'dark' ? '#2D2D35' : '#FFFFFF')

                // 数据视图呈现展示区 [cite: 36]
                Column({ space: 8 }) {
                  Text(`动态数据沙箱队列 (共 ${this.scheduleList.length} 条)`)
                    .fontSize(this.appFontSize - 3)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#10B981')
                    .width('100%')

                  if (this.scheduleList.length === 0) {
                    Text('目前关系型数据库表中无任何数据记录')
                      .fontSize(this.appFontSize - 3)
                      .fontColor('#9CA3AF')
                      .margin({ top: 16, bottom: 16 })
                  } else {
                    ForEach(this.scheduleList, (item: ScheduleItem) => {
                      Row() {
                        Column({ space: 4 }) {
                          Row({ space: 6 }) {
                            Text(`[${item.time}]`).fontSize(this.appFontSize - 3).fontColor('#9CA3AF')
                            Text(item.title)
                              .fontSize(this.appFontSize - 1)
                              .fontWeight(FontWeight.Bold)
                              .fontColor(this.appTheme === 'dark' ? '#FFFFFF' : '#1F2937')
                          }
                          if (item.content) {
                            Text(item.content)
                              .fontSize(this.appFontSize - 3)
                              .fontColor(this.appTheme === 'dark' ? '#9CA3AF' : '#6B7280')
                          }
                        }.alignItems(HorizontalAlign.Start).layoutWeight(1)

                        Button('删除')
                          .fontSize(this.appFontSize - 5)
                          .height(24)
                          .backgroundColor('#EF4444')
                          .onClick(() => this.deleteSchedule(item.id!))
                      }
                      .width('100%')
                      .padding(10)
                      .borderRadius(8)
                      .backgroundColor(this.appTheme === 'dark' ? '#3E3E4A' : '#F9FAFB')
                    }, (item: ScheduleItem) => item.id!.toString())
                  }
                }
                .padding(14)
                .borderRadius(12)
                .backgroundColor(this.appTheme === 'dark' ? '#2D2D35' : '#FFFFFF')

                // 调试工具
                Button('重置首次启动状态标记(调试用)')
                  .fontSize(this.appFontSize - 4)
                  .backgroundColor('#6B7280')
                  .width('100%')
                  .onClick(async () => {
                    const context = getContext(this) as common.Context;
                    let pref = await dataPreferences.getPreferences(context, 'AppLaunchPreferences');
                    await pref.put('is_first_launch', true);
                    await pref.flush();
                    this.isFirstTime = true;
                    promptAction.showToast({ message: '已重置 Preferences 标记，请冷启动复现弹窗' });
                  })
              }
              .padding(12)
            }
            .layoutWeight(1)
          }
          .width('100%')
          .height('100%')
          .backgroundColor(this.appTheme === 'dark' ? '#121216' : '#F3F4F6')
        }
        .tabBar(this.TabBuilder('工作台', 0))

        // ===== TAB 2, 3, 4: 实验分区占位 =====
        TabContent() {
          Column().width('100%').height('100%').backgroundColor(this.appTheme === 'dark' ? '#121216' : '#F3F4F6')
        }.tabBar(this.TabBuilder('学习', 1))

        TabContent() {
          Column().width('100%').height('100%').backgroundColor(this.appTheme === 'dark' ? '#121216' : '#F3F4F6')
        }.tabBar(this.TabBuilder('互动', 2))

        TabContent() {
          Column().width('100%').height('100%').backgroundColor(this.appTheme === 'dark' ? '#121216' : '#F3F4F6')
        }.tabBar(this.TabBuilder('集市', 3))

        // ===== TAB 5: 完美对接个人中心 =====
        TabContent() {
          ProfilePage()
        }
        .tabBar(this.TabBuilder('我的', 4))
      }
      .onChange((index: number) => {
        this.currentIndex = index;
      })
      .width('100%')
      .layoutWeight(1)
      .scrollable(false) // 🛠️ 优化 1：关闭手势滑动交互，防止把底色顶坏
      .barHeight(60)     // 🛠️ 优化 2：小幅拉高导航栏，适配全面屏安全高度
      .barBackgroundColor(this.appTheme === 'dark' ? '#1E1E24' : Color.White) // 🛠️ 状态栏容器底色
      // 🛠️ 优化 3：重磅配置！强制下沉渲染，使 Tab 的背景直接蔓延吞掉系统虚拟按键的白底
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.appTheme === 'dark' ? '#1E1E24' : Color.White) // 🛠️ 外部大底座全屏对齐
  }

  // 状态栏组件构造器
  @Builder TabBuilder(title: string, targetIndex: number) {
    Column() {
      Column()
        .width(22)
        .height(22)
        .backgroundColor(this.currentIndex === targetIndex ? '#2F6BFA' : (this.appTheme === 'dark' ? '#555566' : '#9CA3AF'))
        .borderRadius(5)
        .margin({ bottom: 4 })

      Text(title)
        .fontSize(this.appFontSize - 4)
        .fontColor(this.currentIndex === targetIndex ? '#2F6BFA' : (this.appTheme === 'dark' ? '#888888' : '#666666'))
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor(this.appTheme === 'dark' ? '#1E1E24' : Color.White)
  }
}