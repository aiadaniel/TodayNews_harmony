import categoryTitleViewModel from '../viewmodel/CategoryTitleViewModel';
import display from '@ohos.display';
import NewsDataList from './NewsDataList';
import { FailureLayout, ResManager, TabBarLayout } from 'common';
import promptAction from '@ohos.promptAction';
import { HotListView } from './HotListView';

@Component
export default struct CategoryTabBar {
  @State tabBarArray: string[] = categoryTitleViewModel.getDefaultCategoryList();
  @State currentIndex: number = 0;
  @State displayWidth: number = 0;
  @Link needChange: boolean;

  aboutToAppear() {
    let displayClass = display.getDefaultDisplaySync();
    this.displayWidth = px2vp(displayClass.width);
  }

  @Builder
  newsListView(index: number) {
    if (index === 0) {
      //全部新闻
      NewsDataList({ categoryId: $currentIndex, pageIndex: 0 })
    } else if (index === 1) {
      //热榜
      HotListView()
    } else {
      //暂时都给失败页面
      Column() {
        FailureLayout()
      }
    }

  }

  @Builder
  rightView() {//右侧分类按钮
    Image(this.needChange ? $r('app.media.right_more_icon_Normal') : $r('app.media.toolbar_more_new_Normal'))
      .height(50)
      .objectFit(ImageFit.Contain)
      .width(50 + 10)
      .zIndex(2)
      .padding({
        left: 30,
        right: 10,
        top: 15,
        bottom: 15
      })
      .linearGradient({
        angle: 90,
        colors: [[this.needChange ? 0x44FE5756 : 0x44ffffff, 0.2], [this.needChange ? 0xFE5756 : Color.White, 0.5],
          [this.needChange ? 0xFE5756 : Color.White, 1]]
      })
      .onClick(() => {
        promptAction.showToast({
          message: '点击了分类按钮',
          duration: 2000,
        });
      })
  }

  build() {
    Scroll() {//滚动效果

      Flex({ direction: FlexDirection.Column }) {
        //不使用内置Tabs组件而是自定义：因为要做tabbar更多按钮的效果？
        TabBarLayout({
          titleArr: $tabBarArray,//
          offsetHeight: 56 + 60,
          colorChangeIndex: 1,
          bgChangeColor: ResManager.getDefaultColor(),
          fontChangeSelectedColor: "#FDE1E0",
          fontChangeNormalColor: "#FFFFFF",
          rightView: () => {
            this.rightView()
          },
          customList: ($$) => {//todo lxm
            this.newsListView($$.index)
          },
          changeColor: (changeColor: boolean) => {
            this.needChange = changeColor;
          },
          tabSelected: (position: number, title: string) => {//重写了子组件方法
            promptAction.showToast({
              message: `点击了第 ${position} 页面，标题为：${title}`,
              duration: 2000,
            });
          }

        })

      }

    }
  }
}