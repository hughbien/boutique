var Boutique = {
  URL: "/boutique/",
  lists: {},
  subscribe: function(key) {
    var modal = this.buildModal(key);
    modal.show();
    return modal;
  },
  list: function(key, configs) {
    this.lists[key] = configs;
    var params = this.params("boutique");
    if (params) {
      params = params.split("/");
      var pAction = params[0];
      var pKey = params[1];
      var pId = params[2];
      var pSecret = params[3];
      if (key == pKey && (pAction == "confirm" || pAction == "unsubscribe")) {
        $.ajax(this.URL + pAction + "/" + key + "/" + pId + "/" + pSecret, {
          type: "POST",
          success: function() {
            var modal = Boutique.buildModal(key);
            var state = {confirm: "confirmed", unsubscribe: "unsubscribed"}[pAction];
            modal.removeClass("start subscribed confirmed unsubscribed");
            modal.addClass(state);
            modal.show();
          }
        });
      }
    }
  },
  buildModal: function(key) {
    var modal = $("#boutique-list-" + key);
    if (modal.length) { return modal; }

    var html = "";
    html += '<div class="boutique start">';
    html += '  <div class="boutique-overlay"></div>';
    html += '  <div class="boutique-modal">';
    html += '    <div class="boutique-close">x</div>';
    html += '  </div>';
    html += '</div>';

    modal = $(html);
    modal.find(".boutique-overlay,.boutique-close").click(function(e) {
      e.preventDefault();
      $(this).parents(".boutique").hide();
    });
    modal.attr("id", "boutique-list-" + key);

    var states = ["start", "subscribed", "confirmed", "unsubscribed"];
    for (var i = 0; i < states.length; i++) {
      var state = states[i];
      var head = $('<div class="boutique-head '+ state +'"></div>');
      var body = $('<div class="boutique-body '+ state +'"></div>');
      head.html(this.lists[key][state]["title"]);
      body.html(this.lists[key][state]["body"]);
      if (state == "start") {
        body.append(this.buildSubscribeForm(key));
      } else if (this.lists[key][state]["button"]) {
        body.append(this.buildButton(key, state));
      }
      modal.find(".boutique-modal").prepend(head, body);
    }
    $("body").append(modal);
    return modal;
  },
  buildSubscribeForm: function(key) {
    var html = "";
    html += '<form>';
    html += '  <p>';
    html += '    <input type="email" name="email" placeholder="Email Address" /><br>';
    html += '    <input type="submit" value="Subscribe Now" class="inlined" />';
    html += '  </p>';
    html += '</form>';
    var options = this.lists[key]["start"];

    var form = $(html);
    form.attr("action", Boutique.URL + "subscribe/" + key);
    if (options["button"]) { form.find("input[type=submit]").val(options["button"]); }
    form.submit(function(e) {
      e.preventDefault();
      form.find("input[type=submit]").
        attr("disabled", true).
        val("Loading...");
      $.ajax(form.attr("action"), {
        type: "POST",
        data: form.serialize(),
        error: function() {
          form.find("input[type=submit]").
            attr("disabled", false).
            val(options["button"] || "Subscribe Now");
        },
        success: function() {
          form.parents(".boutique").
            removeClass("start").
            addClass("subscribed");
        }
      });
    });
    return form;
  },
  buildButton: function(key, state) {
    var options = this.lists[key][state];
    var button = $('<a class="boutique-button"></a>');
    button.attr("href", options["href"]);
    button.html(options["button"]);
    var container = $("<p></p>");
    container.append(button);
    return container;
  },
  params: function(name) {
    return decodeURIComponent((new RegExp('[?|&]' + name + '=' + '([^&;]+?)(&|#|;|$)').exec(location.search) || [,""])[1].replace(/\+/g, '%20')) || null;
  }
};
