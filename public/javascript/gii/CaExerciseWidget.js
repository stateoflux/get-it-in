define(["dojo/_base/declare", "dijit/_WidgetBase", "dijit/_TemplatedMixin",
    "dojo/text!./CaExerciseWidget/templates/CaExerciseWidget.html"],
  function(declare, WidgetBase, TemplatedMixin, template) {
    return declare([WidgetBase, TemplatedMixin], {
      exercise_name: "blank",
      duration: "0",
      distance: "0",
      calories: "0",
      //repText: "reps",
      templateString: template,
      baseClass: "caExerciseWidget",

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
