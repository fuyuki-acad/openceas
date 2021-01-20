<template>
  <div id="app">

    <div class="pdf-viewer-navi">
      <div class="pull-left">
        <button id="prev" type="button" class="btn btn-dark" v-on:click="prev" :disabled="isPrevDisabled"><font-awesome-icon icon="arrow-up"/></button>
        <button id="next" type="button" class="btn btn-dark" v-on:click="next" :disabled="isNextDisabled"><font-awesome-icon icon="arrow-down"/></button>
        <span class="page">
          <input type="text" id="pageNumber" readonly="readonly" :value="page" /> / <input type="text" id="totalPage" readonly="readonly" :value="pageCount" />
        </span>
      </div>
    </div>

    <span id="pdf-viewer">
      <pdf
        class="pdf-viewer-canvas"
        :src="src"
        @num-pages="pageCount = $event"
        @page-loaded="loadedPdf($event)"
        :page="page"
      ></pdf>
    </span>

  </div>
</template>

<script>
import pdf from 'vue-pdf'

export default {
  components: {
    pdf,
  },
  props: {
    pdfFile: { type: String, default: '' }
  },
	data() {
		return {
      src: "",
      pdfDocument: null,
      pageCount: 0,
      page: 1,
      isPrevDisabled: true,
      isNextDisabled: true,
      loader: null,
		}
	},
	mounted() {
    this.loadPdf()
	},
  methods: {
    loadPdf: function() {
      this.loader = this.$loading.show()

      this.src = pdf.createLoadingTask(this.pdfFile)
      this.src.promise.then(pdfDocument => {
        this.pdfDocument = pdfDocument
        this.pageCount = pdfDocument.numPages

        if (this.pageCount > 1) this.isNextDisabled = false
      });
    },
    loadedPdf: function(page) {
      this.loader.hide()
    },
    next: function() {
      this.page++
      this.isPrevDisabled = (this.page == 1) ? true : false
      this.isNextDisabled = (this.page == this.pageCount) ? true : false
    },
    prev: function() {
      this.page--
      this.isPrevDisabled = (this.page == 1) ? true : false
      this.isNextDisabled = (this.page == this.pageCount) ? true : false
    },
  }
}
</script>

<style>
@import "./pdf-view.css"
</style>
