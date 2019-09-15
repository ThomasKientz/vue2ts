// import Storage from 'electron-store'
// const storage = new Storage()

export default process.env.IS_ELECTRON ? 'storage' : {
  get: window.localStorage.getItem,
  set: window.localStorage.setItem
}
