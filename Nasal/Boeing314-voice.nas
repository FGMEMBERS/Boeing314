# EXPORT : functions ending by export are called from xml
# CRON : functions ending by cron are called from timer
# SCHEDULE : functions ending by schedule are called from cron


# =============
# CREW CALLOUTS 
# =============

Voice = {};

Voice.new = func {
   var obj = { parents : [Voice,System],

               crewvoice : Crewvoice.new(),

               ABSENTSEC : 15.0,                                 # less attention

               rates : 0.0,                                      # variable time step

               # pilot not in command
               pilotwind : {}
         };

   obj.init();

   return obj;
}

Voice.init = func {
   me.inherit_system( "/systems/voice" );

   me.inittext();

   settimer( func { me.schedule(); }, constant.HUMANSEC );
}

Voice.inittext = func {
   me.inittable("/systems/voice/callouts/wind/pilot", me.pilotwind );
}

Voice.inittable = func( path, table ) {
   var key = "";
   var text = "";
   var node = props.globals.getNode(path).getChildren("message");

   for( var i=0; i < size(node); i=i+1 ) {
        key = node[i].getChild("action").getValue();
        text = node[i].getChild("text").getValue();
        table[key] = text;
   }
}

Voice.set_rates = func( steps ) {
    me.rates = steps;
}

Voice.crewtextexport = func {
    me.crewvoice.textexport();
}

Voice.pilotcall = func( action ) {
   if( action == "port" or action == "starboard" or action == "head" ) {
       me.crewvoice.nowpilot( action, me.pilotwind );
   }

   else {
       print("call not found : ", action);
   }
}

Voice.schedule = func {
   if( me.itself["root"].getChild("serviceable").getValue() ) {
       me.set_rates( me.ABSENTSEC );

       me.crewvoice.schedule();

       me.playvoices();
   }

   else {
       me.rates = me.ABSENTSEC;
   }

   settimer( func { me.schedule(); }, me.rates );
}

Voice.playvoices = func {
   if( me.crewvoice.willplay() ) {
       me.set_rates( constant.HUMANSEC );
   }

   me.crewvoice.playvoices( me.rates );
}


# ==========
# CREW VOICE 
# ==========

Crewvoice = {};

Crewvoice.new = func {
   var obj = { parents : [Crewvoice,System],

               voicebox : Voicebox.new(),

               CONVERSATIONSEC : 4.0,                            # until next message
               REPEATSEC : 4.0,                                  # between 2 messages

               # pilot in command
               phrasecaptain : "",
               delaycaptainsec : 0.0,

               # pilot not in command
               phrase : "",
               delaysec : 0.0,                                   # delay this phrase
               nextsec : 0.0,                                    # delay the next phrase

               # engineer
               phraseengineer : "",
               delayengineersec : 0.0,

               asynchronous : constant.FALSE,

               hearsound : constant.FALSE,
               hearvoice : constant.FALSE
         };

   obj.init();

   return obj;
}

Crewvoice.init = func {
   me.inherit_system("/systems/voice");

   me.hearsound = me.itself["sound"].getChild("enabled").getValue();
}

Crewvoice.textexport = func {
   var feedback = me.voicebox.textexport();

   # also to test sound
   if( me.voicebox.is_on() ) {
       me.talkpilot( feedback );
   }
   else {
       me.talkengineer( feedback );
   }
}

Crewvoice.schedule = func {
   if( me.hearsound ) {
       me.hearvoice = me.itself["root-ctrl"].getNode("sound").getValue();
   }

   me.voicebox.schedule();
}

Crewvoice.stepallways = func( state, table, repeat = 0 ) {
   var result = constant.FALSE;

   if( !me.asynchronous ) {
       if( me.nextsec <= 0 ) {
           me.phrase = table[state];
           me.delaysec = 0;

           if( repeat ) {
               me.nextsec = me.REPEATSEC;
           }

           if( me.phrase == "" ) {
               print("missing voice text : ",state);
           }

           me.asynchronous = constant.TRUE;
           result = constant.TRUE;
       }
   }

   return result;
}

