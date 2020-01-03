import { format, parse } from 'date-fns'

export default {
  state() {
    return {
      rating: null,
      neverAsk: null,
      skip: null,
      counter: null,
    }
  },
  mutations: {
    setRating(state, v) {
      state.rating = v
    },
    setNeverAsk(state, v) {
      state.neverAsk = v
    },
    setSkip(state, v) {
      state.skip = v
    },
    increment(state) {
      state.counter = state.counter + 1
    },
  },
  actions: {
    skip({ commit }) {
      const date = format(new Date(), 'yyyy-MM-dd')
      commit('setSkip', date)
    },
    neverAsk({ commit }) {
      commit('setNeverAsk', true)
    },
  },
  getters: {
    skipDate: state => {
      if (!state.skip) return null

      const date = parse(state.skip, 'yyyy-MM-dd', new Date())

      if (isNaN(date)) {
        console.error('error in skipDate getters: invalid date')
        return null
      }

      return date
    },
  },
}
