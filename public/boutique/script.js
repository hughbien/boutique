var Boutique = {
  URL: "/boutique/",
  subscribe: function(key) {
    var modal = this.buildModal({
      id: "testing",
      head: "Join The Mailing List",
      body: this.buildSubscribeForm(key) });
    modal.show();
  },
  init: function() {
  },
  buildModal: function(options) {
    options = options || {};
    var html = "";
    html += '<div class="boutique">';
    html += '  <div class="boutique-overlay"></div>';
    html += '  <div class="boutique-modal">';
    html += '    <div class="boutique-close">x</div>';
    html += '    <div class="boutique-head"></div>';
    html += '    <div class="boutique-body"></div>';
    html += '  </div>';
    html += '</div>';

    var modal = $(html);
    modal.find(".boutique-overlay,.boutique-close").click(function(e) {
      e.preventDefault();
      $(this).parents(".boutique").hide();
    });
    if (options["id"]) { modal.attr("id", options["id"]); }
    if (options["head"]) { modal.find(".boutique-head").html(options["head"]); }
    if (options["body"]) { modal.find(".boutique-body").html(options["body"]); }
    $("body").append(modal);
    return modal;
  },
  buildSubscribeForm: function(key, options) {
    options = options || {};
    var html = "";
    html += '<form>';
    html += '  <p>';
    html += '    <input type="email" name="email" placeholder="Email Address" /><br>';
    html += '    <input type="submit" value="Subscribe Now" class="inlined" />';
    html += '  </p>';
    html += '</form>';

    var form = $(html);
    if (key) { form.attr("action", Boutique.URL + "subscribe/" + key); }
    if (options["submit"]) { form.find("input[type=submit]").val(options["submit"]); }
    form.submit(function(e) {
      e.preventDefault();
      $.post(form.attr("action"), form.serialize(), function(response) {
        console.log(response);
      });
    });
    return form;
  }
};
Boutique.init();
