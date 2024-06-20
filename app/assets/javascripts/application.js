// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery.turbolinks
//= require rails-ujs
//= require turbolinks
//= require ckeditor/init
//= require_tree .
//= require bootstrap
//= require moment
//= require bootstrap-datetimepicker
//= require Chart.bundle
//= require chartkick
//= require jquery-ui/widgets/sortable
//= require jquery-tablesorter/jquery.tablesorter
/**
 * CEAS顔写真モジュール　新規作成
 * 顔写真のポップアップ
 */

this.imagePreview = function(){
	/* CONFIG */
	xOffset = 200;
	yOffset = 200;

	/* END CONFIG */
	$("a.preview").hover(function(e){
		this.t = this.title;
		this.title = "";
		var c = (this.t != "") ? "<br/>" + this.t : "";
		$("body").append("<p id='preview'><img src='"+ this.href +"' alt='Image preview' />"+ c +"</p>");
		$("#preview")
			.css("top",(e.pageY - xOffset) + "px")
			.css("left",(e.pageX + yOffset) + "px")
			.show();
	},
	function(){
		this.title = this.t;
//		$('#preview').remove();
		$('#preview').attr("id","").hide();
	});
	$("a.preview").mousemove(function(e){
		$("#preview")
			.css("top",(e.pageY - xOffset) + "px")
			.css("left",(e.pageX + yOffset) + "px");
	});
};

$(document).on('turbolinks:load', function () {
  imagePreview();
  $("a.anchor").on('click', function(e) {
    e.preventDefault();
    var link = $(this).attr('href').replace("#", "");
    smoothScrolling(link);
  });
});
