import EventBus from '@/utils/event-bus'

export const toast = {
  success: message => EventBus.$emit('toast', { message, type: 'success' }),
  error: message =>
    EventBus.$emit('toast', {
      message: message || 'Oops, an error occured...',
      type: 'error',
    }),
  warning: message => EventBus.$emit('toast', { message, type: 'warning' }),
}

export const onToast = cb =>
  EventBus.$on('toast', toast => {
    cb(toast)
  })
