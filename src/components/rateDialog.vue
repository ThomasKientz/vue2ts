<template>
  <v-dialog v-model="show">
    <v-card>
      <v-card-title class="title text-center d-block">
        Enjoying Boomerang ?
      </v-card-title>
      <v-card-text>
        <div></div>
        <div class="text-center">
          <p>Tap a star to rate it.</p>
          <v-rating
            x-large
            @input="onRate"
            color="yellow darken-3"
            background-color="grey darken-1"
          />
        </div>
      </v-card-text>
      <v-divider></v-divider>
      <v-btn block color="info" text @click="onSkip">
        Later
      </v-btn>
      <v-divider></v-divider>
      <v-btn block color="error" text @click="onNever"
        >Never ask me again</v-btn
      >
    </v-card>
  </v-dialog>
</template>

<script>
import { mdiHeart } from '@mdi/js'
import { Plugins, Capacitor } from '@capacitor/core'
const { App } = Plugins
// #if process.env.IS_ELECTRON
import { shell } from 'electron'
// #endif

export default {
  props: {
    value: {
      type: Boolean,
      required: true,
    },
  },

  data: () => ({
    rating: 0,
    mdiHeart,
  }),

  computed: {
    show: {
      get() {
        return this.value
      },
      set(v) {
        this.$emit('input', v)
      },
    },
  },

  methods: {
    onRate(e) {
      this.$store.commit('setRating', e)
      if (e > 3) {
        if (Capacitor.platform === 'ios') {
          const url = `https://apps.apple.com/us/app/boomerang-mail-myself/id1154427984?action=write-review`
          App.openUrl({ url })
        } else if (Capacitor.platform === 'android') {
          // const url = `https://play.google.com/store/apps/details?id=com.boomerang.app`
          const url = `market://details?id=com.boomerang.app`
          return App.openUrl({ url })
        } else if (process.env.IS_ELECTRON && process.platform === 'darwin') {
          const url = `https://apps.apple.com/us/app/ringer-ringtone-maker/id402437824?action=write-review`
          shell.openExternal(url)
        } else {
          console.log('Capacitor.platform', Capacitor.platform)
          console.log('process.env.IS_ELECTRON', process.env.IS_ELECTRON)
          console.log('process.platform', process.platform)
          console.error('onRate error : unknown platform.')
        }

        this.show = false
      } else {
        this.$emit('rate', e)
        this.show = false
      }
    },
    onSkip() {
      this.$store.dispatch('skip')
      this.show = false
    },
    onNever() {
      this.$store.dispatch('neverAsk')
      this.show = false
    },
  },
}
</script>