Crewvoice.steppilot = func( state, table ) {
   me.talkpilot( table[state] );

   if( me.phrase == "" ) {
       print("missing voice text : ",state);
   }

   me.asynchronous = constant.TRUE;

   return state;
}

Crewvoice.nowpilot = func( state, table ) {
   me.steppilot( state, table );

   me.playvoices( constant.HUMANSEC );
}

Crewvoice.talkpilot = func( phrase ) {
   if( me.phrase != "" ) {
       print("phrase overflow : ", phrase);
   }

   # add an optional argument
   if( find("%d", phrase) >= 0 ) {
       var argument = me.itself["root"].getChild("argument").getValue();

       phrase = sprintf( phrase, argument );
   }

   me.phrase = phrase;
   me.delaysec = 0;
}


Crewvoice.stepengineer = func( state, table ) {
   me.talkengineer( table[state] );

   if( me.phraseengineer == "" ) {
       print("missing voice text : ",state);
   }

   return state;
}

Crewvoice.nowengineer = func( state, table ) {
   me.stepengineer( state, table );

   me.playvoices( constant.HUMANSEC );
}

Crewvoice.talkengineer = func( phrase ) {
   if( me.phraseengineer != "" ) {
       print("engineer phrase overflow : ", phrase);
   }

   me.phraseengineer = phrase;
   me.delayengineersec = 0;
}

Crewvoice.stepcaptain = func( state, table ) {
   me.talkcaptain( table[state] );

   if( me.phrasecaptain == "" ) {
       print("missing voice text : ",state);
   }

   me.asynchronous = constant.TRUE;

   return state;
}

Crewvoice.nowcaptain = func( state, table ) {
   me.stepcaptain( state, table );

   me.playvoices( constant.HUMANSEC );
}

Crewvoice.talkcaptain = func( phrase ) {
   if( me.phrasecaptain != "" ) {
       print("captain phrase overflow : ", phrase);
   }

   me.phrasecaptain = phrase;
   me.delaycaptainsec = 0;
}

Crewvoice.willplay = func {
   var result = constant.FALSE;

   if( me.phrase != "" or me.phraseengineer != "" or me.phrasecaptain != "" ) {
       result = constant.TRUE;
   }

   return result;
}

Crewvoice.is_asynchronous = func {
   return me.asynchronous;
}

Crewvoice.playvoices = func( rates ) {
   # pilot not in command calls out
   if( me.delaysec <= 0 ) {
       if( me.phrase != "" ) {
           me.itself["display"].getChild("copilot").setValue(me.phrase);

           if( me.hearvoice ) {
               me.itself["sound"].getChild("copilot").setValue(me.phrase);
           }
           me.voicebox.sendtext(me.phrase);
           me.phrase = "";

           # engineer lets pilot speak
           if( me.phraseengineer != "" ) {
               me.delayengineersec = me.CONVERSATIONSEC;
           }
        }
   }
   else {
       me.delaysec = me.delaysec - rates;
   }

   # no engineer voice yet
   if( me.delayengineersec <= 0 ) {
       if( me.phraseengineer != "" ) {
           me.itself["display"].getChild("engineer").setValue(me.phraseengineer);

           if( me.hearvoice ) {
               me.itself["sound"].getChild("pilot").setValue(me.phraseengineer);
           }
           me.voicebox.sendtext(me.phraseengineer, constant.TRUE);
           me.phraseengineer = "";
       }
   }
   else {
       me.delayengineersec = me.delayengineersec - rates;
   }

   # pilot in command calls out
   if( me.delaycaptainsec <= 0 ) {
       if( me.phrasecaptain != "" ) {
           me.itself["display"].getChild("captain").setValue(me.phrasecaptain);

           if( me.hearvoice ) {
               me.itself["sound"].getChild("pilot").setValue(me.phrasecaptain);
           }
           me.voicebox.sendtext(me.phrasecaptain, constant.FALSE, constant.TRUE);
           me.phrasecaptain = "";
       }
   }
   else {
       me.delaycaptainsec = me.delaycaptainsec - rates;
   }

   if( me.nextsec > 0 ) {
       me.nextsec = me.nextsec - rates;
   }

   me.asynchronous = constant.FALSE;
}
