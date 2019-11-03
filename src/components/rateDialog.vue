<template>
  <v-dialog v-model="show">
    <v-card>
      <!-- <v-card-title class="title text-center d-block">
        Thanks !
      </v-card-title> -->
      <v-card-text class="text-center pa-4">
        <v-icon color="pink" size="70">{{ mdiHeart }}</v-icon>
        <div class="mt-3">Thank you for your support !</div>
      </v-card-text>
      <v-divider></v-divider>
      <v-btn block color="info" text>
        Close
      </v-btn>
    </v-card>
    <!-- <v-card>
      <v-card-title class="title text-center d-block">
        Enjoying Boomerang ?
      </v-card-title>
      <v-card-text>
        <div></div>
        <div class="text-center">
          <p>Tap a star to rate it.</p>
          <v-rating
            x-large
            v-model="rating"
            color="yellow darken-3"
            background-color="grey darken-1"
          />
        </div>
      </v-card-text>
      <v-divider></v-divider>
      <v-btn block color="info" text>
        Later
      </v-btn>
      <v-divider></v-divider>
      <v-btn block color="error" text>Never ask me again</v-btn>
    </v-card> -->
  </v-dialog>
</template>

<script>
import { mdiHeart } from '@mdi/js'

export default {
  props: {
    value: {
      type: Boolean,
      required: true,
    },
  },

  data: () => ({
    rating: 0,
    mdiHeart,
  }),

  computed: {
    show: {
      get() {
        return this.value
      },
      set(v) {
        this.$emit('input', v)
      },
    },
  },
}
</script>
