import { Capacitor } from '@capacitor/core'
import { App } from '@capacitor/app'
import { Keyboard } from '@capacitor/keyboard'
// #if process.env.IS_ELECTRON
import { ipcRenderer } from 'electron'
import Store from 'electron-store'

const store = new Store()

export const setStartOnLoggin = boolean =>
  ipcRenderer.send('setStartLogin', boolean)
// #endif

export const getStartOnLogginSetting = () =>
  process.env.IS_ELECTRON && store.get('startOnLoggin', true)

export const setStartOnLogginSetting = boolean =>
  process.env.IS_ELECTRON && store.set('startOnLoggin', boolean)

export const closeApp = () => {
  if (process.env.IS_ELECTRON) return ipcRenderer.send('close')

  return App.exitApp()
}

const getPlatform = () => {
  if (
    Capacitor.getPlatform() === 'ios' ||
    Capacitor.getPlatform() === 'android'
  ) {
    return Capacitor.getPlatform()
  }

  if (process.env.IS_ELECTRON && process.platform) {
    return 'electron ' + process.platform
  }

  console.error('getPlatform() : unknown platform')
  console.log('Capacitor.getPlatform() :', Capacitor.getPlatform())
  console.log('process.platform :', process.platform)
  return 'unknown platform'
}

export const platform = getPlatform()

export const showKeyboard = () => {
  Capacitor.getPlatform() === 'android' && Keyboard.show()
}
