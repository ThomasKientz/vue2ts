import Vue from 'vue'
// import storage from '@/utils/storage'

// const storage = require('@/utils/storage')

const storage = {
  get(val) {
    return window.localStorage.getItem(val)
  },
  set(key, val) {
    return window.localStorage.setItem(key, val)
  },
}

const store = {
  token: storage.get('token'),
  set: (key, value) => storage.set(key, value),
}

Vue.use({
  install(Vue) {
    Vue.prototype.$store = store
  },
})

export default store
