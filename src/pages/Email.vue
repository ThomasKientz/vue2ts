<template>
  <v-container>
    <v-text-field v-model="email" label="email" />
    <v-btn @click="save()" block color="success">
      Next
      <v-icon right>{{mdiArrowRight}}</v-icon>
    </v-btn>
  </v-container>
</template>

<script>
import { mdiArrowRight } from '@mdi/js'

export default {
  name: 'email',

  data () {
    return {
      email: null,
      mdiArrowRight
    }
  },

  methods: {
    save () {
      console.log('')
      this.$store.set.email(this.email)
      this.$router.push('/send')
    }
  }

}
</script>
