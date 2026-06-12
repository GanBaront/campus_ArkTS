/**
 * Onboarding — 首次启动引导页
 * ============================
 * 三页轮播介绍 → 点击"立即开启"或"跳过介绍" → 跳转 LoginPage。
 * 仅在首次启动或 App 版本更新后展示一次。
 */
import router from '@ohos.router';

@Entry
@Component
struct Onboarding {
  // 1. 定义状态和控制器
  @State currentIndex: number = 0
  private swiperController: SwiperController = new SwiperController()
  private totalPages: number = 3

  // 2. 新增：接收来自 StartPage 的业务参数
  private params = router.getParams() as Record<string, string>;
  @State sourceTag: string = this.params?.source || '未知来源';
  @State appVersion: string = this.params?.version || 'v1.0.0';

  build() {
    Column() {
      // 3. 顶部业务参数显示区 (实验要求：并在目标页面接收显示)
      Row() {
        Text(`来源: ${this.sourceTag} | 版本: ${this.appVersion}`)
          .fontSize(10)
          .fontColor('#CCC')
          .margin({ top: 10, left: 20 })
      }.width('100%').justifyContent(FlexAlign.Start)

      // 4. 轮播内容区
      Swiper(this.swiperController) {
        // 第一页：实际内容
        Column({ space: 20 }) {
          Stack() {
            Circle().width(240).height(240).fill('#F0F5FF')
            Image($r('app.media.book')) // 书本位置
              .width(120).height(120)
          }
          .margin({ top: 80 })

          Text('学在云端')
            .fontSize(26)
            .fontWeight(FontWeight.Bold)
            .margin({ top: 40 })

          Text('课表管理、成绩查询、空教室预约，你的学习生活助手。')
            .fontSize(16)
            .fontColor('#666')
            .textAlign(TextAlign.Center)
            .padding({ left: 40, right: 40 })
            .lineHeight(24)
        }
        .width('100%')

        // 第二页
        this.ComingSoonPage('互动社区', '分享校园生活，结交志同道合的小伙伴。')

        // 第三页
        this.ComingSoonPage('智慧生活', '校车查询、食堂充值，一表在手，校园无忧。')
      }
      .layoutWeight(1)
      .loop(false)
      .indicator(false)
      .onChange((index: number) => {
        this.currentIndex = index
      })

      // 5. 底部操作与联动区
      Column({ space: 25 }) {
        // 自定义指示器 (三个点)
        Row({ space: 10 }) {
          ForEach([0, 1, 2], (index: number) => {
            Circle()
              .width(index === this.currentIndex ? 20 : 8)
              .height(8)
              .fill(index === this.currentIndex ? '#005DFF' : '#D8D8D8')
              .borderRadius(4)
              .animation({ duration: 300, curve: Curve.LinearOutSlowIn })
          })
        }

        // 下一步 / 立即开启按钮
        Button(this.currentIndex === this.totalPages - 1 ? '立即开启' : '下一步 →')
          .width('85%')
          .height(50)
          .backgroundColor('#2F6BFF')
          .borderRadius(25)
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .onClick(() => {
            if (this.currentIndex < this.totalPages - 1) {
              // 点击跳转下一页
              this.currentIndex++
              this.swiperController.showNext()
            } else {
              // 业务逻辑：跳转到登录页并传递“首次打开”参数
              this.jumpToLogin('Finish_Onboarding')
            }
          })

        // 跳过介绍：直接跳转到登录
        Text('跳过介绍')
          .fontSize(14)
          .fontColor('#999')
          .margin({ bottom: 40 })
          .onClick(() => {
            this.jumpToLogin('Skip_Onboarding')
          })
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  // 封装跳转逻辑
  jumpToLogin(entryPoint: string) {
    router.pushUrl({
      url: 'pages/LoginPage', // 对应你项目真实的登录页路径
      params: {
        entry: entryPoint,
        isFirstLaunch: true
      }
    })
  }

  // 改进的构建函数，支持传入文案
  @Builder ComingSoonPage(title: string, desc: string) {
    Column({ space: 20 }) {
      Text(title)
        .fontSize(26)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 220 }) // 保持与第一页位置大致对齐

      Text(desc)
        .fontSize(16)
        .fontColor('#999')
        .textAlign(TextAlign.Center)
        .padding({ left: 40, right: 40 })
        .lineHeight(24)
    }
    .width('100%')
    .height('100%')
  }
}