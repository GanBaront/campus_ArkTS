import router from '@ohos.router';

@Entry
@Component
struct StartPage {
  @State countdown: number = 3
  @State animIndex: number = 0
  private timerId: number = -1
  private animTimerId: number = -1

  onPageShow() {
    this.startTimer();
    this.startLoadingAnimation();
  }

  onPageHide() {
    this.stopTimer();
    this.stopLoadingAnimation();
  }

  startTimer() {
    this.timerId = setInterval(() => {
      this.countdown--;
      if (this.countdown <= 0) {
        this.jumpToNext();
      }
    }, 1000);
  }

  startLoadingAnimation() {
    this.animTimerId = setInterval(() => {
      this.animIndex = (this.animIndex + 1) % 3;
    }, 400);
  }

  stopTimer() {
    if (this.timerId !== -1) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
  }

  stopLoadingAnimation() {
    if (this.animTimerId !== -1) {
      clearInterval(this.animTimerId);
      this.animTimerId = -1;
    }
  }

  jumpToNext() {
    this.stopTimer();
    this.stopLoadingAnimation();

    let options: router.RouterOptions = {
      url: 'pages/Onboarding',
      params: { source: 'StartPage' }
    };
    try {
      router.pushUrl(options);
    } catch (err) {
      console.error(`跳转失败: ${err.message}`);
    }
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      // 品牌 Logo 区
      Column({ space: 15 }) {
        Image($r('app.media.hat'))
          .width(120)
          .height(120)
          .borderRadius(30)

        Text('校通Plus')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333')

        Text('智慧校园 · 悦享生活')
          .fontSize(16)
          .fontColor('#999')
          .letterSpacing(2)
      }
      .justifyContent(FlexAlign.Center)
      .width('100%')
      .height('100%')

      // 右上角跳过
      Column() {
        Text(`跳过 ${this.countdown}s`)
          .fontSize(12)
          .fontColor(Color.White)
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .backgroundColor('#40000000')
          .borderRadius(15)
          .margin({ top: 40, right: 20 })
          .onClick(() => this.jumpToNext())
      }
      .width('100%')
      .alignItems(HorizontalAlign.End)

      // 底部跳动加载动画
      Column({ space: 25 }) {
        Row({ space: 10 }) {
          ForEach([0, 1, 2], (item: number) => {
            Circle()
              .width(8)
              .height(8)
              .fill(this.animIndex === item ? '#005DFF' : '#D8D8D8')
              .offset({ y: this.animIndex === item ? -10 : 0 })
              .animation({
                duration: 300,
                curve: Curve.EaseInOut
              })
          })
        }

        Text('VER 2026.04.01')
          .fontSize(12)
          .fontColor('#CCC')
          .margin({ bottom: 50 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}