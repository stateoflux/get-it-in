define(["dojo/_base/declare", "dijit/_WidgetBase", "dijit/_TemplatedMixin",
        "dojo/dom-class", "dojo/topic",
    "dojo/text!./StExInputWidget/templates/StExInputWidget.html"],
  function(declare, WidgetBase, TemplatedMixin, domClass, topic, template) {
    return declare([WidgetBase, TemplatedMixin], {
      // TODO: currently i will have to replicate this widget for the cardio exercise input
      // is it possible to have a base widget pull a specified template?
      ex_num: "0",
      //repText: "reps",
      templateString: template,
      baseClass: "stExInputWidget",

      // Validation Logic
      postCreate: function() {
        var inputNode = this.InputNode;

        // validate presence
        // for the case where user does not trigger the onblur event (no tabbing)
        topic.subscribe("checkPresence", function() {
          // presenceHandler();
        });

        this.connect(inputNode, "onblur", function(evt) {
          // presenceHandler();
          var valStat = this.valStat;
          if (inputNode.value == "") {
            updateValStat(valStat, "Input required", false);
          }
        });
        
        /* function presenceHandler() {
          var valStat = this.valStat;
          if (inputNode.value == "") {
            updateValStat(valStat, "Input required", false);
          }
        } */

        // validate format
        this.connect(inputNode, "onkeyup", function(evt) {
          var valStat = this.valStat;
          if(!/^[1-9]{1,3}$/.test(inputNode.value)) {
            updateValStat(valStat, "Wrong format", false);
            // Disable the add exercise & submit buttons
            // publish a disable message?

          }
          else {
            updateValStat(valStat, "OK", true);
          }
        });

        // Helper function to update the validation label
        function updateValStat(node, text, success) {
          node.innerHTML = text;
          if (success) {
            topic.publish("enableBtns");
            domClass.remove(node, "label-important");
            domClass.add(node, "label-success");
          }
          else {
            topic.publish("disableBtns");
            domClass.remove(node, "label-success");
            domClass.add(node, "label-important");
          }
          // reveal the validation status
          // TODO: use fade in 
          domClass.remove(node, "hidden");
        }
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
