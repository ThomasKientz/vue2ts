// #if process.env.PLATFORM === 'electron'
import Storage from 'electron-store'
const storage = new Storage()

const store = {
  getItem: key => storage.get(key),
  setItem: (key, data) => storage.set(key, data),
  removeItem: key => storage.delete(key),
  clear: () => storage.clear(),
  length: () => storage.size(),
}
// #endif

import VuexPersistence from 'vuex-persist'

export default new VuexPersistence({
  storage: process.env.PLATFORM === 'electron' ? store : window.localStorage,
  // asyncStorage: true,
})

// export default process.env.PLATFORM === 'electron'
//   ? store
//   : {
//       get: key => {
//         console.log('get key', key)
//         const token = window.localStorage.getItem(key)
//         console.log(key, token)
//         return token
//       },
//       set: (key, value) => window.localStorage.setItem(key, value),
//       delete: key => window.localStorage.removeItem(key),
//     }
