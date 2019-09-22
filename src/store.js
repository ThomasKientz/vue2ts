import Vue from 'vue'
import jwt from 'jsonwebtoken'
import Vuex from 'vuex'

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

Vue.use(Vuex)

export default new Vuex.Store({
  state() {
    return {
      token: storage.get('token'),
    }
  },
  getters: {
    email: state => {
      const { email } = jwt.decode(state.token)
      return email
    },
  },
  mutations: {
    setToken: (state, token) => {
      state.token = token
    },
  },
  actions: {
    saveToken({ commit }, token) {
      storage.set('token', token)
      commit('setToken', token)
    },
  },
})
