<template>
  <v-container class="fill-height flex-column">
    <div style="min-width: 100% !important;" class="flex-grow-1">
      <div style="height: 100%;">
        <textarea v-model="message" placeholder="Write something..."></textarea>
      </div>
    </div>
    <v-btn class="flex-grow-0" @click="send()" block color="success">
      Send
      <v-icon right>{{ mdiSend }}</v-icon>
    </v-btn>
  </v-container>
</template>

<script>
import { mdiSend } from '@mdi/js'

export default {
  data() {
    return {
      mdiSend,
      message: null,
    }
  },

  methods: {
    send() {
      console.log('email : ', this.$store.email)
    },
  },
}
</script>

<style lang="scss" scoped>
textarea {
  resize: none;
  width: 100%;
  height: 100%;
}
</style>
