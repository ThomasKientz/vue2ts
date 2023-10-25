<template>
  <v-container fluid>
    <v-window touchless v-model="activeStep">
      <v-window-item eager :key="1">
        <v-form ref="formEmail" @submit.prevent="next()">
          <v-text-field
            @keyup.enter="onEnter"
            :disabled="loading"
            validate-on-blur
            v-model.trim="email"
            type="email"
            label="email"
            :rules="emailRules"
            placeholder="email@domain.com"
            ref="input"
            autofocus
          />
          <p class="caption grey--text text--darken-2">
            We strongly value privacy and will <strong>never</strong> sell it.
          </p>
        </v-form>
      </v-window-item>

      <v-window-item eager :key="2">
        <div class="subtitle-1 text-center" style="line-height: 1.5;">
          Verification code sent to :
          <strong>{{ email }}</strong>
        </div>
        <div class="d-flex align-center mt-2">
          <v-icon color="warning">{{ mdiAlert }}</v-icon>
          <div class="caption ml-3">
            Please check your spams and whitelist the incoming address.
          </div>
        </div>
        <v-form ref="formCode" @submit.prevent="next()">
          <v-text-field
            validate-on-blur
            type="number"
            pattern="[0-9]*"
            ref="inputCode"
            v-intersect.quiet="onShow"
            v-model="code"
            :disabled="loading"
            :rules="codeRules"
            label="Code"
          />
        </v-form>
      </v-window-item>
    </v-window>

    <v-btn
      :loading="loading"
      :disabled="loading"
      @click="next()"
      block
      color="success"
    >
      {{ activeStep == 0 ? 'Next' : 'Validate' }}
      <v-icon v-show="activeStep == 0" right>{{ mdiArrowRight }}</v-icon>
    </v-btn>
    <v-btn
      v-if="activeStep > 0"
      :disabled="loading"
      @click="goBack()"
      class="mt-2"
      block
      text
    >
      <v-icon left>{{ mdiArrowLeft }}</v-icon>
      Back
    </v-btn>
  </v-container>
</template>

<script>
import { mdiArrowRight, mdiArrowLeft, mdiAlert } from '@mdi/js'
import { verifyEmail, getToken } from '@/utils/api'
import { Capacitor } from '@capacitor/core'
import { Keyboard } from '@capacitor/keyboard'

const emailFormat = /^[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?$/
const codeFormat = /^[0-9]{4}$/
const requiredRule = v => !!v || 'Required'

export default {
  name: 'email',

  data() {
    return {
      valid: null,
      email: null,
      code: null,
      randomId: null,
      mdiArrowRight,
      mdiArrowLeft,
      mdiAlert,
      loading: false,
      activeStep: 0,
      emailRules: [requiredRule, v => emailFormat.test(v) || 'Invalid format'],
      codeRules: [requiredRule, v => codeFormat.test(v) || 'Invalid'],
    }
  },

  watch: {
    code(v) {
      if (v && v.length == 4) {
        if (this.codeRules.every(rule => rule(v))) this.validate()
      }
    },
  },

  mounted() {
    Capacitor.getPlatform() == 'android' && Keyboard.show()
  },

  methods: {
    onShow() {
      setTimeout(() => {
        this.$refs.inputCode.focus()
        Capacitor.getPlatform() == 'android' && Keyboard.show()
      }, 300)
    },
    onEnter() {
      this.$refs.input.blur()
      this.next()
    },
    next() {
      return this.activeStep == 0 ? this.send() : this.validate()
    },
    validate() {
      if (this.loading || !this.$refs.formCode.validate()) return

      this.loading = true
      getToken({
        email: this.email,
        id: this.randomId,
        code: this.code,
      })
        .then(async token => {
          await this.$store.dispatch('saveToken', token)
          this.$router.replace('/send')
        })
        .catch(error => {
          if (error.code) {
            if (error.code == 'wrong_code') {
              this.$toast.error('Wrong code !')
            } else {
              console.error('unknown error code :', error.code)
              this.$toast.error()
            }
          }
          this.loading = false
        })
    },
    send() {
      if (this.loading || !this.$refs.formEmail.validate()) return

      this.loading = true
      this.randomId = Math.floor(Math.random() * Math.floor(1000))

      verifyEmail({ email: this.email, id: this.randomId })
        .then(res => {
          if (res.data && res.data.code) console.log('code :', res.data.code)
          this.activeStep++
          this.loading = false
        })
        .catch(error => {
          if (error.code) {
            console.error('unknown error code :', error.code)
            this.$toast.error()
          }
        })
        .finally(() => {
          this.loading = false
        })
    },
    goBack() {
      this.activeStep--
      this.$refs.formCode.reset()
    },
  },
}
</script>
