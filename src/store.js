import Vue from 'vue'
import Storage from 'electron-store'
const storage = new Storage()

const store = {
  email: storage.get('email'),
  set: {
    email: (email) => storage.set('email', email)
  }
}

Vue.use({
  install (Vue) {
    Vue.prototype.$store = store
  }
})

export default store
