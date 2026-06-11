// entry/src/main/ets/pages/MarketPage.ets
@Component
export struct MarketPage {
  @StorageLink('appTheme') appTheme: string = 'light';
  @StorageLink('appFontSize') appFontSize: number = 16;

  build() {
    Column() {
      // 1. 顶部标题
      Row() {
        Text('校园集市').fontSize(this.appFontSize + 4).fontWeight(FontWeight.Bold)
        Blank()
        Row({ space: 15 }) {
          Image($r('app.media.cart')).width(24).height(24)
          Image($r('app.media.add_blue')).width(24).height(24)
        }
      }.width('100%').padding(16)

      // 2. 分类
      Row({ space: 20 }) {
        this.Category('二手交易', true)
        this.Category('失物招领', false)
        this.Category('代取快递', false)
        this.Category('兼职信息', false)
      }.width('100%').padding({ left: 16, bottom: 15 })

      // 3. 搜索框
      Row() {
        Row({ space: 10 }) {
          Image($r('app.media.search_gray')).width(18).height(18)
          Text('搜索宝贝、关键词...').fontSize(14).fontColor('#999')
        }.layoutWeight(1).backgroundColor(this.appTheme === 'dark' ? '#2D2D35' : '#F3F4F6').padding(10).borderRadius(10)
        Image($r('app.media.filter')).width(22).height(22).margin({ left: 15 })
        Text('筛选').fontSize(14).fontColor('#666').margin({ left: 5 })
      }.width('100%').padding({ left: 16, right: 16, bottom: 10 })

      // 4. 商品网格 (复刻双列布局)
      Scroll() {
        GridRow({ columns: 2, gutter: 12 }) {
          GridCol() { this.ProductCard('iPad Air 4 64G 考研神器', '2800', '4200', '研三学姐') }
          GridCol() { this.ProductCard('高等数学 第七版 下册', '35', '', '大二学霸') }
          GridCol() { this.ProductCard('吉他（入门级）没用过几次', '150', '', '吉他社员') }
          GridCol() { this.ProductCard('人体工学椅 很舒服', '80', '', '毕业生') }
        }.padding(16)
      }.layoutWeight(1)
    }
    .width('100%').height('100%')
    .backgroundColor(this.appTheme === 'dark' ? '#121216' : '#F7F8FA')
  }

  @Builder Category(name: string, isAct: boolean) {
    Text(name).fontSize(isAct ? this.appFontSize + 1 : this.appFontSize - 1)
      .fontColor(isAct ? '#2F6BFA' : '#666').fontWeight(isAct ? FontWeight.Bold : FontWeight.Normal)
  }

  @Builder ProductCard(title: string, price: string, oldPrice: string, tag: string) {
    Column() {
      // 模拟图片
      Rect().width('100%').height(150).fill('#EEE').borderRadius({ topLeft: 12, topRight: 12 })

      Column({ space: 6 }) {
        Text(title).fontSize(14).fontWeight(FontWeight.Medium).maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })

        Row({ space: 5 }) {
          Text('￥' + price).fontSize(16).fontColor('#FA5151').fontWeight(FontWeight.Bold)
          if (oldPrice) Text('￥' + oldPrice).fontSize(11).fontColor('#CCC').decoration({ type: TextDecorationType.LineThrough })
        }.width('100%')

        Row({ space: 4 }) {
          Circle({ width: 4, height: 4 }).fill('#2F6BFA')
          Text(tag).fontSize(10).fontColor('#999')
        }
      }.padding(10).alignItems(HorizontalAlign.Start)
    }
    .backgroundColor(this.appTheme === 'dark' ? '#1E1E24' : '#FFF')
    .borderRadius(12).shadow({ radius: 6, color: '#05000000' })
  }
}