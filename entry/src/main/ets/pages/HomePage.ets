import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import Want from '@ohos.app.ability.Want';
import { ProfilePage } from './ProfilePage';

// 【核心修改】：引入你单独编写的学习模块组件
import { StudyAssistantView } from './StudyAssistantPage';

// 定义首页菜单的数据接口
interface MenuDataItem {
  name: string;
  icon: Resource;
  color: string;
}

@Entry
@Component
struct MainEntry {
  // 默认加载第一个标签：首页
  @State currentIndex: number = 0
  private tabsController: TabsController = new TabsController()

  // 提供路由栈给所有子组件，支持 Navigation 内部导航
  @Provide('pageStack') pageStack: NavPathStack = new NavPathStack()

  /**
   * 自定义底部 Tab 构建器
   */
  @Builder TabBuilder(title: string, index: number, icon: Resource) {
    Column() {
      Image(icon)
        .width(24)
        .height(24)
        .margin({ bottom: 4 })
        .fillColor(this.currentIndex === index ? '#005DFF' : '#999')
        .objectFit(ImageFit.Contain)
      Text(title)
        .fontSize(10)
        .fontColor(this.currentIndex === index ? '#005DFF' : '#999')
    }
    .width('100%')
    .height(56)
    .justifyContent(FlexAlign.Center)
  }

  build() {
    Navigation(this.pageStack) {
      Column() {
        Tabs({
          barPosition: BarPosition.End,
          controller: this.tabsController,
          index: this.currentIndex
        }) {
          // 0. 首页内容区
          TabContent() {
            HomePageView({ pageStack: this.pageStack })
          }
          .tabBar(this.TabBuilder('首页', 0, $r('app.media.home')))

          // 1. 学习区 —— 【核心修改】：直接挂载独立出来的学习助手模块组件
          TabContent() {
            StudyAssistantView()
          }
          .tabBar(this.TabBuilder('学习', 1, $r('app.media.book')))

          // 2. 互动区
          TabContent() { this.PlaceholderView('校园互动即将来临...') }
          .tabBar(this.TabBuilder('互动', 2, $r('app.media.chat')))

          // 3. 集市区
          TabContent() { this.PlaceholderView('校园集市筹备中...') }
          .tabBar(this.TabBuilder('集市', 3, $r('app.media.shop')))

          // 4. 我的（直接复用 ProfilePage 组件展示简略信息）
          TabContent() { ProfilePage() }
          .tabBar(this.TabBuilder('我的', 4, $r('app.media.user')))
        }
        .width('100%')
        .height('100%')
        .barHeight(60)
        .onChange((index: number) => {
          this.currentIndex = index
        })
      }
      .width('100%')
      .height('100%')
    }
    .hideTitleBar(true)
    .mode(NavigationMode.Stack)
  }

  @Builder PlaceholderView(text: string) {
    Column() {
      Image($r('app.media.more')).width(64).height(64).opacity(0.1).margin({ bottom: 10 })
      Text(text).fontSize(16).fontColor('#CCC')
    }
    .width('100%').height('100%').justifyContent(FlexAlign.Center)
  }
}

/**
 * 首页主视图组件
 */
@Component
struct HomePageView {
  @Prop pageStack: NavPathStack;

  // 消费来自 MainAbility 或 StartAbility 的全局状态
  @StorageProp('userName') userName: string = '甘同学';
  @StorageProp('userId') userId: string = '2301130077';

  // 动态日期显示状态
  @State currentDayString: string = ''

  // 首页功能金刚区数据
  private menuData: MenuDataItem[] = [
    { name: '我的课表', icon: $r('app.media.calendar'), color: '#E8F0FF' },
    { name: '食堂人流', icon: $r('app.media.food'), color: '#E8F5E9' },
    { name: '空教室', icon: $r('app.media.room'), color: '#FFF3E0' },
    { name: '校园集市', icon: $r('app.media.shop'), color: '#F3E5F5' },
    { name: '校园卡', icon: $r('app.media.id'), color: '#E8EAF6' },
    { name: '成绩查询', icon: $r('app.media.report'), color: '#FFEBEE' },
    { name: '社团招新', icon: $r('app.media.group'), color: '#E0F2F1' },
    { name: '更多服务', icon: $r('app.media.more'), color: '#F5F5F5' },
  ]

  // 组件即将出现时，动态计算当前系统的真实日期
  aboutToAppear() {
    this.updateCurrentDate()
  }

  private updateCurrentDate() {
    const today = new Date()
    const year = today.getFullYear()
    const month = today.getMonth() + 1 // 月份从 0 开始计数，需要加 1
    const date = today.getDate()

    // 映射星期文案
    const weekDays = ['星期日', '星期一', '星期二', '星期三', '星期四', '星期五', '星期六']
    const dayOfWeek = weekDays[today.getDay()]

    // 拼接最终的动态日期格式
    this.currentDayString = `${year}年${month}月${date}日 ${dayOfWeek}`
  }

