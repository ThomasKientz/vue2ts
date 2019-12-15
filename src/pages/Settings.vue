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
        <v-toolbar-title>Settings</v-toolbar-title>
      </v-toolbar>
      <v-card-text class="pa-0">
        <v-container fluid>
          <v-text-field
            v-for="(email, index) of emails"
            :key="'email-' + index"
            :value="email"
            disabled
            readonly
            :label="'email address' + (index > 0 ? ' ' + (index + 1) : '')"
          >
            <template v-slot:append>
              <v-icon @click="remove(index)" color="red">{{
                mdiCloseCircle
              }}</v-icon>
            </template>
          </v-text-field>
          <v-btn
            v-if="!$store.state.token2"
            block
            outlined
            color="success"
            @click="
              dialog = false
              $router.push('/email')
            "
          >
            <v-icon left>{{ mdiPlus }}</v-icon>
            Add second email
          </v-btn>
          <div class="subtitle-2 mt-3">Email subject</div>
          <v-radio-group v-model="subjectMode">
            <v-radio label="Preview" value="preview" />
            <v-radio label="Custom" value="custom" />
          </v-radio-group>
          <v-text-field
            v-if="subjectMode == 'custom'"
            v-model="subjectText"
            label="Custom subject"
          />
          <v-text-field
            :value="fromText"
            label="From field"
            @change="fromText = $event"
          />
          <v-select
            :value="theme"
            label="Theme"
            :items="themeItems"
            @change="theme = $event"
          />
          <v-switch
            :input-value="autoClose"
            label="Auto close app after sending"
            @change="autoClose = $event"
          />
        </v-container>
      </v-card-text>
    </v-card>
  </v-dialog>
</template>

<script>
import { mdiCloseCircle, mdiPlus, mdiSwapVertical, mdiClose } from '@mdi/js'
import {
  FROM_TEXT_DEFAULT,
  SUBJECT_MODE_DEFAULT,
  SUBJECT_TEXT_DEFAULT,
} from '@/utils/defaults'

export default {
  props: {
    value: {
      type: Boolean,
    },
  },

  data: () => ({
    mdiCloseCircle,
    mdiPlus,
    mdiSwapVertical,
    mdiClose,
    subject: 'preview',
    themeItems: ['auto', 'light', 'dark'],
  }),

  watch: {
    theme(v) {
      this.$vuetify.theme.dark = v == 'dark'
    },
  },

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
        return this.$store.state.subjectMode || SUBJECT_MODE_DEFAULT
      },
      set(v) {
        return this.$store.commit('setSubjectMode', v)
      },
    },
    subjectText: {
      get() {
        return this.$store.state.subjectText || SUBJECT_TEXT_DEFAULT
      },
      set(v) {
        return this.$store.commit('setSubjectText', v)
      },
    },
    fromText: {
      get() {
        return this.$store.state.fromText || FROM_TEXT_DEFAULT
      },
      set(v) {
        return this.$store.commit('setFromText', v)
      },
    },
    theme: {
      get() {
        return this.$store.state.theme
      },
      set(v) {
        return this.$store.commit('setTheme', v)
      },
    },
    autoClose: {
      get() {
        return this.$store.state.autoClose
      },
      set(v) {
        return this.$store.commit('setAutoClose', v)
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
::v-deep header {
  height: calc(48px + var(--ion-safe-area-top)) !important;
  padding-top: var(--ion-safe-area-top);
}
</style>
