import './assets/main.css'
import '@openvue/openicons/openicons.css'

import { createApp } from 'vue'
import { createPinia } from 'pinia'
import PrimeVue from 'openvue/config'
import ToastService from 'openvue/toastservice'
import ConfirmationService from 'openvue/confirmationservice'
import Aura from '@openvue/themes/aura'
import { definePreset, palette } from '@openuxkit/styled'

import App from './App.vue'
import router from './router'
import { i18n } from './i18n'

// A soft, muted blue instead of Aura's default - palette() generates the
// full 50-950 shade ramp every component's tokens reference from this one
// base color.
const SoftBluePreset = definePreset(Aura, {
  semantic: {
    primary: palette('#5B8DEF'),
  },
})

const app = createApp(App)

app.use(createPinia())
app.use(router)
app.use(i18n)
app.use(PrimeVue, {
  theme: {
    preset: SoftBluePreset,
    options: {
      darkModeSelector: '.p-dark',
    },
  },
})
app.use(ToastService)
app.use(ConfirmationService)

app.mount('#app')
