<template>
  <v-snackbar top :color="color" v-model="show" :timeout="timeout">
    {{ message }}
  </v-snackbar>
</template>

<script>
import { onToast } from '@/utils/toast'

export default {
  data() {
    return {
      show: false,
      color: 'success',
      timeout: null,
      message: '',
    }
  },

  created() {
    onToast(({ message, type }) => {
      this.message = message

      if (type == 'success') {
        this.color = 'success'
        this.timeout = 1000
      } else if (type == 'error') {
        this.color = 'error'
        this.timeout = 4000
      } else {
        return
      }

      this.show = true
    })
  },
}
</script>
