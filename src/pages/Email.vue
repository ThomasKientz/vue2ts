<template>
  <v-container>
    <!-- <v-text-field label="email" /> -->
    <v-btn @click="next()" block color="success">
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
      mdiArrowRight
    }
  },

  methods: {
    next () {
      this.$router.push('/code')
    }
  }

}
</script>
