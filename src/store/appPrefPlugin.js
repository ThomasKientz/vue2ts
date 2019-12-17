import { AppPreferences } from '@ionic-native/app-preferences'

let userPref
document.addEventListener('deviceready', async () => {
  userPref = AppPreferences.iosSuite('group.settings.boomerang')
})

export default store => {
  store.subscribe((mutation, state) => {
    const { fromText, subjectMode, subjectText, token1, token2 } = state

    if (!userPref) {
      throw new Error('App preferences not initialized')
    }

    userPref.store('fromText', fromText)
    userPref.store('subjectMode', subjectMode)
    userPref.store('subjectText', subjectText)
    userPref.store('token1', token1)
    userPref.store('token2', token2)
  })
}
