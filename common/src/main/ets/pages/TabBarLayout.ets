import measure from '@ohos.measure';
import display from '@ohos.display';
import { ResManager } from '../constants/ResManager';
import { TabBarDataSource } from '../utils/TabBarDataSource';

export interface CustomItem {
  index: number;
}

@Component
export struct TabBarLayout {
  // 设置展示的高度，默认减去了tabBar和状态栏高度
  offsetHeight?: number = 0;
  // 传入的内容列表数据 index:为页面的索引  参考：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-two-way-sync
  @BuilderParam customList: ($$: CustomItem) => void;
  // 传入的内容列表数据
  @BuilderParam rightView: () => void;
  // 标题列表，由父组件初始化
  @Link titleArr: string[]
  // 高度
  tabBarHeight?: number = 50;
  // 分类需要替换背景颜色
  @State colorChangeIndex: number = 0;
  // 需要替换的颜色
  bgChangeColor: string = '';
  // 需要替换的颜色
  fontChangeNormalColor: string = "";
  // 需要替换的颜色
  fontChangeSelectedColor: string = "";
  // 指示器x坐标
  @State indicatorX: number = 0;
  // 状态栏高度
  @State statusBarH: number = 30
  // 左右滑动的距离
  @State scrollX: number = 0
  // 屏幕宽度
  @State screenW: number = 0;
  // 高度
  @State screenH: number = 0;
  // 当前的页面索引
  @State @Watch("updateViewState") currentIndex: number = 0;
  // 模型数据
  @State private tabDataArr: TabBarDataSource = new TabBarDataSource();
  // 顶部tabBar滚动控制器
  private tabBarScroller: Scroller = new Scroller()
  // 内容滚动控制器
  private contentScroller: Scroller = new Scroller()
  // 标题size
  private fontSizeNormal: number = 16
  // 间距
  private tabMargin: number = 15
  // 默认颜色
  private bgDefaultColor: string = '#ffffff';
  // 默认颜色
  private fontDefaultNormalColor: string = "#000000";
  // 默认颜色
  private fontDefaultSelectedColor: string = ResManager.getDefaultColor();
  // 是否改变颜色
  @State private changeAllColor: boolean = false;
  // 开始的左边距离
  private left: number = 0
  // 默认指示器宽度
  private defaultIndicatorW: number = 24;
  // 指示器宽度
  @State indicatorWidth: number = this.defaultIndicatorW;
  // 上次手指按下的位置
  private lastX: number = 0;
  // 是否正在滚动
  private isScrolling: Boolean = false;

  // 当前索引发生改变的监听
  updateViewState() {
    // 获取当前的tab数据
    const item: TabModel = this.tabDataArr.getData(this.currentIndex);
    try {
      // 滚动到屏幕中央
      this.scrollToCenter(item.left, item.width)
    } catch (error) {
    }

    // 回调函数
    if (this.tabSelected instanceof Function) {
      this.tabSelected(item.index, item.content)
    }

    if (this.changeColor != undefined && this.currentIndex === this.colorChangeIndex) {
      this.changeAllColor = true
      this.changeColor(this.changeAllColor);
    } else {
      this.changeAllColor = false
      this.changeColor(this.changeAllColor);
    }

    // 重置指示器的状态
    this.resetIndicator(false);

    // 执行内容页面的滑动
    animateTo({
      duration: 200,
      onFinish: () => {
        this.isScrolling = false;
      }
    },
      () => {
        this.contentScroller.scrollTo({
          xOffset: (this.currentIndex) * this.screenW,
          yOffset: 0,
          animation: { duration: 200, curve: Curve.EaseOut }
        })
      })
  }

  // 重置指示器状态
  resetIndicator(source: boolean) {

    // 获取当前的tab数据
    const item: TabModel = this.tabDataArr.getData(this.currentIndex);

    // 更新指示器的宽度和x轴坐标
    animateTo({
      duration: 200,
      onFinish: () => {
        // 动画结束 来源是不发生翻页的情况
        if (source) {
          this.isScrolling = false;
        }
      }
    }, () => {
      // 重置指示器宽度为原始宽度
      this.indicatorWidth = this.defaultIndicatorW;
      // 指示器重置到中心
      this.indicatorX = item.left + (item.width - this.indicatorWidth) / 2
    })

  }

