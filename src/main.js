import Vue from 'vue'
import App from './App.vue'
import router from './router'
import store from './store'
import vuetify from './plugins/vuetify'
import './plugins/toast'
import '@/style/main.scss'
import { setupPlatforms } from '@/utils/platform'

Vue.config.productionTip = false

setupPlatforms()

new Vue({
  router,
  store,
  vuetify,
  render: h => h(App),
}).$mount('#app')
