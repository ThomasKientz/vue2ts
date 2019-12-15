import Vue from 'vue'
import jwt from 'jsonwebtoken'
import Vuex from 'vuex'
import { VuexPersist } from '@/utils/storage'
import AppPrefPlugin from './appPrefPlugin'
import { Capacitor } from '@capacitor/core'

Vue.use(Vuex)

export default new Vuex.Store({
  plugins: [
    VuexPersist.plugin,
    ...((Capacitor.isNative && [AppPrefPlugin]) || []),
  ],

  state() {
    return {
      token1: null,
      token2: null,
      subjectMode: null,
      subjectText: null,
      fromText: null,
      theme: 'auto',
    }
  },
  getters: {
    getEmail: state => id => {
      const { email } = jwt.decode(state['token' + id])
      return email
    },
  },
  mutations: {
    setToken: (state, { token, id }) => {
      state['token' + id] = token
    },
    setSubjectMode: (state, v) => {
      state.subjectMode = v
    },
    setSubjectText: (state, v) => {
      state.subjectText = v
    },
    setFromText: (state, v) => {
      state.fromText = v
    },
    setTheme: (state, v) => {
      state.theme = v
    },
  },
  actions: {
    saveToken({ commit, state }, token) {
      const id = state.token1 ? 2 : 1
      commit('setToken', { token, id })
    },
    removeToken({ commit, state }, id) {
      if (id == 1 && state.token2) {
        commit('setToken', { id: 1, token: state.token2 })
        commit('setToken', { id: 2, token: null })
      } else {
        commit('setToken', { token: null, id })
      }
    },
  },
})
