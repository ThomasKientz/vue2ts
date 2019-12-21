<template>
  <v-app>
    <Toast />
    <v-navigation-drawer v-model="drawer" width="200" app>
      <v-list dense>
        <v-list-item @click="show('settings')">
          <v-list-item-action>
            <v-icon>{{ mdiSettings }}</v-icon>
          </v-list-item-action>
          <v-list-item-content>
            <v-list-item-title>Settings</v-list-item-title>
          </v-list-item-content>
        </v-list-item>
        <v-list-item @click="show('feedback')">
          <v-list-item-action>
            <v-icon>{{ mdiHeart }}</v-icon>
          </v-list-item-action>
          <v-list-item-content>
            <v-list-item-title>Feedback</v-list-item-title>
          </v-list-item-content>
        </v-list-item>
      </v-list>
    </v-navigation-drawer>
    <v-app-bar
      dense
      :color="$vuetify.theme.isDark ? 'dark' : 'primary'"
      dark
      app
    >
      <v-app-bar-nav-icon
        v-if="$route.meta.menuButton"
        @click.stop="drawer = !drawer"
      >
        <v-icon>{{ mdiMenu }}</v-icon>
      </v-app-bar-nav-icon>
      <v-app-bar-nav-icon
        v-if="$route.meta.backButton && $store.state.token1"
        @click.stop="$router.go(-1)"
      >
        <v-icon>{{ mdiArrowLeft }}</v-icon>
      </v-app-bar-nav-icon>

      <v-toolbar-title class="subTitle pl-2">
        <span>{{ $route.meta.name }}</span>
      </v-toolbar-title>
    </v-app-bar>

    <v-content>
      <router-view />
      <settings v-model="showSettings" />
      <feedback v-model="showFeedback" />
    </v-content>
    <rate-dialog v-model="showRate" />
  </v-app>
</template>

<script>
import { mdiMenu, mdiSettings, mdiArrowLeft, mdiHeart } from '@mdi/js'
import Toast from '@/components/toast'
import { Plugins, Capacitor } from '@capacitor/core'
const { SplashScreen, App, StatusBar } = Plugins
import { mapState } from 'vuex'

export default {
  name: 'App',

  components: {
    Toast,
    Settings: () => import('@/pages/Settings'),
    Feedback: () => import('@/pages/Feedback'),
    RateDialog: () => import('@/components/rateDialog'),
  },

  created() {
    if (this.$store.state.theme == 'dark') this.$vuetify.theme.dark = true
  },

  mounted() {
    if (Capacitor.isNative) {
      SplashScreen.hide()
      StatusBar.show()
    }

    this.initAutoTheme()
  },

  data: () => ({
    drawer: false,
    mdiSettings,
    mdiArrowLeft,
    mdiHeart,
    mdiMenu,
    showSettings: false,
    showFeedback: false,
    showRate: false,
  }),

  computed: {
    ...mapState(['theme']),
  },

  methods: {
    initAutoTheme() {
      const mq = window.matchMedia('(prefers-color-scheme: dark)')

      // 'addEventListener' function is not compatible with iOS safari
      mq.addListener(e => {
        if (this.theme == 'auto') this.$vuetify.theme.dark = e.matches
      })

      App.addListener('appStateChange', state => {
        if (this.theme == 'auto')
          this.$vuetify.theme.dark = state.isActive && mq.matches
      })
    },
    show(view) {
      if (view == 'settings') {
        this.showSettings = true
      } else this.showFeedback = true

      this.drawer = false
    },
  },
}
</script>

<style lang="scss">
body {
  touch-action: manipulation;
}

.toasted-container .toasted {
  font-family: 'Roboto', sans-serif;
}

.v-content {
  flex: 1 0 0px !important;
  padding: 0px !important;
}

.v-app-bar.v-app-bar--fixed {
  position: static !important;
  flex: 0 0 calc(48px + var(--ion-safe-area-top)) !important;
  padding-top: var(--ion-safe-area-top);
}

.v-navigation-drawer {
  padding-top: var(--ion-safe-area-top);
}

.v-snack--top {
  padding-top: var(--ion-safe-area-top);
}
</style>
