import { LocalDataManager } from '../viewmodel/LocalDataManager';

import { productModel } from '../viewmodel/productModel';
import { productView } from './productView';


@Component
export struct productLayout {
  @State productList: Array<productModel> = [];
  @Link @Watch('changeIndex') currentIndex: number;
  private localManager: LocalDataManager = LocalDataManager.instance();

  aboutToAppear() {
    this.changeIndex();
  }

  changeIndex() {

    let array: Array<productModel> = [];
    if (this.currentIndex === 0) {
      array = this.localManager.queryProductList();
    } else {
      array = this.localManager.queryProductCollectList();
    }

    this.productList = [];
    for (let index = 0; index < array.length; index++) {
      const element = array[index];
      this.productList.push(element)
    }
  }

  build() {

    List() {
      ForEach(this.productList, (product: productModel) => {

        ListItem() {
          productView({ product: product })
        }

      }, (item: productModel) => JSON.stringify(item))

    }
    .backgroundColor(Color.White)
    .divider({ strokeWidth: 10, color: 0xF2F1F2 })

  }
}