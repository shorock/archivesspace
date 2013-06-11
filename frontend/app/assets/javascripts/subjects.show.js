//= require embedded_search

$(function () {
  $('.merge-form .btn-cancel').on('click', function () {
    $('.merge-action').trigger("click");
  });

  // Override the default bootstrap dropdown behaviour here to
  // ensure that this modal stays open even when another modal is
  // opened within it.
  $(".merge-action").on("click", function(event) {
    event.preventDefault();
    event.stopImmediatePropagation();
    if ($(".merge-form")[0].style.display === "block") {
      // Hide it
      $(".merge-form").css("display", "");
    } else {
      // Show it
      $(".merge-form").css("display", "block");
    }
  });

  // Stop the modal from being hidden by clicks within the form
  $(".merge-form").on("click", function(event) {
    event.stopPropagation();
  });


  $(".merge-form .linker-wrapper .dropdown-toggle").on("click", function(event) {
    event.stopPropagation();
    $(this).parent().toggleClass("open");
  });


  $(".merge-form .merge-button").on("click", function(event) {
    var formvals = $(".merge-form").serializeObject();
    if (!formvals["merge[ref]"]) {
      $(".missing-ref-message", ".merge-form").show();
      event.preventDefault();
      event.stopImmediatePropagation();
      return false;
    } else {
      $(".missing-ref-message", ".merge-form").hide();
      $(this).data("form-data", {"ref": formvals["merge[ref]"]});
    }
  });
});
