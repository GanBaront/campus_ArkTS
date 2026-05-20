import common from '@ohos.app.ability.common';
import Want from '@ohos.app.ability.Want';

@Entry
@Component
export struct ProfilePage {
  // 实时响应全局状态机的用户信息
  @StorageProp('userName') userName: string = '甘同学';
  @StorageProp('userId') userId: string = '2301130077';

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
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 15 })
        Blank()
      }
      .width('100%')
      .height(56)
      .padding({ left: 20, right: 20 })
      .backgroundColor(Color.White)

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
              .border({ width: 2, color: Color.White })

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
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1A1A1A')

          Text('软件工程 · 2023级')
            .fontSize(14)
            .fontColor('#999')

          Row() {
            Image($r('app.media.id')).width(14).height(14).margin({ right: 6 })
            Text(`学号：${this.userId}`)
              .fontSize(12)
              .fontColor('#005DFF')
              .fontWeight(FontWeight.Medium)
          }
          .backgroundColor('#EBF2FF')
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
          Column() {
            this.MenuRow($r('app.media.user'), '学籍卡包')
            Divider().margin({ left: 50, right: 15 }).color('#F7F8FA')
            this.MenuRow($r('app.media.calendar'), '2026春季校历')
            Divider().margin({ left: 50, right: 15 }).color('#F7F8FA')
            this.MenuRow($r('app.media.report'), '我的成绩单')
          }
          .backgroundColor(Color.White)
          .borderRadius(20)
          .shadow({ radius: 10, color: '#0A000000', offsetY: 4 })

          Column() {
            this.MenuRow($r('app.media.privacy'), '隐私与安全')
            Divider().margin({ left: 50, right: 15 }).color('#F7F8FA')
            this.MenuRow($r('app.media.help'), '帮助与反馈')
            Divider().margin({ left: 50, right: 15 }).color('#F7F8FA')
            this.MenuRow($r('app.media.setting'), '通用设置')
          }
          .backgroundColor(Color.White)
          .borderRadius(20)
          .shadow({ radius: 10, color: '#0A000000', offsetY: 4 })

          // 4. 退出登录按钮
          Button('退出当前账号')
            .width('100%')
            .height(55)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FA5151')
            .backgroundColor('#FFF8F8')
            .borderRadius(20)
            .margin({ top: 10, bottom: 20 })
            .onClick(() => {
              // 【安全升级】：清除状态机里的痕迹，回滚至初始未登录状态
              AppStorage.setOrCreate('userId', '2301130077');
              AppStorage.setOrCreate('userName', '甘凯洋');

              const context = getContext(this) as common.UIAbilityContext;
              let logoutWant: Want = {
                bundleName: 'com.example.campus', // 【核心Bug修复】：修正为应用当前的实际包名
                abilityName: 'EntryAbility'
              };

              try {
                context.startAbility(logoutWant);
                context.terminateSelf(); // 成功返回登录向导流后销毁大厅
              } catch (err) {
                console.error('退出登录能力拉起失败: ' + JSON.stringify(err));
              }
            })

          Text('校通Plus Version 4.2.0')
            .fontSize(11)
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
    .backgroundColor('#F7F8FA')
  }

  @Builder StatItem(num: string, label: string) {
    Column({ space: 5 }) {
      Text(num).fontSize(22).fontWeight(FontWeight.Bold).fontColor('#333')
      Text(label).fontSize(13).fontColor('#999')
    }.layoutWeight(1)
  }

  @Builder MenuRow(icon: Resource, title: string) {
    Row() {
      Image(icon).width(20).height(20).margin({ left: 18, right: 15 })
      Text(title).fontSize(16).fontColor('#333').fontWeight(FontWeight.Medium)
      Blank()
      Image($r('app.media.right'))
        .width(14).height(14).margin({ right: 18 }).opacity(0.3)
    }
    .width('100%')
    .height(60)
  }
}