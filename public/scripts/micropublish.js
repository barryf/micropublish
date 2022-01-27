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

	function getLocation(callback) {
		navigator.geolocation.getCurrentPosition(function(position) {
			var latitude = (Math.round(position.coords.latitude * 100000) / 100000);
			var longitude = (Math.round(position.coords.longitude * 100000) / 100000);
			var accuracy = (Math.round(position.coords.accuracy * 100000) / 100000);

			callback(latitude, longitude, accuracy)

		}, function(err){
			if(err.code == 1) {
				alert("The website was not able to get permission");
			} else if(err.code == 2) {
				alert("Location information was unavailable");
			} else if(err.code == 3) {
				alert("Timed out getting location");
			}
		})
	}

	$('#find_location').on('click', function() {
		getLocation(function (latitude, longitude) {
			$("#latitude").val(latitude);
			$("#longitude").val(longitude);
		})
		return false
	});

	if ($('#auto_location').length) {
		function getAutoLocation () {
			return localStorage.getItem('autoLocation') === 'true'
		}

		function fillLocation() {
			if (!getAutoLocation()) {
				return
			}

			getLocation(function(latitude, longitude, accuracy) {
				$('#location').val(`geo:${latitude},${longitude};u=${accuracy}`)
			})
		}

		$('#auto_location').prop('checked', getAutoLocation())

		$('#auto_location').on('change', function(event) {
			localStorage.setItem('autoLocation', event.target.checked)
			fillLocation()
		})

		fillLocation()
	}

	$('#upload_photo').on('click', function() {
		$('#photo_file').click()
	});

	$('#photo_file').on('change', function(event) {
		var fd = new FormData();
		var files = event.target.files[0];
		fd.append('file', files);

		$.ajax({
			url: '/media',
			type: 'post',
			data: fd,
			contentType: false,
			processData: false,
			success: function(response){
				let val = $('#photo').val() + '\n' + response
				val = val.trim()
				$('#photo').val(val)
				$('#photo').attr('rows', val.split('\n').length || 1)
			},
			error: function(xhr, desc, error) {
				alert(xhr.responseText);
			}
		});
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

