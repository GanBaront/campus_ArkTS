// entry/src/main/ets/pages/InteractionPage.ets
@Component
export struct InteractionPage {
  @StorageLink('appTheme') appTheme: string = 'light';
  @StorageLink('appFontSize') appFontSize: number = 17;
  private tags: string[] = ['#2026招生信息#', '#毕业设计课题#', '#食堂新品采样#'];

  build() {
    Column() {
      // 1. 顶部标题栏
      Row() {
        Text('互动社区').fontSize(this.appFontSize + 4).fontWeight(FontWeight.Bold)
        Blank()
        Row({ space: 15 }) {
          Image($r('app.media.search')).width(22).height(22).fillColor(this.appTheme === 'dark' ? '#FFF' : '#333')
          Image($r('app.media.edit')).width(22).height(22)
        }
      }.width('100%').padding(16)

      // 2. 导航 Tab
      Row({ space: 25 }) {
        this.SubTab('推荐', true)
        this.SubTab('组队', false)
        this.SubTab('匿名树洞', false)
        this.SubTab('社团', false)
      }.width('100%').padding({ left: 16, bottom: 10 })

      Scroll() {
        Column({ space: 12 }) {
          // 3. 话题标签
          Row({ space: 8 }) {
            ForEach(this.tags, (tag: string) => {
              Text(tag).fontSize(this.appFontSize - 4).fontColor('#2F6BFA').padding({ left: 10, right: 10, top: 6, bottom: 6 })
                .backgroundColor('#EBF2FF').borderRadius(15)
            }, (tag: string) => tag)
          }.width('100%').padding({ left: 16 })

          // 4. 活动卡片复刻 (机器人协会)
          this.EventCard()

          // 5. 普通吐槽帖
          this.NormalPost()

          // 6. 底部组队招募
          this.TeamSection()
        }.padding({ bottom: 20 })
      }.layoutWeight(1).edgeEffect(EdgeEffect.Spring)
    }
    .width('100%').height('100%')
    .backgroundColor(this.appTheme === 'dark' ? '#121216' : '#F7F8FA')
  }

  @Builder SubTab(title: string, isActive: boolean) {
    Column({ space: 4 }) {
      Text(title).fontSize(this.appFontSize).fontColor(isActive ? '#2F6BFA' : '#999').fontWeight(isActive ? FontWeight.Bold : FontWeight.Normal)
      if (isActive) Rect().width(20).height(3).fill('#2F6BFA').borderRadius(2)
    }
  }

  @Builder EventCard() {
    Column({ space: 10 }) {
      Row({ space: 10 }) {
        Image($r('app.media.avatar_club')).width(40).height(40).borderRadius(20)
        Column() {
          Text('机器人协会 小王').fontSize(this.appFontSize - 2).fontWeight(FontWeight.Bold)
          Text('来自【社团展示】').fontSize(11).fontColor('#999')
        }.alignItems(HorizontalAlign.Start)
      }.width('100%')

      Text('下周三下午在信教302有无人机飞行演示活动，欢迎各位对机器人感兴趣的同学参加！名额有限，点击下方卡片预约~')
        .fontSize(this.appFontSize - 1).lineHeight(22)

      // 活动预约小卡片
      Row() {
        Column() {
          Text('APR').fontSize(10).fontColor('#FFF')
          Text('08').fontSize(18).fontWeight(FontWeight.Bold).fontColor('#FFF')
        }.backgroundColor('#2F6BFA').padding(8).borderRadius(8).margin({ right: 12 })

        Column() {
          Text('无人机操作入门讲座').fontSize(this.appFontSize - 2).fontWeight(FontWeight.Bold)
          Text('已有 45 人报名 / 限 60 人').fontSize(11).fontColor('#999')
        }.alignItems(HorizontalAlign.Start).layoutWeight(1)

        Button('预约').fontSize(12).height(30).width(60).backgroundColor('#2F6BFA')
      }
      .backgroundColor(this.appTheme === 'dark' ? '#2D2D35' : '#F3F4F6').padding(12).borderRadius(12).width('100%')

      this.PostActions('128', '34')
    }.cardStyle(this.appTheme)
  }

  @Builder NormalPost() {
    Column({ space: 10 }) {
      Row({ space: 10 }) {
        Image($r('app.media.avatar_user')).width(40).height(40).borderRadius(20)
        Text('匿名用户').fontSize(this.appFontSize - 2).fontWeight(FontWeight.Bold)
      }.width('100%')
      Text('真的很想吐槽一下，图书馆某些同学占座真的太夸张了，一占就是一天，人都不见，希望能管管。')
        .fontSize(this.appFontSize - 1).lineHeight(22)
      this.PostActions('562', '89')
    }.cardStyle(this.appTheme)
  }

  @Builder TeamSection() {
    Column({ space: 10 }) {
      Text('组队招募中').fontSize(this.appFontSize - 1).fontWeight(FontWeight.Bold).width('100%')
      Row({ space: 15 }) {
        this.TeamItem('考研', '#FF823A')
        this.TeamItem('球友', '#2F6BFA')
        this.TeamItem('竞赛', '#16A34A')
      }
    }.cardStyle(this.appTheme)
  }

  @Builder TeamItem(name: string, col: string) {
    Column({ space: 5 }) {
      Circle({ width: 45, height: 45 }).fill(col).opacity(0.1)
      Text(name).fontSize(12)
    }
  }

  @Builder PostActions(like: string, comment: string) {
    Row({ space: 20 }) {
      Row({ space: 5 }) { Image($r('app.media.like')).width(16).height(16); Text(like).fontSize(12).fontColor('#999') }
      Row({ space: 5 }) { Image($r('app.media.comment')).width(16).height(16); Text(comment).fontSize(12).fontColor('#999') }
      Image($r('app.media.share')).width(16).height(16)
    }.width('100%').margin({ top: 5 })
  }
}

@Extend(Column) function cardStyle(theme: string) {
  .width('92%').padding(16).borderRadius(16).margin({ top: 12, left: '4%', right: '4%' })
  .backgroundColor(theme === 'dark' ? '#1E1E24' : '#FFF')
  .shadow({ radius: 8, color: '#05000000', offsetY: 2 })
}