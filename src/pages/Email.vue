<template>
  <v-container>
    <v-text-field v-model="email" label="email" />
    <v-btn @click="save()" block color="success">
      Next
      <v-icon right>{{ mdiArrowRight }}</v-icon>
    </v-btn>
  </v-container>
</template>

<script>
import { mdiArrowRight } from '@mdi/js'
import { verifyEmail } from '@/utils/api'

export default {
  name: 'email',

  data() {
    return {
      email: null,
      mdiArrowRight,
    }
  },

  methods: {
    save() {
      const randomId = Math.floor(Math.random() * Math.floor(1000))
      verifyEmail({ email: this.email, id: randomId })
        .then(() => {
          this.$router.push({
            path: 'code',
            query: { id: randomId, email: this.email },
          })
        })
        .catch(e => {
          console.error(e)
        })
    },
  },
}
</script>
