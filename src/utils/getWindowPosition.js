export function getWindowPosition(tray) {
  // macOS
  // Supports top taskbars
  if (process.platform === 'darwin') return 'trayCenter'

  // Linux
  // Supports top taskbars
  // TODO Support bottom taskbars too https://github.com/maxogden/menubar/issues/123
  if (process.platform === 'linux') return 'topRight'

  // Windows
  // Supports top/bottom/left/right taskbar, default bottom
  if (process.platform === 'win32') {
    const traySide = taskbarLocation(tray)

    // Assign position for menubar
    if (traySide === 'top') {
      return 'trayCenter'
    }
    if (traySide === 'bottom') {
      return 'trayBottomCenter'
    }
    if (traySide === 'left') {
      return 'trayBottomLeft'
    }
    if (traySide === 'right') {
      return 'bottomRight'
    }
  }
}

export function taskbarLocation(tray) {
  const trayBounds = tray.getBounds()

  // Determine taskbar location
  if (trayBounds.width !== trayBounds.height && trayBounds.y === 0) {
    return 'top'
  }
  if (trayBounds.width !== trayBounds.height && trayBounds.y > 0) {
    return 'bottom'
  }
  if (trayBounds.width === trayBounds.height && trayBounds.x < trayBounds.y) {
    return 'left'
  }
  if (trayBounds.width === trayBounds.height && trayBounds.x > trayBounds.y) {
    return 'right'
  }

  // By default, return 'bottom'
  return 'bottom'
}
