<template>
  <v-container>
    <v-text-field v-model="code" label="code" />
    <v-btn @click="next()" block color="success">
      Next
      <v-icon right>{{ mdiArrowRight }}</v-icon>
    </v-btn>
  </v-container>
</template>

<script>
import { mdiArrowRight } from '@mdi/js'
import { getToken } from '@/utils/api'

export default {
  data() {
    return {
      mdiArrowRight,
      code: null,
    }
  },

  methods: {
    next() {
      getToken({
        email: this.$route.query.email,
        id: this.$route.query.id,
        code: this.code,
      }).then(async token => {
        await this.$store.dispatch('saveToken', token)
        this.$router.replace('/send')
      })
    },
  },
}
</script>
