// entry/src/main/ets/pages/MarketPage.ets

interface ProductItem {
  name: string;
  price: string;
  oldPrice: string;
  seller: string;
  category: string;
  image: Resource;
}

@Component
export struct MarketPage {
  @StorageLink('appTheme') appTheme: string = 'light';
  @StorageLink('appFontSize') appFontSize: number = 17;

  @State selectedCategoryIndex: number = 0;

  private categories: string[] = ['二手交易', '失物招领', '代取快递', '兼职信息'];

  @State products: ProductItem[] = [
    { name: 'iPad Air 4 64G 考研神器', price: '2800', oldPrice: '4200', seller: '研三学姐', category: '二手交易', image: $r('app.media.ipad') },
    { name: '高等数学 第七版 下册', price: '35', oldPrice: '', seller: '大二学霸', category: '二手交易', image: $r('app.media.math') },
    { name: '吉他（入门级）没用过几次', price: '150', oldPrice: '', seller: '吉他社员', category: '二手交易', image: $r('app.media.guitar') },
    { name: '人体工学椅 很舒服', price: '80', oldPrice: '', seller: '毕业生', category: '二手交易', image: $r('app.media.chair') },
    { name: '图书馆捡到校园卡一张', price: '0', oldPrice: '', seller: '热心同学', category: '失物招领', image: $r('app.media.chair') },
    { name: '黑色双肩包在食堂二楼', price: '0', oldPrice: '', seller: '管理员', category: '失物招领', image: $r('app.media.chair') },
    { name: '帮取中通快递 小件', price: '5', oldPrice: '', seller: '跑腿小哥', category: '代取快递', image: $r('app.media.chair') },
    { name: '周末家教兼职 高中数学', price: '200', oldPrice: '300', seller: '教育机构', category: '兼职信息', image: $r('app.media.chair') },
  ];

  // 当前分类下的展示列表
  @State displayProducts: ProductItem[] = [];

  aboutToAppear() {
    this.updateDisplayProducts();
  }

  private updateDisplayProducts() {
    const cat = this.categories[this.selectedCategoryIndex];
    this.displayProducts = this.products.filter(p => p.category === cat);
  }

  build() {
    Column() {
      // 1. 顶部标题
      Row() {
        Text('校园集市')
          .fontSize(this.appFontSize + 4).fontWeight(FontWeight.Bold)
          .fontColor(this.appTheme === 'dark' ? '#FFFFFF' : '#1A1A1A')
        Blank()
        Row({ space: 15 }) {
          Image($r('app.media.cart')).width(24).height(24)
            .fillColor(this.appTheme === 'dark' ? '#CCCCCC' : '#333333')
          Image($r('app.media.add_blue')).width(24).height(24)
        }
      }.width('100%').padding(16)

      // 2. 分类（可点击切换）
      Row({ space: 20 }) {
        ForEach(this.categories, (cat: string, index: number) => {
          Text(cat)
            .fontSize(this.selectedCategoryIndex === index ? this.appFontSize + 1 : this.appFontSize - 1)
            .fontColor(this.selectedCategoryIndex === index ? '#2F6BFA' : (this.appTheme === 'dark' ? '#888888' : '#666'))
            .fontWeight(this.selectedCategoryIndex === index ? FontWeight.Bold : FontWeight.Normal)
            .onClick(() => {
              this.selectedCategoryIndex = index;
              this.updateDisplayProducts();
            })
        }, (cat: string) => cat)
      }.width('100%').padding({ left: 16, bottom: 15 })

      // 3. 搜索框
      Row() {
        Row({ space: 10 }) {
          Image($r('app.media.search')).width(18).height(18)
            .fillColor(this.appTheme === 'dark' ? '#888888' : '#999999')
          Text('搜索宝贝、关键词...')
            .fontSize(this.appFontSize - 2)
            .fontColor(this.appTheme === 'dark' ? '#666666' : '#999')
        }.layoutWeight(1)
        .backgroundColor(this.appTheme === 'dark' ? '#2D2D35' : '#F3F4F6')
        .padding(10).borderRadius(10)

        Image($r('app.media.filter')).width(22).height(22).margin({ left: 15 })
          .fillColor(this.appTheme === 'dark' ? '#CCCCCC' : '#333333')
        Text('筛选')
          .fontSize(this.appFontSize - 2)
          .fontColor(this.appTheme === 'dark' ? '#888888' : '#666')
          .margin({ left: 5 })
      }.width('100%').padding({ left: 16, right: 16, bottom: 10 })

      // 4. 商品网格（按分类动态过滤，使用 Grid + GridItem 稳定布局）
      Scroll() {
        if (this.displayProducts.length === 0) {
          Column() {
            Text('暂无商品').fontSize(this.appFontSize).fontColor('#999').margin({ top: 60 })
          }.width('100%')
        } else {
          Grid() {
            ForEach(this.displayProducts, (item: ProductItem) => {
              GridItem() {
                this.ProductCard(item)
              }
            }, (item: ProductItem) => `${item.name}_${item.category}`)
          }
          .columnsTemplate('1fr 1fr')
          .columnsGap(12)
          .rowsGap(12)
          .width('100%')
          .padding(16)
        }
      }.layoutWeight(1)
    }
    .width('100%').height('100%')
    .backgroundColor(this.appTheme === 'dark' ? '#121216' : '#F7F8FA')
  }

  @Builder ProductCard(item: ProductItem) {
    Column() {
      Image(item.image)
        .width('100%').height(150)
        .objectFit(ImageFit.Cover)
        .borderRadius({ topLeft: 12, topRight: 12 })

      Column({ space: 6 }) {
        Text(item.name)
          .fontSize(this.appFontSize - 2).fontWeight(FontWeight.Medium)
          .fontColor(this.appTheme === 'dark' ? '#FFFFFF' : '#1A1A1A')
          .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })

        Row({ space: 5 }) {
          Text('￥' + item.price)
            .fontSize(this.appFontSize).fontColor('#FA5151').fontWeight(FontWeight.Bold)
          if (item.oldPrice) {
            Text('￥' + item.oldPrice)
              .fontSize(this.appFontSize - 5)
              .fontColor(this.appTheme === 'dark' ? '#666666' : '#CCC')
              .decoration({ type: TextDecorationType.LineThrough })
          }
        }.width('100%')

        Row({ space: 4 }) {
          Circle({ width: 4, height: 4 }).fill('#2F6BFA')
          Text(item.seller)
            .fontSize(this.appFontSize - 6)
            .fontColor(this.appTheme === 'dark' ? '#888888' : '#999')
        }
      }.padding(10).alignItems(HorizontalAlign.Start)
    }
    .backgroundColor(this.appTheme === 'dark' ? '#1E1E24' : '#FFF')
    .borderRadius(12).shadow({ radius: 6, color: '#05000000' })
  }
}
