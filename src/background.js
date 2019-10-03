'use strict'
/* global __static */

import { app, protocol, Tray, BrowserWindow, ipcMain } from 'electron'
import {
  createProtocol,
  // installVueDevtools
} from 'vue-cli-plugin-electron-builder/lib'
import * as path from 'path'
import { getWindowPosition } from './utils/getWindowPosition'
import Positioner from 'electron-positioner'

const isDevelopment = process.env.NODE_ENV !== 'production'

let win, positioner, tray, windowPosition, cachedBounds

ipcMain.on('close', () => {
  console.log('CLOSE')
  hideWindow()
})

// Scheme must be registered before the app is ready
protocol.registerSchemesAsPrivileged([
  { scheme: 'app', privileges: { secure: true, standard: true } },
])

// Quit when all windows are closed.
app.on('window-all-closed', () => {
  // On macOS it is common for applications and their menu bar
  // to stay active until the user quits explicitly with Cmd + Q
  if (process.platform !== 'darwin') {
    app.quit()
  }
})

app.on('activate', () => {
  // On macOS it's common to re-create a window in the app when the
  // dock icon is clicked and there are no other windows open.
  if (win === null) {
    createWindow()
  }
})

// This method will be called when Electron has finished
// initialization and is ready to create browser windows.
// Some APIs can only be used after this event occurs.
app.on('ready', async () => {
  if (isDevelopment && !process.env.IS_TEST) {
    // Install Vue Devtools
    // Devtools extensions are broken in Electron 6.0.0 and greater
    // See https://github.com/nklayman/vue-cli-plugin-electron-builder/issues/378 for more info
    // Electron will not launch with Devtools extensions installed on Windows 10 with dark mode
    // If you are not using Windows 10 dark mode, you may uncomment these lines
    // In addition, if the linked issue is closed, you can upgrade electron and uncomment these lines
    // try {
    //   await installVueDevtools()
    // } catch (e) {
    //   console.error('Vue Devtools failed to install:', e.toString())
    // }
  }

  appReady()
})

// Exit cleanly on request from parent process in development mode.
if (isDevelopment) {
  if (process.platform === 'win32') {
    process.on('message', data => {
      if (data === 'graceful-exit') {
        app.quit()
      }
    })
  } else {
    process.on('SIGTERM', () => {
      app.quit()
    })
  }
}

const appReady = async () => {
  if (app.dock) {
    app.dock.hide()
  }

  let trayImage = path.join(__static, 'icons', 'icon.png')

  tray = new Tray(trayImage)

  // tray.on('click', clicked.bind(this))
  tray.on('click', clicked)
  tray.on('double-click', clicked)

  windowPosition = getWindowPosition(tray)

  await createWindow()
}

const createWindow = async () => {
  win = new BrowserWindow({
    width: 350,
    height: 400,
    show: false,
    frame: false,
    webPreferences: {
      nodeIntegration: true,
    },
  })

  positioner = new Positioner(win)

  win.on('blur', () => {
    if (!win) {
      return
    }

    hideWindow()
  })

  win.on('closed', () => {
    win = null
  })

  if (process.env.WEBPACK_DEV_SERVER_URL) {
    // Load the url of the dev server if in development mode
    await win.loadURL(process.env.WEBPACK_DEV_SERVER_URL)
    // if (!process.env.IS_TEST) win.webContents.openDevTools()
  } else {
    createProtocol('app')
    // Load the index.html when not in development
    await win.loadURL('app://./index.html')
  }
}

const clicked = async (event, bounds) => {
  if (event && (event.shiftKey || event.ctrlKey || event.metaKey)) {
    return hideWindow()
  }
  if (win && win.isVisible()) {
    return hideWindow()
  }

  cachedBounds = bounds || cachedBounds
  await showWindow(cachedBounds)
}

const showWindow = async trayPos => {
  if (!tray) {
    throw new Error('Tray should have been instantiated by now')
  }

  if (!win) {
    await createWindow()
  }

  if (!win) {
    throw new Error('Window has been initialized just above. qed.')
  }

  if (trayPos && trayPos.x !== 0) {
    // Cache the bounds
    cachedBounds = trayPos
  } else if (cachedBounds) {
    // Cached value will be used if showWindow is called without bounds data
    trayPos = cachedBounds
  } else if (tray.getBounds) {
    // Get the current tray bounds
    trayPos = tray.getBounds()
  }

  // Default the window to the right if `trayPos` bounds are undefined or null.
  let noBoundsPosition = null
  if (
    (trayPos === undefined || trayPos.x === 0) &&
    windowPosition &&
    windowPosition.startsWith('tray')
  ) {
    noBoundsPosition = process.platform === 'win32' ? 'bottomRight' : 'topRight'
  }

  const position = positioner.calculate(
    noBoundsPosition || windowPosition,
    trayPos,
  )

  const x = position.x
  let y = position.y

  if (process.platform === 'win32') {
    if (trayPos && windowPosition && windowPosition.startsWith('bottom')) {
      y = trayPos.y + trayPos.height / 2 - win.getBounds().height / 2
    }
  }

  // `.setPosition` crashed on non-integers
  win.setPosition(Math.round(x), Math.round(y))
  win.show()
}

const hideWindow = () => {
  if (!win || !win.isVisible()) {
    return
  }

  win.hide()
}
