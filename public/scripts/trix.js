(() => {
  const mediaEndpointEnabled = document.querySelector("#content-html")?.dataset?.mediaEndpointEnabled !== undefined;
  const trixFileTools = document.querySelector(".trix-button-group--file-tools");

  if (!mediaEndpointEnabled && trixFileTools) {
    trixFileTools.style.display = "none";

    document.addEventListener("trix-file-accept", (event) => {
      event.preventDefault();
    })
  }

  function uploadFileAttachment(attachment) {
    uploadFile(attachment.file, setProgress, setAttributes);

    function setProgress(progress) {
      attachment.setUploadProgress(progress);
    }

    function setAttributes(attributes) {
      attachment.setAttributes(attributes);
    }
  }

  function uploadFile(file, progressCallback, successCallback) {
    var formData = createFormData(file);
    var xhr = new XMLHttpRequest();

    xhr.open("POST", '/media', true);

    xhr.upload.addEventListener("progress", function (event) {
      var progress = (event.loaded / event.total) * 100;
      progressCallback(progress);
    });

    xhr.addEventListener("load", function (event) {
      if (xhr.status == 200) {
        var attributes = {
          url: xhr.response,
          href: xhr.response + "?content-disposition=attachment",
        };
        successCallback(attributes);
      }
    });

    xhr.send(formData);
  }

  function createFormData(file) {
    var data = new FormData();
    data.append("Content-Type", file.type);
    data.append("file", file);
    return data;
  }

  if (!mediaEndpointEnabled) {
    return;
  }

  addEventListener("trix-attachment-add", (event) => {
    if (event.attachment.file) {
      uploadFileAttachment(event.attachment);
    }
  });
})();
