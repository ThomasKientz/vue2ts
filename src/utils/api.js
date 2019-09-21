import axios from 'axios'

const api = axios.create({
  baseURL: process.env.VUE_APP_API_URL || 'http://localhost:3000',
})

export const verifyEmail = ({ email, id }) => {
  return api.post('/verifyEmail', { email, id })
}

export const getToken = ({ email, id, code }) => {
  return api
    .post('/verifyCode', { email, id, code })
    .then(res => res && res.data)
}
