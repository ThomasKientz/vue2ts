<template>
  <v-container fluid>
    <v-window touchless v-model="activeStep">
      <v-window-item :key="1">
        <div class="text-center subtitle-1 my-2">
          What is your email address ?
        </div>
        <v-form ref="formEmail">
          <v-text-field
            :disabled="loading"
            validate-on-blur
            v-model.trim="email"
            type="email"
            label="email"
            :rules="emailRules"
            placeholder="john@doe.com"
            autofocus
          />
        </v-form>
      </v-window-item>

      <v-window-item :key="2">
        <div class="subtitle-1 text-center my-2" style="line-height: 1.5;">
          We have sent a verification email to :
          <strong>{{ email }}</strong>
        </div>
        <p class="body-2 text-center my-2">
          Check your spams and whitelist the incoming address.
        </p>
        <v-form ref="formCode">
          <v-text-field
            validate-on-blur
            type="text"
            pattern="[0-9]*"
            v-model="code"
            :disabled="loading"
            :rules="codeRules"
            label="Code"
            autofocus
          />
        </v-form>
      </v-window-item>
    </v-window>

    <v-btn
      :loading="loading"
      :disabled="loading"
      @click="activeStep == 0 ? send() : validate()"
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
import { mdiArrowRight, mdiArrowLeft } from '@mdi/js'
import { verifyEmail, getToken } from '@/utils/api'

const emailFormat = /^[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?$/
const codeFormat = /^[0-9]{4}$/
const requiredRule = v => !!v || 'Required'

export default {
  name: 'email',

  data() {
    return {
      valid: null,
      email: 'qsd@qsd.fr',
      code: null,
      randomId: null,
      mdiArrowRight,
      mdiArrowLeft,
      loading: false,
      activeStep: 1,
      emailRules: [
        requiredRule,
        v => emailFormat.test(v) || 'Invalid email address',
      ],
      codeRules: [requiredRule, v => codeFormat.test(v) || 'Invalid'],
    }
  },

  watch: {
    code(v) {
      if (v.length == 4) {
        if (this.codeRules.every(rule => rule(v))) this.validate()
      }
    },
  },

  methods: {
    validate() {
      if (!this.$refs.formCode.validate()) return

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
      if (!this.$refs.formEmail.validate()) return

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
