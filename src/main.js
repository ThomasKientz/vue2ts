import * as Sentry from '@sentry/browser'
import * as Integrations from '@sentry/integrations'
Sentry.init({
  dsn: process.env.NODE_ENV === 'production' && process.env.VUE_APP_SENTRY_DSN,
  integrations: [
    new Integrations.CaptureConsole({
      levels: ['error'],
    }),
  ],
  environment: 'production',
})

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
