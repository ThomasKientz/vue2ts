// #if process.env.PLATFORM === 'electron'
import { ipcRenderer } from 'electron'
// #endif

import { Plugins } from '@capacitor/core'
const { App } = Plugins

export const closeApp = () => {
  if (process.env.PLATFORM === 'electron') return ipcRenderer.send('close')

  return App.exitApp()
}
