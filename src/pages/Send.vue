<template>
  <v-container class="fill-height flex-column">
    <div style="min-width: 100% !important;" class="flex-grow-1">
      <div style="height: 100%;">
        <textarea
          :disabled="loading"
          @dblclick="paste()"
          v-model="message"
          placeholder="Write something..."
        ></textarea>
      </div>
    </div>
    <v-btn
      :loading="loading"
      :disabled="loading"
      class="flex-grow-0"
      @click="send()"
      block
      color="success"
    >
      Send
      <v-icon right>{{ mdiSend }}</v-icon>
    </v-btn>
  </v-container>
</template>

<script>
import { mdiSend } from '@mdi/js'
import { send } from '@/utils/api'

export default {
  data() {
    return {
      mdiSend,
      message: null,
      loading: false,
    }
  },

  methods: {
    send() {
      if (!this.message) return

      this.loading = true
      send({ token: this.$store.state.token, message: this.message })
        .then(() => {
          this.$toast.success('Boomerang sent !')
        })
        .catch(error => {
          console.error(error)
          this.$toast.error('Oops, an error occured...')
        })
        .finally(() => (this.loading = false))
    },
    paste() {
      console.log('paste')
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
