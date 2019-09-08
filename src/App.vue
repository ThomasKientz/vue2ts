<template>
  <v-app>
    <v-navigation-drawer
      v-model="drawer"
      width="200"
      app
    >
      <v-list dense>
        <v-list-item @click="$router.push('/email')">
          <v-list-item-action>
            <v-icon>{{mdiSettings}}</v-icon>
          </v-list-item-action>
          <v-list-item-content>
            <v-list-item-title>Settings</v-list-item-title>
          </v-list-item-content>
        </v-list-item>
        <!-- <v-list-item @click="">
          <v-list-item-action>
            <v-icon>mdi-contact-mail</v-icon>
          </v-list-item-action>
          <v-list-item-content>
            <v-list-item-title>Contact</v-list-item-title>
          </v-list-item-content>
        </v-list-item> -->
      </v-list>
    </v-navigation-drawer>
    <v-app-bar dense color="primary" dark app>
      <v-app-bar-nav-icon v-show="!$route.meta.hideMenu" @click.stop="drawer = !drawer">
         <v-icon>{{mdiMenu}}</v-icon>
      </v-app-bar-nav-icon>

      <v-toolbar-title class="subTitle text-capitalize">
        <span>boomerang</span>
      </v-toolbar-title>
    </v-app-bar>

    <v-content>
      <router-view/>
    </v-content>
  </v-app>
</template>

<script>
import { mdiMenu, mdiSettings } from '@mdi/js'

export default {
  name: 'App',
  data: () => ({
    drawer: false,
    mdiSettings,
    mdiMenu
  })
}
</script>
