define(["dojo/_base/declare", "dijit/_WidgetBase", "dijit/_TemplatedMixin",
    "dojo/text!./CaExInputWidget/templates/CaExInputWidget.html"],
  function(declare, WidgetBase, TemplatedMixin, template) {
    return declare([WidgetBase, TemplatedMixin], {
      // TODO: currently i will have to replicate this widget for the cardio exercise input
      // is it possible to have a base widget pull a specified template?
      ex_num: "0",
      //repText: "reps",
      templateString: template,
      baseClass: "CaExInputWidget",

      // Debug messages
      /* constructor: function() {
        this.inherited(arguments);
        console.log("inside constructor");
      },
      postMixInProperties: function() {
        this.inherited(arguments);
        console.log("inside postMixinProps");
      },
      buildRendering: function() {
        this.inherited(arguments);
        console.log("inside buildRendering");
      },
      postCreate: function() {
        this.inherited(arguments);
        console.log("inside postCreate");
      } */
    });
});
