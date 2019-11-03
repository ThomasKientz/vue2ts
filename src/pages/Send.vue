<template>
  <v-container class="fill-height flex-column">
    <!-- flex: 1 1 0; fix for safari -->
    <div style="min-width: 100% !important; flex: 1 1 0;">
      <div style="height: 100%;" @dragover.prevent @drop.prevent="dropHandler">
        <textarea
          ref="textarea"
          :disabled="loading"
          @dblclick="paste()"
          v-model="message"
          placeholder="Write something..."
        ></textarea>
      </div>
    </div>
    <v-layout
      style="flex-grow: 0 !important; flex-shrink: 0 !important; width: 100%; height: auto;"
      align-center
      class="d-flex mb-3"
    >
      <v-spacer></v-spacer>
      <span v-show="files.length"
        >{{ files.length }} file{{ files.length && 's' }}</span
      >
      <v-btn
        style="flex-grow: 0 !important; flex-shrink: 0 !important;"
        class="mr-0 ml-2 elevation-2"
        color="grey"
        fab
        small
        dark
        @click="showFiles = true"
      >
        <v-icon>{{ mdiPaperclip }}</v-icon>
      </v-btn>
    </v-layout>
    <div style="width: 100%;">
      <v-row dense>
        <v-col>
          <v-btn
            :loading="loading == 1"
            :disabled="loading == 2"
            @click="send(1)"
            color="success"
            block
            >{{ $store.state.token2 ? $store.getters.getEmail(1) : 'Send' }}
            <v-icon v-show="!$store.state.token2" right>{{ mdiSend }}</v-icon>
          </v-btn>
        </v-col>
        <v-col v-if="$store.state.token2">
          <v-btn
            :loading="loading == 2"
            :disabled="loading == 1"
            @click="send(2)"
            color="success"
            block
            >{{ $store.getters.getEmail(2) }}
          </v-btn>
        </v-col>
      </v-row>
    </div>
    <v-bottom-sheet v-model="showFiles">
      <v-list class="list pa-0" subheader dense>
        <template v-for="(file, n) in files">
          <v-list-item :key="'list-item-' + n" @click="showFiles = false">
            <v-list-item-title>{{ file.name }}</v-list-item-title>
            <v-list-item-action>
              <v-icon @click.stop.prevent="files.splice(n, 1)" color="red">{{
                mdiCloseCircle
              }}</v-icon>
            </v-list-item-action>
          </v-list-item>
          <v-divider :key="'divider-' + n"></v-divider>
        </template>
      </v-list>
      <v-sheet tile class="pa-3 elevation-0">
        <v-btn @click="$refs.input.click()" block color="success">
          add
          <v-icon right>{{ mdiPlus }}</v-icon>
        </v-btn>
      </v-sheet>
    </v-bottom-sheet>
    <input type="file" ref="input" multiple v-show="false" @change="onInput" />
  </v-container>
</template>

<script>
import {
  mdiSend,
  mdiPaperclip,
  mdiClose,
  mdiCloseCircle,
  mdiPlus,
} from '@mdi/js'
import { send } from '@/utils/api'
import { closeApp } from '@/utils'

const getDataUrl = file => {
  return new Promise((resolve, reject) => {
    const reader = new FileReader()
    reader.onload = e => resolve(e.target.result)
    reader.onerror = e => reject(e)
    reader.readAsDataURL(file)
  })
}

const processFiles = async files => {
  const filesArray = []

  for (let i = 0; i < files.length; i++) {
    const file = files[i]

    const dataUrl = await getDataUrl(file)

    filesArray.push({
      name: file.name,
      size: file.size,
      type: file.type,
      dataUrl,
    })
  }

  return Promise.resolve(filesArray)
}

export default {
  data: () => ({
    mdiSend,
    mdiPaperclip,
    mdiClose,
    mdiCloseCircle,
    mdiPlus,
    message: null,
    loading: false,
    showFiles: false,
    files: [],
  }),

  mounted() {
    setTimeout(() => {
      this.$refs.textarea.focus()
    }, 500)
  },

  methods: {
    async onInput(e) {
      const files = e.target.files
      const processedFiles = await processFiles(files)
      this.showFiles = false
      this.files.push(...processedFiles)
    },
    async dropHandler(e) {
      const files = e.dataTransfer.files
      this.files.push(...(await processFiles(files)))
    },
    send(id) {
      if (!this.message || this.loading) return

      this.loading = id
      send({
        token: this.$store.state['token' + id],
        message: this.message,
        attachments: this.files,
      })
        .then(() => {
          this.message = null
          this.files = []
          this.$toast.success('Boomerang sent !')
          setTimeout(() => {
            closeApp()
          }, 1000)
        })
        .catch(error => {
          if (error.code) {
            console.error('unknown error code :', error.code)
            this.$toast.error()
          }
          closeApp()
        })
        .finally(() => (this.loading = false))
    },
    paste() {
      console.log('paste')
    },
  },
}
</script>

<style lang="scss" scoped>
textarea {
  resize: none;
  width: 100%;
  height: 100%;
  &:focus {
    outline: none !important;
  }
}

.list {
  max-height: 200px;
  overflow: auto;
}
</style>
