define(["dojo/dom-class", "dojo/query", "dojo/_base/declare",
    "dijit/_WidgetBase", "dijit/_TemplatedMixin",
    "dojo/text!./StExerciseWidget/templates/StExerciseWidget.html", "dojo/NodeList-dom"],
  function(domClass, query, declare, WidgetBase, TemplatedMixin, template) {
    return declare([WidgetBase, TemplatedMixin], {
      // exercise_name: "blank",
      sets: "0",
      reps: "0",
      //repText: "reps",
      templateString: template,
      baseClass: "stExerciseWidget",

      _setExName: function(ex_name) {
        var names = {
          pushups: "Push Ups",
          squats: "Squats",
          planks: "Planks"
        };

        this.exNameSpanNode.innerHTML = names[ex_name];
      },
      _setColor: function(ex_name) {
        var colors = {
          pushups: "red",
          squats: "yellow",
          planks: "purple"
        };
        console.log("color " + colors[ex_name]);
        domClass.add(this.exNameNode, ["ex-name-" + colors[ex_name], "rvs"]);
        // 3/20: .addClass has been moved to the dojo/Nodelist-dom resource
        // hmmm, for some reason, I'm getting a Type Error when I include the NodeList-dom resource
        // - wow! made an intersting discovery.  I think the sequence of arguments passed into the define
        // call back have to match the resources specified in the define array.  by me adding the
        // NodeList-dom resource adjacent to the dojo/query resource i inadvertantly added a "space"
        // between the query & declare arguments in the callback.  I moved the NodeList-dom resource to
        // the end of the array and now everything is fine.
        query("span", this.exDetailsNode).addClass("ex-details-" + colors[ex_name]);
      },

      postCreate: function() {
        this.inherited(arguments);
        this._setExName(this.exercise_name);
        this._setColor(this.exercise_name);
      }
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
