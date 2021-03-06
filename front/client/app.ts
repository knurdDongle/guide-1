import Vue from 'vue'
import VueRouter from 'vue-router'
import Vuex from 'vuex'
import Vuetify from 'vuetify'
import { sync } from 'vuex-router-sync'
import ALink from 'client/components/ALink.vue'
import 'vuetify/dist/vuetify.css' // Ensure you are using css-loader
import '@fortawesome/fontawesome-free/css/all.css'
import 'material-design-icons-iconfont/dist/material-design-icons.css'

import AppComponent from './App.vue'
import { createRouter } from './router'
import { createStore } from './store'


function initVue() {
  Vue.use(VueRouter)
  Vue.use(Vuex)
  Vue.use(Vuetify)
  Vue.component('ALink', ALink)
}

function createApp() {
  const router = createRouter()
  const store = createStore()

  sync(store, router)

  const app = new Vue({
    router,
    store,
    render(h) {
      return h(AppComponent)
    }
  })

  return {
    app,
    router,
    store
  }
}

initVue()


export {
  createApp
}
