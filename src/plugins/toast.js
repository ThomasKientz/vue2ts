import Vue from 'vue'
import { toast } from '@/utils/toast'

Vue.use({
  install(Vue) {
    Vue.prototype.$toast = toast
  },
})
