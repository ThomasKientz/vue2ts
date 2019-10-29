import Vue from 'vue'
import Router from 'vue-router'
import store from '@/store'

const router = new Router({
  mode: 'history',
  base: process.env.BASE_URL,
  routes: [
    {
      path: '/email',
      name: 'email',
      component: () => import('./pages/Email.vue'),
      meta: {
        name: 'Register an email address',
        menuButton: false,
        backButton: true,
      },
    },
    // {
    //   path: '/settings',
    //   name: 'settings',
    //   component: () => import('./pages/Settings.vue'),
    //   beforeEnter: (to, from, next) => {
    //     if (store.state.token1) next()
    //     else next('/')
    //   },
    // },
    {
      path: '/send',
      name: 'send',
      component: () => import('./pages/Send.vue'),
      beforeEnter: async (to, from, next) => {
        await store.restored

        if (store.state.token1) next()
        else next('/email')
      },
      meta: {
        name: 'Boomerang',
        menuButton: true,
        backButton: false,
      },
    },
    { path: '*', redirect: '/send' },
    { path: '/', redirect: '/send' },
  ],
})

const waitForStorageToBeReady = async (to, from, next) => {
  await store.restored
  next()
}
router.beforeEach(waitForStorageToBeReady)

export default router

Vue.use(Router)
