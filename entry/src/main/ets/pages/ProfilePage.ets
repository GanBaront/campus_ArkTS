// entry/src/main/ets/pages/ProfilePage.ets
import common from '@ohos.app.ability.common';
import Want from '@ohos.app.ability.Want';
import promptAction from '@ohos.promptAction';
import { StorageManager } from '../utils/StorageManager';

@Entry
@Component
export struct ProfilePage {
  // 实时响应全局状态机的用户信息
  @StorageProp('userName') userName: string = '甘同学';
  @StorageProp('userId') userId: string = '2301130077';

  // 🛠️ 核心修复：状态统一双向绑定到 AppStorage，冷启动默认值彻底设为 'light'（浅色模式）
  @StorageLink('appTheme') appTheme: string = 'light';
  @StorageLink('appFontSize') appFontSize: number = 16;

  private storage = StorageManager.getInstance();

  // 页面生命周期：异步初始化拉取 KV Store 缓存数据并安全注入 AppStorage
  async aboutToAppear() {
    try {
      const savedTheme = await this.storage.getSetting('theme_mode', 'light');
      AppStorage.set('appTheme', savedTheme);

      const savedFontSize = await this.storage.getSetting('font_size', '16');
      AppStorage.set('appFontSize', Number(savedFontSize));
    } catch (e) {
      console.error('读取 KV Store 偏好设置失败: ' + JSON.stringify(e));
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
              AppStorage.setOrCreate('userId', '2301130077');
              AppStorage.setOrCreate('userName', '甘凯洋');

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