// #if process.env.PLATFORM === 'electron'
import { ipcRenderer } from 'electron'
// #endif

export const closeApp = () => {
  if (process.env.PLATFORM === 'electron')
    return ipcRenderer.send('close', 'ping')
  else return console.log('closeApp() not implemented for this platform.')
}