  // tab标签选中监听 父类可重写
  tabSelected: (position: number, title: string) => void = (position: number, title: string) => {
    console.log('tabSelected position = ' + position + ', title = ' + title)
  }
  changeColor: (changColor: boolean) => void = (changColor: boolean) => {

  }

  aboutToAppear() {

    this.titleArr.map((title, index) => {
      let tabModel = new TabModel()
      tabModel.index = index
      tabModel.content = title
      tabModel.left = this.left

      // 计算文本的宽度值
      const textW = measure.measureText({
        textContent: title,
        fontSize: this.fontSizeNormal,
        fontWeight: FontWeight.Normal
      })
      let width = px2vp(textW) + this.tabMargin
      // 默认指示器位置
      if (index === 0) {
        this.indicatorX = (width - this.indicatorWidth) / 2
      }
      tabModel.width = width
      tabModel.left = this.left
      this.left += width
      this.tabDataArr.addData(index, tabModel)
    })

    // 获取屏幕的宽度和高度
    let promise = display.getAllDisplays();
    promise.then((data) => {
      const tempScreenW = data[0].width
      const tempScreenH = data[0].height
      this.screenH = px2vp(tempScreenH)
      this.screenW = px2vp(tempScreenW)
    }).catch(() => {
    });
  }

  build() {

    Column() {
      // ----顶部tabBar内容开始------
      Stack({ alignContent: Alignment.End }) {

        if (this.rightView !== undefined) {
          this.rightView();//来自父组件 zIndex=2
        }

        Scroll(this.tabBarScroller) {
          Flex({ direction: FlexDirection.Column, justifyContent: FlexAlign.Start }) {//横向bar + 指示器 的布局

            Flex({ direction: FlexDirection.Row }) {//整个横向bar布局

              ForEach(this.tabDataArr.getDataArr(), (item: TabModel, index: number) => {

                Flex({
                  direction: FlexDirection.Row,
                  justifyContent: FlexAlign.Center,
                  alignItems: ItemAlign.Center
                }) {//每个页签单项布局 可以不用？ 这个布局效率应该比Column低？
                  // 标题
                  Text(item.content)
                    .fontSize(this.fontSizeNormal)
                    .fontColor(this.currentIndex == item.index ?
                      (this.changeAllColor ? this.fontChangeSelectedColor : this.fontDefaultSelectedColor) :
                      (this.changeAllColor ? this.fontChangeNormalColor : this.fontDefaultNormalColor))
                    .fontWeight(FontWeight.Normal)
                    .textAlign(TextAlign.Center)
                    .height(20)
                    .onClick((event: ClickEvent) => {
                      this.isScrolling = true;
                      this.currentIndex = item.index;
                    })
                }.margin({ right: index === this.tabDataArr.totalCount() - 1 ? 40 : 0 })
                .width(item.width)
                .height(this.tabBarHeight)

              }, (item: TabModel) => JSON.stringify(item))

            }//flex

            // 指示器  另一种思路：做到上面每个子项的布局里，控制显隐
            Column()
              .height(3)
              .width(this.indicatorWidth)
              .borderRadius(3)
              .margin({ top: 10 })
              .position({ x: this.indicatorX, y: 40 })
              .backgroundColor(this.changeAllColor ? this.bgDefaultColor : this.bgChangeColor)
          }//flex

        }//scroll
        .backgroundColor(this.changeAllColor ? this.bgChangeColor : this.bgDefaultColor)
        .scrollBar(BarState.Off)
        .scrollable(ScrollDirection.Horizontal)

      }//Stack
      .height(this.tabBarHeight)
      // ----顶部tabBar内容 结束------

      // ----内容部分 开始------
      if (this.customList !== undefined) {
        Scroll(this.contentScroller) {//嵌套了list，而且都是水平方向 只为onScroll监听？  嵌套滚动需要设置子list的宽高!
          // 横向滚动的List
          List() {
            LazyForEach(this.tabDataArr, (item: TabModel, index: number) => {
              ListItem() {
                Scroll() {//新闻内容列表的滚动
                  Column() {
                    this.customList({ index: index })//这里面还有list，所以是不是过度嵌套了，会产生卡顿
                  }
                }
                .width(this.screenW)
                .height(this.screenH - this.tabBarHeight! - this.statusBarH - this.offsetHeight!)
              }
            }, (item: TabModel) => JSON.stringify(item))
          }.cachedCount(2)
          .listDirection(Axis.Horizontal)
        }//Scroll
        .scrollable(ScrollDirection.Horizontal)//这里也是横向
        .edgeEffect(EdgeEffect.Spring)
        .scrollBar(BarState.Off)
        .onScroll((xOffset: number, yOffset: number) => {
          this.scrollX += xOffset
          this.handScroll(xOffset)
        })
      }

    }.onTouch((event: TouchEvent) => {//整个Column的事件 会跟上面的事件重叠 效率？
      // 处理横向翻页
      this.handTouchEvent(event)
    })

  }

