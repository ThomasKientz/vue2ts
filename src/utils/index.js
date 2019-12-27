// #if process.env.IS_ELECTRON
import { ipcRenderer } from 'electron'
import Store from 'electron-store'

const store = new Store()

export const setStartOnLoggin = boolean =>
  ipcRenderer.send('setStartLogin', boolean)
// #endif

import { Plugins } from '@capacitor/core'
const { App } = Plugins

export const getStartOnLogginSetting = () =>
  process.env.IS_ELECTRON && store.get('startOnLoggin', true)

export const setStartOnLogginSetting = boolean =>
  process.env.IS_ELECTRON && store.set('startOnLoggin', boolean)

export const closeApp = () => {
  if (process.env.IS_ELECTRON) return ipcRenderer.send('close')

  return App.exitApp()
}
