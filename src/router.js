import Vue from 'vue'
import Router from 'vue-router'
import store from '@/store'

Vue.use(Router)

export default new Router({
  mode: 'history',
  base: process.env.BASE_URL,
  routes: [
    {
      path: '/email',
      name: 'email',
      component: () => import('./pages/Email.vue'),
      meta: {
        hideMenu: true,
      },
    },
    {
      path: '/code',
      name: 'code',
      props: true,
      component: () => import('./pages/Code.vue'),
    },
    {
      path: '/send',
      name: 'send',
      component: () => import('./pages/Send.vue'),
      beforeEnter: (to, from, next) => {
        if (store.token) next()
        else next('/email')
      },
    },
    { path: '*', redirect: '/send' },
    { path: '/', redirect: '/send' },
  ],
})