  // 处理横向滚动数据
  handScroll(xOffset: number) {
    // 滚动的比例
    const scale = (this.scrollX - (this.currentIndex * this.screenW)) / this.screenW;
    // 正在执行滚动动画，直接返回
    if (this.isScrolling) {
      return;
    }
    // 获取当前页的数据
    const currentItem: TabModel = this.tabDataArr.getData(this.currentIndex);
    // 下一页的索引
    let nextPage: number;
    if (this.currentIndex === this.titleArr.length - 1 && scale > 0) {
      return;
    }
    if (this.currentIndex === 0 && scale < 0) {
      return;
    }
    nextPage = scale < 0 ? this.currentIndex - 1 : this.currentIndex + 1;
    // 修改颜色判断
    if (nextPage === this.colorChangeIndex && Math.abs(scale) >= 0.5) {
      this.changeAllColor = true;
    } else if (this.currentIndex === this.colorChangeIndex && Math.abs(scale) < 0.5) {
      this.changeAllColor = true;
    } else {
      this.changeAllColor = false;
    }
    // 调用回调
    if (this.changeColor != undefined) {
      this.changeColor(this.changeAllColor);
    }

    const nextItem: TabModel = this.tabDataArr.getData(nextPage);
    // 计算两个item的距离,需要滑动的距离
    const scrollDistance = (currentItem.width + nextItem.width) / 2;
    // 计算每次需要增加距离
    const tempOffset = xOffset / this.screenW * scrollDistance;
    // 修改指示器x轴坐标
    this.indicatorX += tempOffset;
    // 根据滑动比例，设置指示器宽度
    this.indicatorWidth += Math.abs(tempOffset * scale);
  }

  // 滚动至中间位置
  scrollToCenter(itemLeft: number, itemWidth: number): void {

    // 指示器也滚动到tabBar的中心位置
    animateTo({ duration: 200, delay: 10 }, () => {
      this.indicatorX = itemLeft + (itemWidth - this.indicatorWidth) / 2
    })

    // 计算中心需要的x轴位置
    let targetOffset: number = itemLeft + itemWidth / 2 - this.screenW / 2

    // 滚动到指定位置
    this.tabBarScroller.scrollTo({
      xOffset: targetOffset,
      yOffset: 0,
      animation: { duration: 200, curve: Curve.EaseInOut }
    })
  }

  // 处理翻页时间
  handTouchEvent(event: TouchEvent): void {

    if (event.type === TouchType.Down) {
      // 记录滑动开始时的x值
      this.lastX = event.touches[0].x
    } else if (event.type === TouchType.Move) {

    } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
      // 滑动的距离
      let dis: number = (event.touches[0].x - this.lastX)
      // 滑动到屏幕的三分之一就可以翻页
      let needChangePage: boolean = Math.abs(dis) > this.screenW / 3

      // 滑动的时候记录正在滚动状态，在松开手之后重置滚动状态为false
      this.isScrolling = true;
      if (needChangePage) {
        // 需要翻页
        if (dis < 0) {
          // 判断页面边缘
          if (this.currentIndex !== this.titleArr.length - 1) {
            this.currentIndex += 1;
          }
        } else {
          if (this.currentIndex !== 0) {
            this.currentIndex -= 1;
          }
        }
      } else {
        // 不需切换页面
        this.resetIndicator(true);
        this.contentScroller.scrollTo({
          xOffset: (this.currentIndex) * this.screenW,
          yOffset: 0,
          animation: { duration: 200, curve: Curve.EaseOut }
        })
      }
    }
  }
}

enum BarSelectStyle {
  normal,
  scale
}


export class TabModel {
  index: number = 0
  content: string = ''
  left: number = 0
  width: number = 0
}

export { BarSelectStyle }