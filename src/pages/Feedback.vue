<template>
  <v-dialog
    v-model="dialog"
    fullscreen
    hide-overlay
    transition="dialog-bottom-transition"
    scrollable
  >
    <v-card>
      <v-toolbar
        style="flex-grow: 0;"
        dark
        dense
        :color="$vuetify.theme.isDark ? 'dark' : 'primary'"
      >
        <v-btn icon dark @click="dialog = false">
          <v-icon>{{ mdiClose }}</v-icon>
        </v-btn>
        <v-toolbar-title>Feedback</v-toolbar-title>
      </v-toolbar>
      <v-card-text style="height: 100%; display: flex;" class="pa-0">
        <v-container style="height: auto;" class="fill-height flex-column">
          <div style="min-width: 100% !important; flex: 1 1 0;">
            <div style="height: 100%;">
              <textarea
                :disabled="loading"
                v-model="message"
                placeholder="How can we improve Boomerang ?"
              ></textarea>
            </div>
          </div>
          <div style="width: 100%;">
            <v-row dense>
              <v-col cols="12" :sm="12">
                <v-btn :loading="loading" @click="send()" color="success" block
                  >Send
                  <v-icon v-show="!$store.state.token2" right>{{
                    mdiSend
                  }}</v-icon>
                </v-btn>
              </v-col>
            </v-row>
          </div>
        </v-container>
      </v-card-text>
    </v-card>
  </v-dialog>
</template>

<script>
import { mdiSend, mdiClose } from '@mdi/js'
import { sendFeedback } from '@/utils/api'

export default {
  props: {
    value: {
      type: Boolean,
    },
    rating: {
      type: Number,
      default: null,
    },
  },

  data: () => ({
    mdiSend,
    mdiClose,
    message: null,
    loading: false,
  }),

  computed: {
    dialog: {
      get() {
        return this.value
      },
      set(v) {
        this.$emit('input', v)
      },
    },
  },

  methods: {
    send() {
      if (!this.message || this.loading) return

      this.loading = true
      sendFeedback({
        message:
          this.rating !== null
            ? `(rate : ${this.rating}) ${this.message}`
            : this.message,
      })
        .then(() => {
          this.message = null
          this.$toast.success('Thanks !')
        })
        .catch(() => {})
        .finally(() => {
          this.loading = false
        })
    },
  },
}
</script>

<style lang="scss" scoped>
::v-deep header {
  height: 48px !important;
  height: calc(48px + var(--ion-safe-area-top)) !important;
  padding-top: var(--ion-safe-area-top);
}

textarea {
  resize: none;
  width: 100%;
  height: 100%;
  &:focus {
    outline: none !important;
  }
}
</style>
