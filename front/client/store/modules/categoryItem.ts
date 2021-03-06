import { ActionTree, GetterTree, MutationTree, ActionContext, Module } from 'vuex'
import { ICategoryItem, CategoryItemService } from 'client/service/CategoryItem'

interface CategoryItemState {
  categoryItemList: ICategoryItem[]
}

const state: CategoryItemState = {
  categoryItemList: []
}

const getters: GetterTree<CategoryItemState, any> = {}

const actions: ActionTree<CategoryItemState, any> = {
  async loadCategoryItem({ commit }: ActionContext<CategoryItemState, any>): Promise<any> {
    const data: ICategoryItem[] = await CategoryItemService.getCategoryItem()
    commit('setCategoryItem', data)
  }
}

const mutations: MutationTree<CategoryItemState> = {
  setCategoryItem: (state: CategoryItemState, payload: ICategoryItem[]) => {
    state.categoryItemList = payload
  }
}

const categoryItem: Module<CategoryItemState, any> = {
  namespaced: true,
  state,
  getters,
  actions,
  mutations
}

export default categoryItem