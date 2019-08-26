import Vue from 'vue'
import Router from 'vue-router'

Vue.use(Router)

export default new Router({
  mode: 'history',
  base: process.env.BASE_URL,
  routes: [
    {
      path: '/email',
      name: 'email',
      component: () => import('./pages/Email.vue')
    },
    {
      path: '/code',
      name: 'code',
      component: () => import('./pages/Code.vue')
    },
    { path: '*', redirect: '/email' },
    { path: '/', redirect: '/email' }
  ]
})
