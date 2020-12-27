$(function(){
  $(document).on('change','input[type="file"]', function(){
    var file = this.files[0];
    $(this).parents('label').nextAll('.form-file-name').text(file.name);
  });
});
