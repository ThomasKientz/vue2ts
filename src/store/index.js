import Vue from 'vue'
import jwt from 'jsonwebtoken'
import Vuex from 'vuex'
import { VuexPersist } from '@/utils/storage'
import AppPrefPlugin from './appPrefPlugin'
import { Capacitor } from '@capacitor/core'
import rateModule from './rateModule'

Vue.use(Vuex)

export default new Vuex.Store({
  plugins: [
    VuexPersist.plugin,
    ...((Capacitor.isNative && [AppPrefPlugin]) || []),
  ],
  modules: {
    rate: rateModule,
  },

  state() {
    return {
      token1: null,
      token2: null,
      displayName1: null,
      displayName2: null,
      subjectMode: null,
      subjectText: null,
      fromText: null,
      theme: 'auto',
      autoClose: false,
    }
  },
  getters: {
    getEmail: state => id => {
      const { email } = jwt.decode(state['token' + id])
      return email
    },
  },
  mutations: {
    setDisplayName: (state, { name, id }) => {
      state['displayName' + id] = name
    },
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
    setAutoClose: (state, v) => {
      state.autoClose = v
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
        commit('setDisplayName', { id: 1, name: state.displayName2 })
        commit('setToken', { id: 2, token: null })
        commit('setDisplayName', { id: 2, name: null })
      } else {
        commit('setToken', { id, token: null })
        commit('setDisplayName', { id, name: null })
      }
    },
  },
})
