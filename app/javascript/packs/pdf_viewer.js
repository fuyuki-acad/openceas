import Vue from 'vue'
import bootstrap from '../plugins/bootstrap'
import vueLoadingOverlay from '../plugins/vue-loading-overlay'
import fontawesome from '../plugins/fontawesome'

import PdfJsView from '../src/pdf/pdf-view.vue'


document.addEventListener('DOMContentLoaded', () => {
  new Vue({
    el: '#pdf_viewer',
    render: h => h(PdfJsView, { props: document.getElementById('pdf_viewer').dataset })
  })
})