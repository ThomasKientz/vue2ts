<template>
  <v-container>
    <v-text-field
      :value="$store.getters.email"
      disabled
      readonly
      label="email"
    />
    <v-btn block color="success" @click="$router.push('/email')">Edit</v-btn>
  </v-container>
</template>

<script>
export default {
  methods: {
    next() {},
  },
}
</script>
