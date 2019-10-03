// #if process.env.PLATFORM === 'electron'
import Storage from 'electron-store'
const storage = new Storage()
// #endif

export default process.env.PLATFORM === 'electron'
  ? storage
  : {
      get: key => window.localStorage.getItem(key),
      set: (key, value) => window.localStorage.setItem(key, value),
    }
