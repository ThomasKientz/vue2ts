<template>
  <v-dialog
    v-model="dialog"
    fullscreen
    hide-overlay
    transition="dialog-bottom-transition"
    scrollable
  >
    <v-card>
      <v-toolbar style="flex-grow: 0;" dark dense color="primary">
        <v-btn icon dark @click="dialog = false">
          <v-icon>{{ mdiClose }}</v-icon>
        </v-btn>
        <v-toolbar-title>Feedback</v-toolbar-title>
      </v-toolbar>
      <v-card-text style="height: 100%;" class="pa-0">
        <v-container style="height: 100%;" class="fill-height flex-column">
          <div style="min-width: 100% !important; flex: 1 1 0;">
            <div style="height: 100%;">
              <textarea
                :disabled="loading"
                v-model="message"
                placeholder="Write something..."
              ></textarea>
            </div>
          </div>
          <div style="width: 100%;">
            <v-row dense>
              <v-col cols="12" :sm="12">
                <v-btn :loading="loading" @click="send(1)" color="success" block
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

export default {
  props: {
    value: {
      type: Boolean,
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
    emails() {
      if (this.$store.state.token1) {
        return this.$store.state.token2
          ? [this.$store.getters.getEmail(1), this.$store.getters.getEmail(2)]
          : [this.$store.getters.getEmail(1)]
      } else return []
    },
    subjectMode: {
      get() {
        return this.$store.state.subjectMode || 'preview'
      },
      set(v) {
        return this.$store.commit('setSubjectMode', v)
      },
    },
    subjectText: {
      get() {
        return this.$store.state.subjectText || 'New Boomerang'
      },
      set(v) {
        return this.$store.commit('setSubjectText', v)
      },
    },
    fromText: {
      get() {
        return this.$store.state.fromText || 'Me'
      },
      set(v) {
        return this.$store.commit('setFromText', v)
      },
    },
  },

  methods: {
    remove(index) {
      if (!this.$store.state.token2 && index == 0) {
        this.$router.replace('/email')
        this.dialog = false
      }
      this.$store.dispatch('removeToken', index + 1)
    },
  },
}
</script>

<style lang="scss" scoped>
textarea {
  resize: none;
  width: 100%;
  height: 100%;
  &:focus {
    outline: none !important;
  }
}
</style>
