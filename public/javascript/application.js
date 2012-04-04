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
  "dojo/dom", "dojo/dom-construct", "dojo/dom-attr", "dojo/dom-form",
  "dojo/dom-style", "dojo/dom-class",
  // Nodelist
  "dojo/query",
  // Dijit Modules
   "dijit/registry",
   "dijit/Dialog",
   "dijit/Tooltip",
  // Charting Modules
  "gii/StExInputWidget",
  "gii/CaExInputWidget",
  "gii/StExerciseWidget",
  "gii/CaExerciseWidget",
  //"dojox/charting/Chart", "dojox/charting/themes/Claro",
  //"dojox/charting/plot2d/Lines", "dojox/charting/plot2d/Markers",
  //"dojox/charting/axis2d/Default",
  // Dijit Parser
  "dojo/parser",
  "dojo/domReady!"],
  function(baseFx, fx, xhr, arrayUtils, on, topic, dom, domConstruct,
    domAttr, domForm, domStyle, domClass, query, registry, Dialog, Tooltip,
    StExInputWidget, CaExInputWidget, StExerciseWidget, CaExerciseWidget) {
    // domAttr, domForm, StExerciseWidget, Chart, theme) {
    var workoutForm = dom.byId("workout-form");

    // Initialize exercise module counters
    createExInput.st_cnt = 0;
    createExInput.ca_cnt = 0;


    // UI 
    // =========================================================================
    // User login (Programmatic)
    // Some Googling showed me how to implement multiline strings in javascript
    // 
    var loginSignupDialog = new Dialog({
      title: "User Login/Signup",
      // I don't like  having so much HTML here!!!
      // TODO: investigate how to create dialog declaratively
      content: '<div class="login-signup-container"> \
                  <div id="login-signup-error"></div> \
                  <div class="login-container"> \
                    <p>Already signed up?  Please login below.</p> \
                    <form id="loginForm"> \
                      <div class="control-group"> \
                        <label class="control-label" for="user_name">User Name</label> \
                        <div class="controls"> \
                         <input type="text" name="user_name" id="user_name"> \
                        </div> \
                      </div> \
                      <div class="control-group"> \
                        <label for="password">Password</label> \
                        <div class="controls"> \
                          <input type="password" name="password" id="password"> \
                        </div> \
                      </div> \
                      <button type="submit" id="loginBtn">Log In</button> \
                    </form> \
                  </div> \
                  <div class="signup-container"> \
                    <p>Not signed up yet?  Please fill out the form below.</p> \
                    <form id="signupForm"> \
                      <div class="control-group"> \
                        <label class="control-label" for="user_name">User Name</label> \
                        <div class="controls"> \
                         <input type="text" name="user_name" id="user_name"> \
                        </div> \
                      </div> \
                      <div class="control-group"> \
                        <label for="password">Password</label> \
                        <div class="controls"> \
                          <input type="password" name="password" id="password"> \
                        </div> \
                      </div> \
                      <div class="control-group"> \
                        <label for="password_confirmation">Password</label> \
                        <div class="controls"> \
                          <input type="password" name="password_confirmation" id="password_confirmation"> \
                        </div> \
                      </div> \
                      <button type="submit" id="signupBtn">Sign Up</button> \
                    </form> \
                  </div> \
                </div>',
      style: "width: 800px"
    });

    loginSignupDialog.show();
    
    // login submit handler will send data to server via ajax.  if transfer is successful then hide the dialog.
    on(dom.byId("loginForm"), "submit", function(evt) {
      evt.preventDefault();

      var loginPost = xhr.post({
        url: "/login",
        timeout: 5000,
        form: this,
      });

      loginPost.then(function() {
        console.log("login post was successful");
        loginSignupDialog.hide();
      },
      function(error) {
        console.log(error);
        var loginSignupErrorNode = dom.byId("login-signup-error");
        loginSignupErrorNode.innerHTML = error.responseText;
        domClass.add(loginSignupErrorNode, "flash");
      });
    });

    // login submit handler will send data to server via ajax.  if transfer is successful then hide the dialog.
    on(dom.byId("signupForm"), "submit", function(evt) {
      evt.preventDefault();

      var signupPost = xhr.post({
        url: "/signup",
        timeout: 5000,
        form: this,
      });

      signupPost.then(function() {
        console.log("Signup post was successful");
        loginSignupDialog.hide();
      },
      function(error) {
        console.log(error);
        // TODO: This is a ugly hack. must clean up!
        var loginSignupErrorNode = dom.byId("login-signup-error");
        loginSignupErrorNode.innerHTML = error.responseText;
        domClass.add(loginSignupErrorNode, "flash");
      });
    });

    //-------------------------------------------------------------------------

    // arrays to hold collection of exercise input widgets
    var stExInputs = [];
    var caExInputs = [];

    // create initial exercise modules
    // (3/17): maybe i should add these dijits to the arrays above since I don't want to 
    // delete these dijits upon form submission.  will try it out and see
    createExInput("st").placeAt(dom.byId("stExInContainer"));
    createExInput("ca").placeAt(dom.byId("caExInContainer"));

  //-----------------------------------------------------------------------------
    // Exercise Input Generation
    function createExInput(exType) {
      // st_cnt & ca_cnt properties are initialized in the beginning of code app definition
      var exercise = null;

      if (exType === "st") {
        createExInput.st_cnt++;
        exInput = new StExInputWidget({ ex_num: createExInput.st_cnt });
      }
      else if (exType === "ca") {
        createExInput.ca_cnt++;
        exInput = new CaExInputWidget({ ex_num: createExInput.ca_cnt });
      }

      return exInput;
    }

    // Validation of exercise inputs
    // Can I move this logic inside the widget?
    query(".valTxtIn").on("keyup", function(evt) {
      // not sure if nextElementSibling is supported universally?
      // it's not: http://www.quirksmode.org/dom/w3c_traversal.html
      // TODO: will have to figure out a way to support IE6-8
      var valStat = this.nextElementSibling;
      console.log("text input value: ", this.value);
      if(!/^[1-9]{1,3}$/.test(this.value)) {
        console.log("failed validation");
        valStat.innerHTML = "Wrong format";
        domClass.remove(valStat, "label-success");
        domClass.add(valStat, "label-important");
      }
      else {
        valStat.innerHTML = "OK";
        domClass.remove(valStat, "label-important");
        domClass.add(valStat, "label-success");
      }
      // reveal the validation status
      domClass.remove(valStat, "hidden");
    });





    // TODO: DRY these up
    // click handler that adds exercise module to form
    on(dom.byId("st_btn"), "click", function(evt) {
      evt.preventDefault();
      //TODO: need some nice animation here if possible
      stExInputs.push(createExInput("st"));
      stExInputs[stExInputs.length - 1].placeAt(dom.byId("stExInContainer"));
    });

    on(dom.byId("ca_btn"), "click", function(evt) {
      evt.preventDefault();
      caExInputs.push(createExInput("ca"));
      caExInputs[caExInputs.length - 1].placeAt(dom.byId("caExInContainer"));
    });


  //-----------------------------------------------------------------------------

    // TODO: investigate using a accordion panels to handle the transition
    // from form submission to log report display
    // 3/17: i'm going to scrap the accordion idea. instead i'd like to have some type of spinner
    // and then fade out the form, set it's height to 0, fade in the summary and highlight background with some color
    //
    /* function createReport() {
      domConstruct.create("div", {
        style: {
          backgroundColor: "red",
          height: "300px"
          //opacity: 0
        }
      },
      workoutForm, "after")
    } */

    // Form Submit handler
    on(workoutForm, "submit", function(evt) {
      var messageNode = dom.byId("message");

      evt.preventDefault();

      // perform form validation one final time

      // add two hidden fields to form to indicate
      // how many of each exercise modules are present
      // TODO: DRY this up
      // can move the hidden fields into the template and update the value
      // via using domAttr.set
      domAttr.set(dom.byId("st_cnt"), { value: createExInput.st_cnt });
      domAttr.set(dom.byId("ca_cnt"), { value: createExInput.ca_cnt });

      var def= xhr.post({
        url: "/",
        timeout: 5000,
        handleAs: "json",
        form: this,
      });

      def.then(function(response) {
          console.log("success! ", response)

          // response should be a JSON version of the workout that was submitted
          // console.log("exs: ", response.exercises);
          if (response) {
            arrayUtils.forEach(response.exercises, function(exercise) {
              // console.log("ex: ", exercise);
              if (exercise._type == "StrengthExercise") {
                console.log("creating strength exercise report");
                new StExerciseWidget(exercise).placeAt(dom.byId("stExerciseReport"));
              }
              else if (exercise._type == "CardioExercise") {
                console.log("creating cardio exercise report");
                new CaExerciseWidget(exercise).placeAt(dom.byId("caExerciseReport"));
              }
              else {
                console.log("ERROR: exercise has no type!");
              }
            });
          }
          else {
            console.log("server did not response with json object");
          }
          
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
          // TODO: create a proper "flash" section

          dom.byId("message").innerHTML = "Ajax request failed!";
          console.log("post request failed");
          console.log(error);
        }
      );
    });

    // Cancel button click handler
    on(dom.byId("cancelBtn"), "click", backToDefault);


    // clear the workout log form
    // later, this function will have to revert the form back to it's default look (1 exercise)
    function backToDefault() {
      workoutForm.reset();

      // TODO: Dry it up
      arrayUtils.forEach(stExInputs, function(stExInput) {
        stExInput.destroyRecursive();
      });

      arrayUtils.forEach(caExInputs, function(caExInput) {
        caExInput.destroyRecursive();
      });
    }

    // Chart Generation
    /*function createChart(chartData) {
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
    }*/
    

    //---------------------- EVENTS --------------------------------------------
    ////////////////////////////////////////////////////////////////////////////
    // --------------------------------------------------------------------------
    // "submitted" subscribers
    // --------------------------------------------------------------------------
    // retrieve all workout logs from db when form is submitted.
    // i added this with the idea of charting the logs that have been submitted thus
    // far.  will have to modify such that only the past (3?) months of data is retrieved
    // by default and then provide user a way to specify the amount of data they would like
    // to see.
    /* topic.subscribe("submitted", function() {
      xhr.get({
        url: "/logs",
        handleAs: "json"
      })
      .then(function(jsonData) {
        var strength = [];
        var cardio = [];
        arrayUtils.forEach(jsonData, function(log) {
          arrayUtils.forEach(log.exercises, function(exercise) {
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
    }); */

    // reset form, slide it up and fade in the workout report
    topic.subscribe("submitted", function() {
      // probably should move the function definitions inside of here since they are
      // only relevent here.
      console.log("inside form clear routine");
      backToDefault();
      console.log("reset form to default state");
      resetExCntr();
      console.log("reset exercise input counters");
      // set container's height to 0px will not work, children do not inherit height property?
      // maybe i can try to wipe out the form, but very quickly.
      // actually the correct css attribute is display: hidden, but wipeOut works out just fine
      fx.chain([
        // would like to fade out form then wipeOut
        fx.wipeOut({
          node: workoutForm,
          duration: 10
        }),
        // would like to fade out form then wipeOut
        fx.wipeIn({
          node: workoutReport,
        })
        // would like to fade in form then wipeOut
      ]).play();

      // reset exercise input counters to 1 when form is submitted
      function resetExCntr() {
        createExInput.st_cnt = 1;
        createExInput.ca_cnt = 1;
      }

    });
});

