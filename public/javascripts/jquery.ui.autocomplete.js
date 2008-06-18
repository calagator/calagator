/* jQuery Autocomplete
 * Version 1.0
 * Written by Yehuda Katz (wycats@gmail.com) and Rein Henrichs (reinh@reinh.com)
 * @requires jQuery v1.2, jQuery dimensions plugin
 *
 * Copyright 2007 Yehuda Katz, Rein Henrichs
 * Dual licensed under the MIT and GPL licenses:
 *   http://www.opensource.org/licenses/mit-license.php
 *   http://www.gnu.org/licenses/gpl.html
 *
 */

/*
 * @description Form autocomplete plugin using preloaded or Ajax JSON data source 
 *
 * @example $('input#user-name').autocomplete({list: ["quentin", "adam", "admin"]})
 * @desc Simple autocomplete with basic JSON data source
 *
 * @example $('input#user-name').autocomplete({ajax: "/usernames.js"})
 * @desc Simple autocomplete with Ajax loaded JSON data source
 *
 */
 

(function($) {
  
  $.ui = $.ui || {}; $.ui.autocomplete = $.ui.autocomplete || {}; var active;
    
  $.fn.autocompleteMode = function(container, input, size, opt) {
    var original = input.val(); var selected = -1; var self = this;
    
    $.data(document.body, "autocompleteMode", true);

    $("body").one("cancel.autocomplete", function() { 
      input.trigger("cancel.autocomplete"); $("body").trigger("off.autocomplete"); input.val(original); 
    });
    
    $("body").one("activate.autocomplete", function() {
      input.trigger("activate.autocomplete", [$.data(active[0], "originalObject")]); $("body").trigger("off.autocomplete");
    });
    
    $("body").one("off.autocomplete", function(e, reset) {
      container.remove();
      $.data(document.body, "autocompleteMode", false);
      input.unbind("keydown.autocomplete");
      $("body").add(window).unbind("click.autocomplete").unbind("cancel.autocomplete").unbind("activate.autocomplete");
    });
    
    // If a click bubbles all the way up to the window, close the autocomplete
    $(window).bind("click.autocomplete", function() { $("body").trigger("cancel.autocomplete"); });

    var select = function() {
      active = $("> *", container).removeClass("active").slice(selected, selected + 1).addClass("active");
      input.trigger("itemSelected.autocomplete", [$.data(active[0], "originalObject")]);     
      input.val(opt.insertText($.data(active[0], "originalObject")));
    };
    
    container.mouseover(function(e) {
      // If you hover over the container, but not its children, return
      if(e.target == container[0]) return;
      // Set the selected item to the item hovered over and make it active
      selected = $("> *", container).index($(e.target).is('li') ? $(e.target)[0] : $(e.target).parents('li')[0]); select();
    }).bind("click.autocomplete", function(e) {
      $("body").trigger("activate.autocomplete"); $.data(document.body, "suppressKey", false); 
    });
    
    input
      .bind("keydown.autocomplete", function(e) {
        if(e.which == 27) { $("body").trigger("cancel.autocomplete"); }
        else if(e.which == 13) { $("body").trigger("activate.autocomplete"); }
        else if(e.which == 40 || e.which == 9 || e.which == 38) {
          switch(e.which) {
            case 40: 
            case 9:
              selected = selected >= size - 1 ? 0 : selected + 1; break;
            case 38:
              selected = selected <= 0 ? size - 1 : selected - 1; break;
            default: break;
          }
          select();
        } else { return true; }
        $.data(document.body, "suppressKey", true);
      });
  };
  
  $.fn.autocomplete = function(opt) {
    
    opt = $.extend({}, {
      timeout: 1000,
      getList: function(input) { input.trigger("updateList", [opt.list]); },
      template: function(str) { return "<li>" + opt.insertText(str) + "</li>"; },
      insertText: function(str) { return str; },
      match: function(typed) { return this.match(new RegExp(typed)); },
      wrapper: "<ul class='jq-ui-autocomplete'></ul>"
    }, opt);

    if($.ui.autocomplete.ext) {
      for(var ext in $.ui.autocomplete.ext) {
        if(opt[ext]) {
          opt = $.extend(opt, $.ui.autocomplete.ext[ext](opt));
          delete opt[ext];
        }
    } }

    return this.each(function() {
  
      $(this)
        .keypress(function(e) {
          var typingTimeout = $.data(this, "typingTimeout");
          if(typingTimeout) window.clearInterval(typingTimeout);
                    
          if($.data(document.body, "suppressKey"))
            return $.data(document.body, "suppressKey", false);
          else if($.data(document.body, "autocompleteMode") && e.charCode < 32 && e.keyCode != 8 && e.keyCode != 46) return false;          
          else {
            $.data(this, "typingTimeout", window.setTimeout(function() { 
              $(e.target).trigger("autocomplete"); 
            }, opt.timeout));
          }
        })
        .bind("autocomplete", function() {
          var self = $(this);

          self.one("updateList", function(e, list) {
            list = $(list)
              .filter(function() { return opt.match.call(this, self.val()); })
              .map(function() {
                var node = $(opt.template(this))[0];
                $.data(node, "originalObject", this);
                return node; 
              });
          
            $("body").trigger("off.autocomplete");
          
            if(!list.length) return false;
          
            var container = list.wrapAll(opt.wrapper).parents(":last").children();
            
            var offset = self.offset();
          
            opt.container = container
              .css({top: offset.top + self.outerHeight(), left: offset.left})
              .appendTo("body");
          
            $("body").autocompleteMode(container, self, list.length, opt);
          });

          opt.getList(self);
        });

    });
  };
  
})(jQuery);
