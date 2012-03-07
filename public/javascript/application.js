require([
  // Effects
  "dojo/_base/fx", "dojo/fx",
  // Ajax
  "dojo/_base/xhr",
  // Utils
  "dojo/_base/array",
  // Events
  "dojo/on", "dojo/topic",
  // DOM operations
  "dojo/dom", "dojo/dom-construct", "dojo/dom-attr",
  // Dijit Modules
  // "dijit/layout/TabContainer",
  // "dijit/layout/ContentPane",
  // Charting Modules
  "dojox/charting/Chart", "dojox/charting/themes/Claro",
  "dojox/charting/plot2d/Lines", "dojox/charting/plot2d/Markers",
  "dojox/charting/axis2d/Default",
  // Dijit Parser
  "dojo/parser",
  "dojo/domReady!"],
  function(baseFx, fx, xhr, baseArray, on, topic, dom, domConstruct,
    domAttr, Chart, theme) {
    var workoutForm = dom.byId("workout-form");

    // Initialize exercise module counters
    // will call again when form is submitted
    function resetExCntr() {
      createExercise.st_cnt = 0;
      createExercise.ca_cnt = 0;
    }

    resetExCntr();

    //------------------------ UI ---------------------------------------------
    ///////////////////////////////////////////////////////////////////////////
    // create initial exercise modules
    domConstruct.place(createExercise("st"), dom.byId("st_ex"))
    domConstruct.place(createExercise("ca"), dom.byId("ca_ex"))

    // TODO: need to add a "add_exercise" button
    // that will create a new exercise module
    // going to move button outside of exercise module
    // makes more sense to have a single button
    // that is stacked underneath exercise modues.
    // DONE

    // TODO: DRY this up.
    var st_btn = domConstruct.create("button", { 
      className: "btn btn-success",
      innerHTML: "Add Exercise"
    }, dom.byId("st_ex"));

    var ca_btn = domConstruct.create("button", { 
      className: "btn btn-success",
      innerHTML: "Add Exercise"
    }, dom.byId("ca_ex"));

    


    // clear the workout log form
    // later, this function will have to revert the form back to it's default look (1 exercise)
    function backToDefault() {
      workoutForm.reset();

      //TODO: investigate how to remove the extra exercise modules?
      // - i added an id to each exercise module in the form "type_ex_number"
      // i will delete all exercise modules except for number 1
      // probably should fade out first then destroy?
      // DONE

      // TODO: Dry it up
      for (i = createExercise.st_cnt; i > 1; i--) {
        domConstruct.destroy("st_ex" + i);
      }
      for (i = createExercise.ca_cnt; i > 1; i--) {
        domConstruct.destroy("ca_ex" + i);
      }
    }



    // TODO: investigate using a accordion panels to handle the transition
    // from form submission to log report display
    //
    // wipe form up
    function wipeFormUp() {
      fx.wipeOut({ node: workoutForm }).play();
    }

    function createReport() {
      domConstruct.create("div", {
        style: {
          backgroundColor: "red",
          height: "300px"
          //opacity: 0
        }
      },
      workoutForm, "after")
    }



    // Submit handler
    on(workoutForm, "submit", function(evt) {
      var messageNode = dom.byId("message");

      evt.preventDefault();

      // create workout object.

      // add two hidden fields to form to indicate
      // how many of each exercise modules are present
      // TODO: DRY this up
      var st_hidden = domConstruct.create("input", null, workoutForm);
      domAttr.set(st_hidden, {
        type: "hidden",
        name: "st_cnt",
        value: createExercise.st_cnt
      });

      var ca_hidden = domConstruct.create("input", null, workoutForm);
      domAttr.set(ca_hidden, {
        type: "hidden",
        name: "ca_cnt",
        value: createExercise.ca_cnt
      });

      // Let's try the Deferred version
      // Hmmm.  Looks like the ioArgs object is not avail when you use the Deferred method.
      // Also, I really don't see the benefit of using deferreds, but of course I'm
      // still new at this.
      var def= xhr.post({
        url: "/",
        timeout: 5000,
        form: this,
      });

      def.then(function(response) {
          console.log("success! ", response)
          // handler should reset the form
          // need to investigate how to do that

          // book says that error handler should always return the response.  why?
          // - return a response if you plan on adding more callbacks to the deferred object
          // - from reading the "promises" article on Sitepen, the new Deferred object returns
          // a copy of the original return value, called a "promise".  This "promise" is
          // read-only and is unaffected and available to every callback in the chain.  Therefore,
          // there is no need to expicitly return the response.
          //return response;
          topic.publish("submitted");
        },
        function(error) {
          messageNode.innerHTML = "Ajax request failed!";
          console.log("post request failed");
          console.log(error);
        }
      );
      //)
      // how would I go about adding a new callback to the orig xhr that is only fired after
      // the successful callback returns? if possible, i can use this mechanism to request
      // the resulting workout log collection
      // wow! it worked.  what happens if the post request fails?
      // looks like it still executes to get request even though the post request fails.
      // can I inspect the status of the post request before issuing the get?
      // 
      // I wonder if the request for logs should be implemented via pub/sub?  the deferred
      // chaining seems overly complicated for this purpose, since the request for
      // logs does not depend on the return value of the post to the db.
      /*.then(function() {
        xhr.get({
          url: "/logs",
          handleAs: "json"
        })
        .then(function(jsonData) {
            console.log("request for logs succeeded", jsonData);
          },
          function(error) {
            messageNode.innerHTML = "logs request failed!";
            console.log("get request failed");
          }
        );
      });*/
    });

  //-----------------------------------------------------------------------------
  // I should extract this into a separate module
    // Exercise Module Generation
    function createExercise(exType) {
      // TODO:  investigate adding a counting mechanism
      // for each exercise module that is created.  
      // will have to reset count when form is submitted
      //

      var exercise = domConstruct.create("div");
      //var exercise = domConstruct.create("div", { className: "row-fluid exercise" });
      var cnt = 0;

      // Strength exercises require 3 control groups.  Cardio exercises require
      // control groups.
      var st_labels = ["Exercise", "Sets", "Reps"];
      var ca_labels = ["Exercise", "Duration", "Distance", "Calories"];

      if (exType === "st") {
        //createExercise.st_cnt++;
        cnt = ++createExercise.st_cnt;
        for (i = 0; i < 3; i++) {
          domConstruct.place(createCntrlGrp(exType, st_labels.shift()), exercise);
        }
      }
      else if (exType === "ca") {
        //createExercise.ca_cnt++;
        cnt = ++createExercise.ca_cnt;
        for (i = 0; i < 4; i++) {
          domConstruct.place(createCntrlGrp(exType, ca_labels.shift()), exercise);
        }
      }

      // create Control Group
      function createCntrlGrp (exType, lblName) {
        var cntrlGrp = domConstruct.create("div", { className: "control-group span3" });

        // Add units to label names where necessary
        var fullLabel = lblName;
        if (lblName === "Duration") {
          fullLabel = "Duration in Minutes";
        }
        else if (lblName === "Distance") {
          fullLabel = "Distance in Miles";
        }

        var lbl = domConstruct.create("label", {
          className: "control-label",
          innerHTML: fullLabel   // would like to make sure that text is capitalized
        }, cntrlGrp);
        domAttr.set(lbl, "for", exType + "_" + lblName.toLowerCase() + cnt);
        var cntrls = domConstruct.create("div", { className: "controls docs-input-sizes" }, cntrlGrp);

        // set createCntrl arguments based on exType & lblName
        var cntrlType = "text";
        var selOpts = null;

        if (exType === "st" && lblName.toLowerCase() === "exercise") {
          cntrlType = "select";
          selOpts = [
            { value: "pushups", html: "Push Ups"},
            { value: "squats", html: "Squats"},
            { value: "planks", html: "Planks"}
          ];
        }
        else if (lblName.toLowerCase() === "sets") {
          cntrlType = "select";
          selOpts = [
            { value: "1", html: "1"},
            { value: "2", html: "2"},
            { value: "3", html: "3"},
            { value: "4", html: "4"},
            { value: "5", html: "5"},
            { value: "6", html: "6"}
          ];
        }
        else if (lblName.toLowerCase() === "exercise") {
          cntrlType = "select";
          selOpts = [
            { value: "elliptical", html: "Elliptical"},
            { value: "cycle", html: "Cycle"},
            { value: "treadmill", html: "Treadmill"}
          ];
        }

        domConstruct.place(createCntrl(cntrlType, exType, lblName.toLowerCase(), selOpts), cntrls);
        return cntrlGrp;
      }

      // create Control
      function createCntrl(cntrlType, exType, cntrlName, selOpts) {
        // should validate arguments
        var cntrl = null;
        /* var cnt = createExercise.st_cnt;

        if (exType === "ca") {
          cnt = createExercise.ca_cnt;
        }*/

        if (cntrlType === "text") {
          var cntrl = domConstruct.create("input");
          domAttr.set(cntrl, {
            type: "input",
            className: "span1",
            id: exType + "_" + cntrlName + cnt,
            name: exType + "_" + cntrlName + cnt
          });
        }
        else if (cntrlType === "select") {
          var cntrl = domConstruct.create("select");
          var width = "span1";

          if (cntrlName === "exercise") {
            width = "span2";
          }
          domAttr.set(cntrl, {
            className: width,
            id: exType + "_" + cntrlName + cnt,
            name:  exType + "_" + cntrlName + cnt
          });
          // create and attach option nodes
          baseArray.forEach(selOpts, function(option) {
            var opt = domConstruct.create("option", null, cntrl);
            domAttr.set(opt, {
              value: option.value,
              innerHTML: option.html
            })
          });
        }
        return cntrl;
      }
      
      domAttr.set(exercise, {
        className: "row-fluid exercise",
        id: exType + "_ex" + cnt
      });
      return exercise;
    }

  //-----------------------------------------------------------------------------


    // Chart Generation
    function createChart(chartData) {
      //var chartData = [10000,9200,11811,12000,7662,13887,14200,12222,12000,10009,11288,12099];
      var chart = new Chart("chartNode");

      chart.setTheme(theme);
      chart.addPlot("default", {
        type: "Markers"
      });
      chart.addAxis("x");
      chart.addAxis("y", { min: 0, max: 20, vertical: true, fixLower: "major", fixUpper: "major" });
      chart.addSeries("durationThusFar", chartData);
      chart.render();
    }
    

    //---------------------- EVENTS --------------------------------------------
    ////////////////////////////////////////////////////////////////////////////
    // --------------------------------------------------------------------------
    // "submitted" subscribers
    // --------------------------------------------------------------------------
    topic.subscribe("submitted", function() {
      xhr.get({
        url: "/logs",
        handleAs: "json"
      })
      .then(function(jsonData) {
        var strength = [];
        var cardio = [];
        baseArray.forEach(jsonData, function(log) {
          baseArray.forEach(log.exercises, function(exercise) {
            if (exercise._type === "StrengthExercise") {
              strength.push(exercise.sets * exercise.reps);
              // console.log("- reps: ", strength);
            }
          });
        });
          //createChart(strength);
        },
        function(error) {
          messageNode.innerHTML = "logs request failed!";
          console.log("get request failed");
        }
      );
    });
    // reset form, slide it up and fade in the workout report
    topic.subscribe("submitted", function() {
      backToDefault();
      resetExCntr();
      //wipeFormUp();
      //createReport();
    });

    // reset exercise module counters upon form submission
    topic.subscribe("submitted", function() {
    });

    // TODO: DRY these up
    // click handler that adds exercise module to form
    on(st_btn, "click", function(evt) {
      evt.preventDefault();
      //TODO: need some nice animation here if possible
      domConstruct.place(createExercise("st"), st_btn, "before");
      console.log(createExercise.st_cnt);
    });

    on(ca_btn, "click", function(evt) {
      evt.preventDefault();
      domConstruct.place(createExercise("ca"), ca_btn, "before");
      console.log(createExercise.ca_cnt);
    });
});

