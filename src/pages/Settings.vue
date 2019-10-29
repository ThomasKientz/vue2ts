<template>
  <v-dialog
    v-model="dialog"
    fullscreen
    hide-overlay
    transition="dialog-bottom-transition"
  >
    <v-card>
      <v-toolbar dark dense color="primary">
        <v-btn icon dark @click="dialog = false">
          <v-icon>{{ mdiClose }}</v-icon>
        </v-btn>
        <v-toolbar-title>Settings</v-toolbar-title>
      </v-toolbar>
      <v-container fluid>
        <v-text-field
          v-for="(email, index) of emails"
          :key="'email-' + index"
          :value="email"
          disabled
          readonly
          :label="'email address' + (emails.length > 1 ? ' ' + index : '')"
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
          label="subject"
        />
        <v-text-field v-model="fromText" label="From" />
      </v-container>
    </v-card>
  </v-dialog>
</template>

<script>
import { mdiCloseCircle, mdiPlus, mdiSwapVertical, mdiClose } from '@mdi/js'

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
