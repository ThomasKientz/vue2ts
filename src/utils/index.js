// #if process.env.IS_ELECTRON
import { ipcRenderer } from 'electron'
// #endif

import { Plugins } from '@capacitor/core'
const { App } = Plugins

export const closeApp = () => {
  if (process.env.IS_ELECTRON) return ipcRenderer.send('close')

  return App.exitApp()
}