  build() {
    Scroll() {
      Column() {
        // 1. 顶部状态栏与用户信息
        Row() {
          Column() {
            Text(this.currentDayString).fontSize(14).fontColor('#999')
            Text(`你好，${this.userName}`)
              .fontSize(24).fontWeight(FontWeight.Bold).margin({ top: 6 })
          }.alignItems(HorizontalAlign.Start)

          Blank()

          // 点击“铃铛”图标，触发跨 Ability 跳转到个人中心
          Image($r('app.media.notification'))
            .width(28).height(28)
            .onClick(() => {
              const context = getContext(this) as common.UIAbilityContext;
              let want: Want = {
                bundleName: 'com.example.campus',
                abilityName: 'ProfileAbility',
                parameters: {
                  userId: this.userId,
                  userName: this.userName
                }
              };
              try {
                context.startAbility(want);
              } catch (err) {
                console.error('主页通知拉起 ProfileAbility 失败: ' + JSON.stringify(err));
              }
            })
        }
        .width('92%').margin({ top: 20, bottom: 20 })

        // 2. 校园搜索
        Search({ placeholder: '搜索课程、讲座或校园动态...' })
          .width('92%').height(46).backgroundColor('#F2F2F2').margin({ bottom: 20 })

        // 3. 动态 Banner
        Stack({ alignContent: Alignment.BottomStart }) {
          Image($r('app.media.banner1'))
            .width('100%').height(180).borderRadius(12).objectFit(ImageFit.Cover)

          Column() {
            Text('2026春季学术周启幕').fontSize(18).fontWeight(FontWeight.Bold).fontColor(Color.White)
            Text('前沿科技讲座预约已开启').fontSize(12).fontColor(Color.White).margin({ top: 4 })
          }
          .width('100%').alignItems(HorizontalAlign.Start).padding(15)
          .backgroundBlurStyle(BlurStyle.Thin).borderRadius({ bottomLeft: 12, bottomRight: 12 })
        }
        .width('92%').margin({ bottom: 20 })

        // 4. 金刚区网格
        Grid() {
          ForEach(this.menuData, (item: MenuDataItem) => {
            GridItem() {
              Column({ space: 8 }) {
                Stack() {
                  Rect({ width: 54, height: 54 }).fill(item.color).radius(12)
                  Image(item.icon).width(28).height(28).objectFit(ImageFit.Contain)
                }
                Text(item.name).fontSize(13).fontColor('#333')
              }
            }
          })
        }
        .columnsTemplate('1fr 1fr 1fr 1fr')
        .rowsTemplate('1fr 1fr')
        .height(180).width('94%').margin({ bottom: 10 })

        // 5. 今日课表卡片
        Column() {
          Row() {
            Text('今日课程 (2)').fontSize(18).fontWeight(FontWeight.Bold)
            Blank()
            Text('完整课表 >').fontSize(13).fontColor('#005DFF')
          }.width('92%').margin({ bottom: 15, top: 10 })

          this.CourseCard('10:00', '11:35', '高级人工智能', '信教 302 (数字多媒体教室)', '必修', '#EBF2FF', '#005DFF')
          this.CourseCard('14:00', '15:35', '创业管理学', '公教楼 508', '选修', '#F0F9F4', '#4CAF50')
        }
        .width('100%').margin({ bottom: 20 })
      }
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
  }

  /**
   * 课程卡片组件
   */
  @Builder CourseCard(start: string, end: string, name: string, loc: string, tag: string, tagBg: string, tagColor: string) {
    Row() {
      Column() {
        Text(start).fontSize(15).fontWeight(FontWeight.Medium)
        Text(end).fontSize(12).fontColor('#CCC').margin({ top: 2 })
      }.width('20%')

      Column({ space: 8 }) {
        Row() {
          Text(name).fontSize(17).fontWeight(FontWeight.Bold).layoutWeight(1)
          Text(tag).fontSize(11).fontColor(tagColor).backgroundColor(tagBg)
            .padding({ left: 8, right: 8, top: 2, bottom: 2 }).borderRadius(10)
        }.width('100%')

        Row() {
          Image($r('app.media.location')).width(12).height(12).margin({ right: 5 }).opacity(0.4)
          Text(loc).fontSize(13).fontColor('#666').maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
        }.width('100%')
      }.alignItems(HorizontalAlign.Start).layoutWeight(1).padding({ left: 10 })
    }
    .width('92%')
    .padding(20)
    .margin({ bottom: 12 })
    .backgroundColor('#FFFFFF')
    .borderRadius(20)
    .border({ width: 1, color: '#F0F0F0' })
  }
}