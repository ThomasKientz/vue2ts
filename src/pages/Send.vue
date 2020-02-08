<template>
  <v-container style="height: auto !important;" class="fill-height flex-column">
    <!-- flex: 1 1 0; fix for safari -->
    <div style="min-width: 100% !important; flex: 1 1 0;">
      <div style="height: 100%;" @dragover.prevent @drop.prevent="dropHandler">
        <textarea
          ref="textarea"
          :disabled="loading"
          v-model="message"
          placeholder="Write something..."
        ></textarea>
      </div>
    </div>
    <v-layout
      style="flex-grow: 0 !important; flex-shrink: 0 !important; width: 100%; height: auto;"
      align-center
      class="d-flex mb-2"
    >
      <v-spacer></v-spacer>
      <v-badge color="amber" :value="files.length">
        <template v-slot:badge>{{ files.length }}</template>
        <v-btn
          style="flex-grow: 0 !important; flex-shrink: 0 !important;"
          class="mr-0 ml-2 elevation-2"
          color="grey"
          fab
          small
          dark
          @click="onFilesButton()"
        >
          <v-icon>{{ mdiPaperclip }}</v-icon>
        </v-btn>
      </v-badge>
    </v-layout>
    <div style="width: 100%;">
      <v-row :no-gutters="!$store.state.token2" dense>
        <v-col :cols="$store.state.token2 ? 6 : 12">
          <v-btn
            :loading="loading == 1"
            :disabled="loading == 2"
            @click="send(1)"
            color="success"
            block
            >{{ $store.state.token2 ? $store.getters.getEmail(1) : 'Send' }}
            <v-icon v-show="!$store.state.token2" right>{{ mdiSend }}</v-icon>
            <template v-if="files.length" v-slot:loader>
              <v-progress-circular size="30" rotate="270" :value="progress" />
            </template>
          </v-btn>
        </v-col>
        <v-col cols="6" v-if="$store.state.token2">
          <v-btn
            :loading="loading == 2"
            :disabled="loading == 1"
            @click="send(2)"
            color="success"
            block
            >{{ $store.getters.getEmail(2) }}
            <template v-if="files.length" v-slot:loader>
              <v-progress-circular size="30" rotate="270" :value="progress" />
            </template>
          </v-btn>
        </v-col>
      </v-row>
    </div>
    <v-bottom-sheet v-model="showFiles">
      <v-list class="list pa-0" subheader dense>
        <template v-for="(file, n) in files">
          <v-list-item :key="'list-item-' + n">
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
        <v-btn @click="openInput()" block color="success">
          add
          <v-icon right>{{ mdiPlus }}</v-icon>
        </v-btn>
      </v-sheet>
    </v-bottom-sheet>
    <v-bottom-sheet v-model="showInputSelector">
      <v-list>
        <v-list-item
          @click="
            showInputSelector = false
            $refs.inputCamera.click()
          "
        >
          <v-list-item-icon>
            <v-icon>{{ mdiCamera }}</v-icon>
          </v-list-item-icon>
          <v-list-item-title>Camera</v-list-item-title>
        </v-list-item>
        <v-list-item
          @click="
            showInputSelector = false
            $refs.input.click()
          "
        >
          <v-list-item-icon>
            <v-icon>{{ mdiFolder }}</v-icon>
          </v-list-item-icon>
          <v-list-item-title>Chose from device</v-list-item-title>
        </v-list-item>
      </v-list>
    </v-bottom-sheet>
    <input
      ref="inputCamera"
      type="file"
      accept="image/*"
      capture="camera"
      v-show="false"
      @change="onInput"
    />
    <input
      ref="input"
      type="file"
      multiple
      accept="*"
      v-show="false"
      @change="onInput"
    />
  </v-container>
</template>

<script>
import {
  mdiSend,
  mdiPaperclip,
  mdiClose,
  mdiCloseCircle,
  mdiPlus,
  mdiCamera,
  mdiFolder,
} from '@mdi/js'
import { send } from '@/utils/api'
import { platform } from '@/utils'

const MAX_SIZE = 10000000

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
  let totalExceed = 0

  for (let i = 0; i < files.length; i++) {
    const file = files[i]

    if (file.size > MAX_SIZE) {
      totalExceed++
    } else {
      const dataUrl = await getDataUrl(file)

      filesArray.push({
        name: file.name,
        size: file.size,
        dataUrl,
      })
    }
  }

  return Promise.resolve({ filesArray, totalExceed })
}

export default {
  data: () => ({
    mdiSend,
    mdiPaperclip,
    mdiClose,
    mdiCloseCircle,
    mdiPlus,
    mdiCamera,
    mdiFolder,
    message: null,
    loading: false,
    showFiles: false,
    files: [],
    progress: 0,
    showInputSelector: false,
  }),

  mounted() {
    this.focus()
  },

  methods: {
    async addFiles(files) {
      const { filesArray, totalExceed } = await processFiles(files)

      if (totalExceed) {
        if (filesArray.length)
          this.$toast.error('Some files selected are too big (> 10 mB).')
        else this.$toast.error('The file selected is too big (> 10 mB)')
      }

      this.showFiles = false
      this.files.push(...filesArray)
    },
    async onInput(e) {
      const files = e.target.files

      this.addFiles(files).then(() => {
        this.$refs.input.value = ''
      })
    },
    async dropHandler(e) {
      const files = e.dataTransfer.files

      this.addFiles(files)
    },
    onFilesButton() {
      if (this.files.length === 0) {
        this.openInput()
      } else {
        this.showFiles = true
      }
    },
    openInput() {
      if (platform == 'android') {
        this.showInputSelector = true
      } else {
        this.$refs.input.click()
      }
    },
    focus() {
      if (document.activeElement === this.$refs.textarea) return
      setTimeout(() => {
        this.$refs.textarea.focus()
      }, 200)
    },
    send(id) {
      if (!(this.message || this.files.length) || this.loading) return

      const totalSize = this.files.reduce((acc, file) => {
        return acc + file.size
      }, 0)

      if (totalSize > MAX_SIZE) {
        this.$toast.error('Total files size must be less than 10mB')
        return
      }

      this.loading = id
      send({
        token: this.$store.state['token' + id],
        ...(this.message && { message: this.message }),
        ...(this.files.length && {
          attachments: this.files,
          progress: percentage => (this.progress = percentage),
        }),
      })
        .then(() => {
          this.message = null
          this.files = []
          this.$toast.success('Boomerang sent !')
          this.focus()

          this.$emit('send')
        })
        .catch(error => {
          if (error.code) {
            console.error('unknown error code :', error.code)
            this.$toast.error()
          } else {
            // error already handled in interceptor
          }
        })
        .finally(() => {
          this.loading = false
          this.progress = 0
        })
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

::v-deep .v-btn__content {
  overflow: hidden !important;
  text-overflow: ellipsis !important;
  width: 100% !important;
  display: block !important;
}

::v-deep .v-badge__badge {
  right: -8px !important;
  top: -8px !important;
}
</style>

<style>
.v-content__wrap {
  display: flex;
}
</style>
