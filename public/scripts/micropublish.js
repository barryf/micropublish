$(function() {

	$('#preview').on('click', function() {
		$('#preview-modal').modal();
		$('#preview-content').html("");
    $.ajax({
			data: $('#form').serialize(),
			type: 'post',
			url: $('#form').attr('action') + "?_preview=1",
			success: function(data) {
				var content = "<pre>" + data + "</pre>";
				$('#preview-content').html(content);
      },
			error: function(xhr, desc, error) {
				var content = "<div class=\"alert alert-danger\">" + xhr.responseText +
					"</div>"
				$('#preview-content').html(content);
			}
		});
		return false
	});

	function count_content() {
     $('#content_count').html(
			 "<span class=\"fa fa-twitter\"></span> " +
			 twttr.txt.getTweetLength(
				 $('#content').val()
			 )
		 );
	}
	if ($('#content_count').length) {
		$('#content').on('change keyup', count_content);
		count_content();
	}

	$('#helpable-toggle').on('click', function() {
		$('.helpable .help-block').slideToggle();
	});

	$('#settings-format-form input').on('click', function() {
		$('#settings-format-form').submit();
	});

	// progressively enhance if js is available
	$('.helpable .help-block').css({ display: "none" });
	$('#content-html').css({ display: "none" });
	$('trix-editor').css({ display: "block" });

});