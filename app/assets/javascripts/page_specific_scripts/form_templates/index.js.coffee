ProcureIo.PageSpecificScripts["form_templates#index"] = ->


$(document).on "ajax:beforeSend", ".js-preview-form-template", (e) ->
  $(".preview-column-wrapper").addClass 'loading'