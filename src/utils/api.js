import axios from 'axios'
import { toast } from './toast'
import store from '@/store'
import { SUBJECT_TEXT_DEFAULT, FROM_TEXT_DEFAULT } from '@/utils/defaults'

const api = axios.create({
  baseURL: process.env.VUE_APP_API_URL,
})

api.interceptors.response.use(
  res => res,
  error => {
    if (!error.response) {
      // network error
      toast.error('Network error') // "Check connexion or check Boomerang status"
      return Promise.reject('handled in interceptor')
    } else {
      if (error.response.data.code)
        return Promise.reject({ code: error.response.data.code })

      const msg = error.response.data && error.response.data.message
      toast.error(msg || 'Server error') // "We are on it"
      return Promise.reject('handled in interceptor')
    }
  },
)

export const send = ({ token, message, attachments }) => {
  const subject =
    store.state.subjectMode === 'custom'
      ? store.state.subjectText || SUBJECT_TEXT_DEFAULT
      : message
      ? message.substring(0, 78).replace('\n', ' ')
      : attachments && attachments.length
      ? attachments
          .map(e => e.name)
          .join(', ')
          .substring(0, 78)
      : SUBJECT_TEXT_DEFAULT

  return api.post('/send', {
    token,
    message,
    attachments,
    fromText: store.state.fromText || FROM_TEXT_DEFAULT,
    subject,
  })
}

export const verifyEmail = ({ email, id }) => {
  return api.post('/verifyEmail', { email, id })
}

export const getToken = ({ email, id, code }) => {
  return api
    .post('/verifyCode', { email, id, code })
    .then(res => res && res.data)
}
