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

	function count_chars(id) {
     $('#' + id + '_count').html(
			 "<span class=\"fa fa-twitter\"></span> " +
			 twttr.txt.getTweetLength(
				 $('#' + id).val()
			 )
		 );
	}
	if ($('#content_count').length) {
		$('#content').on('change keyup', function() { count_chars('content'); });
		count_chars('content');
	}
  if ($('#summary_count').length) {
    $('#summary').on('change keyup', function() { count_chars('summary'); });
    count_chars('summary');
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

  $('#find_location').on('click', function() {
    navigator.geolocation.getCurrentPosition(function(position) {

      var latitude = (Math.round(position.coords.latitude * 100000) / 100000);
      var longitude = (Math.round(position.coords.longitude * 100000) / 100000);
      $("#latitude").val(latitude);
      $("#longitude").val(longitude);

    }, function(err){
      if(err.code == 1) {
        alert("The website was not able to get permission");
      } else if(err.code == 2) {
        alert("Location information was unavailable");
      } else if(err.code == 3) {
        alert("Timed out getting location");
      }
    });
    return false
  });

});

$.fn.countdown = function(duration) {
  var container = $(this[0]);
  var countdown = setInterval(function() {
    if (--duration) {
      container.html(
        "Redirecting in " + duration + " second" + (duration != 1 ? "s" : "")
      );
    } else {
      container.html("Redirecting&hellip;");
      clearInterval(countdown);
      document.location = document.location;
    }
  }, 1000);
}

