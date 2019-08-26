<template>
  <v-app>
    <v-app-bar dense color="primary" dark app>
      <v-toolbar-title class="subTitle text-capitalize">
        <span>boomerang</span>
      </v-toolbar-title>
    </v-app-bar>

    <v-content>
      <main>
        <transition :name="transitionName">
          <router-view/>
        </transition>
      </main>
    </v-content>
  </v-app>
</template>

<script>
export default {
  name: 'App',
  data: () => ({
    transitionName: ''
  }),

  watch: {
    $route (e) {
      console.log(e)
      this.transitionName = 'next'
    }
  }
}
</script>

<style lang="scss" scoped>
main {
  min-height: 100%;
  display: grid;
  grid-template: "main";
  flex: 1;
  position: relative;
  overflow: hidden;
  background-color: white;
}

main > * {
  grid-area: main; /* Transition: make sections overlap on same cell */
  flex: 1 1 auto;
  background-color: white;
  position: relative;
  height: 100vh; /* To be fixed */
}

main > :first-child {
  z-index: 1; /* Prevent flickering on first frame when transition classes not added yet */
}

$easing: cubic-bezier(0.32,0.72,0,1);

.next-leave-to {
  animation: leaveToLeft 540ms both $easing;
  z-index: 0;
}

.next-enter-to {
  animation: enterFromRight 540ms both $easing;
  z-index: 1;
}

.prev-leave-to {
  animation: leaveToRight 540ms both $easing;
  z-index: 1;
}

.prev-enter-to {
  animation: enterFromLeft 540ms both $easing;
  z-index: 0;
}

@keyframes leaveToLeft {
  from {
    transform: translateX(0);
  }
  to {
    transform: translateX(-25%);
    // filter: brightness(0.5);
  }
}

@keyframes enterFromLeft {
  from {
    transform: translateX(-25%);
    // filter: brightness(0.5);
  }
  to {
    transform: translateX(0);
  }
}

@keyframes leaveToRight {
  from {
    transform: translateX(0);
  }
  to {
    transform: translateX(100%);
  }
}

@keyframes enterFromRight {
  from {
    transform: translateX(100%);
  }
  to {
    transform: translateX(0);
  }
}
</style>
