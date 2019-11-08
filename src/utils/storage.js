// #if process.env.PLATFORM === 'electron'
import ElectronStorage from 'electron-store'
// #endif

import { Plugins, Capacitor } from '@capacitor/core'
import VuexPersistence from 'vuex-persist'

const getStorage = () => {
  if (process.env.PLATFORM === 'electron') {
    const storage = new ElectronStorage()

    return {
      storage: {
        getItem: key => storage.get(key),
        setItem: (key, value) => storage.set(key, value),
        removeItem: key => storage.delete(key),
        clear: () => storage.clear(),
        length: () => storage.size(),
      },
    }
  } else if (Capacitor.isNative) {
    const CapStorage = Plugins.Storage
    return {
      storage: {
        getItem: key =>
          CapStorage.get({ key }).then(res => {
            console.log('GET key :', key)
            console.log('val :', res)
            return res.value && JSON.parse(res.value)
          }),
        setItem: (key, value) =>
          CapStorage.set({ key, value: JSON.stringify(value) }),
        removeItem: key => CapStorage.remove({ key }),
      },
      asyncStorage: true,
    }
  } else return { storage: window.localStorage }
}

export const VuexPersist = new VuexPersistence(getStorage())
