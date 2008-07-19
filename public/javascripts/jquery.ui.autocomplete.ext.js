/*
 * jQuery UI Autocomplete
 * version: 1.0 (1/2/2008)
 * @requires: jQuery v1.2 or later, dimensions plugin
 *
 * Dual licensed under the MIT and GPL licenses:
 *   http://www.opensource.org/licenses/mit-license.php
 *   http://www.gnu.org/licenses/gpl.html
 *
 * Copyright 2007 Yehuda Katz, Rein Henrichs
 */

(function($) {
  $.ui = $.ui || {};
  $.ui.autocomplete = $.ui.autocomplete || {};
  $.ui.autocomplete.ext = $.ui.autocomplete.ext || {};
  
  $.ui.autocomplete.ext.ajax = function(opt) {
    var ajax = opt.ajax;
    return { getList: function(input) { 
      $.getJSON(ajax, "val=" + input.val(), function(json) { input.trigger("updateList", [json]); }); 
    } };
  };
  
  $.ui.autocomplete.ext.templateText = function(opt) {
    var template = $.makeTemplate(opt.templateText, "<%", "%>");
    return { template: function(obj) { return template(obj); } };
  };
  
})(jQuery);
