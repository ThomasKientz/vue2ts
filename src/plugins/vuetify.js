import Vue from 'vue'
import Vuetify from 'vuetify/lib'
import colors from 'vuetify/lib/util/colors'

Vue.use(Vuetify)

const mq = window.matchMedia('(prefers-color-scheme: dark)')

const vuetify = new Vuetify({
  icons: {
    iconfont: 'mdiSvg',
  },
  theme: {
    dark: mq.matches,
    themes: {
      dark: {
        primary: colors.blue.darken4,
        success: colors.green.darken3,
      },
    },
  },
})

export default vuetify
