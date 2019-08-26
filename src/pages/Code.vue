<template>
  <v-container>
    <v-btn @click="next()" block color="success">
      Previous
    </v-btn>
  </v-container>
</template>

<script>
export default {
  data () {
    return {
    }
  },

  methods: {
    next () {
      this.$router.go(-1)
    }
  }

}
</script>
