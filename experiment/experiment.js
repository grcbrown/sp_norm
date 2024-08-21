const jsPsych = initJsPsych({
    show_progress_bar: true,
    auto_update_progress_bar: false,
    on_finish: function(data) {
        proliferate.submit({"trials": data.trials});
      }
  });

let timeline = []; //Empty timeline to which we will add trials

//IRB//
const irb = {
    type: jsPsychHtmlButtonResponse,
    stimulus: "<p><font size='3'>DESCRIPTION: You are invited to participate in a research study. Its general purpose is to understand how people perceive speech. We are interested in how people make use of varying properties of language to infer social information about a speaker. In this study, you will hear spoken sentences, and you will be asked to make simple decisions about the sentences you hear. Following this, you will be asked to complete a short questionnaire, where you will indicate on a sliding scale how much you agree or disagree with a series of statements. You will also be asked to complete an optional demographic survey. <br><br>TIME INVOLVEMENT: Your participation will take approximately 3 to 10 minutes. <br><br>RISKS AND BENEFITS: The foreseeable risks associated with this study are minimal. This judgment is based on a large body of experience with the same or similar procedures with people of similar ages, sex, origins, etc. Study data will be stored securely, in compliance with Stanford University standards, minimizing the risk of confidentiality breach. There are no known benefits to you for participating in this study, and we cannot and do not guarantee or promise that you will receive any benefits from this study. You will help us to understand how people perceive spoken language. <br><br>PAYMENT: You will be paid at the posted rate. <br><br>PARTICIPANT RIGHTS: If you have read this form and have decided to participate in this project, please understand your participation is voluntary and you have the right to withdraw your consent or discontinue participation at any time without penalty or loss of benefits to which you are otherwise entitled. The alternative is not to participate. You have the right to refuse to answer particular questions. The results of this research study may be presented at scientific or professional meetings or published in scientific journals. Your individual privacy will be maintained in all published and written data resulting from the study. In accordance with scientific norms, the data from this study may be used or shared with other researchers for future research (after removing personally identifying information) without additional consent from you. <br><br>CONTACT INFORMATION: If you have any questions, concerns or complaints about this research study, its procedures, risks and benefits, you should contact the Protocol Director Meghan Sumner at (650)-725-9336. If you are not satisfied with how this study is being conducted, or if you have any concerns, complaints, or general questions about the research or your rights as a participant, please contact the Stanford Institutional Review Board (IRB) to speak to someone independent of the research team at (650)-723-2480 or toll free at 1-866-680-2906. You can also write to the Stanford IRB, Stanford University, 3000 El Camino Real, Five Palo Alto Square, 4th Floor, Palo Alto, CA 94306 USA. <br><br>WAIVER OF DOCUMENTATION: If you agree to participate in this research, please click the 'Continue' button to begin the experiment. </font></p>",
    choices: ['Continue']
};

// push to the timeline
timeline.push(irb);

//PRELOAD AUDIO//
const preload_array = ['audio/193_B1_CN7.wav', 'audio/246_B2_CN7.wav', 'audio/340_B1_CN7.wav', 'audio/625_B2_CN7.wav', 'audio/723_B1_CN7.wav'];
const preload_trial = {
    type: jsPsychPreload,
    audio: preload_array
};

timeline.unshift(preload_trial);

//INSTRUCTIONS//
const instructions = {
    type: jsPsychHtmlButtonResponse,
    stimulus: "<p><font size='3'>In this study, you will listen to a series of sentences. Each sentence is produced by a different speaker. While listening to each sentence, you will be prompted to rate the social characteristics of its speaker. To rate the social characteristics of a speaker, click along the scale that appears on your screen. You may click along this scale after the speaker stops talking. Try to respond as quickly as you can. The study will advance automatically if you do not respond within ten seconds. <br><br>When you are ready to begin, click ‘Start’.</font></p>",
    choices: ['Start']
};

//push to the timeline
timeline.push(instructions);

//audio trials
let stim_array = create_tv_array(trial_obj);
const audio_trials = {
    timeline: [
        {
            type: jsPsychAudioSliderResponse,
            stimulus: jsPsych.timelineVariable('stimulus'),
            labels: ['Not at all masculine', 'Extremely masculine'],
            prompt: '<p>How masculine is the speaker of this sentence?</p>',
            response_allowed_while_playing: false,
            response_ends_trial: true,
            require_movement: true,
            slider_width: 500,
            step: 1,
            min: 0,
            max: 100,
            trial_duration: 10000,
            data: {
                coding: jsPsych.timelineVariable('coding')
            },
            on_finish: function(data) {
                jsPsych.setProgressBar((data.trial_index - 1) / (timeline.length + stim_array.length));
            }
        },
        {
            type: jsPsychHtmlKeyboardResponse,
            choices: [""],
            stimulus: "",
            response_ends_trial: false,
            trial_duration: 1000
        }
    ],
    timeline_variables: trial_obj,
    randomize_order: true
}
timeline.push(audio_trials);

//INSTRUCTIONS//
const instructions_SRQ = {
    type: jsPsychHtmlButtonResponse,
    stimulus: "<p><font size='3'>You have completed the listening trials. You will now complete a short questionnaire. During the questionnaire, you will see a series of statements alongside a scale. Click along the scale to indicate how much you agree or disagree with the statement. Upon completion of the questionnaire, you will be asked to fill out an optional demographic survey. <br><br>When you're ready to begin the questionnaire, click ‘Continue’.</font></p>",
    choices: ['Continue']
};

//push to the timeline
timeline.push(instructions_SRQ);

// SRQ
let gender_array = create_tv_array(gender_objects);
const gender_ideology = {
    timeline: [
        {
            type: jsPsychHtmlVasResponse,
            labels: ["Completely Disagree", "Completely Agree"],
            stimulus: jsPsych.timelineVariable('stimulus'),
            scale_width: 500,
            ticks: false,
            required: true,
            response_ends_trial: true,
            trial_duration: 10000,
            data: {
                coding: jsPsych.timelineVariable('coding')
            },
            on_finish: function(data) {
                jsPsych.setProgressBar((data.trial_index - 1) / (timeline.length + gender_array.length));
            }
        }
    ],
    timeline_variables: gender_objects, //this is what is referencing the trials that were externally created
    randomize_order: true
};
timeline.push(gender_ideology);

const instructions_demo = {
    type: jsPsychHtmlButtonResponse,
    stimulus: "<p><font size='3'>You have completed the questionnaire. There will now be an optional survey. Please answer the following questions if you feel comfortable doing so. If you do not wish to answer a question, please leave it blank. <br><br>When you're ready to procede, click ‘Continue’.</font></p>",
    choices: ['Continue']
};

//push to the timeline
timeline.push(instructions_demo);

// Questionnaire pt 2
const questionnaire_2 = {
    type: jsPsychSurveyLikert,
    preamble: "Please answer the following question:",
    questions: [
      {
        prompt: "What is your political affiliation?", 
        labels: [
          "Very Progressive", 
          "Somewhat Progressive", 
          "Moderate", 
          "Somewhat Conservative", 
          "Very Conservative"
        ]
      }
    ]
};
timeline.push(questionnaire_2);

const questionnaire = {
    type: jsPsychSurvey,
    pages: [
        [
            {
                type: 'html',
                prompt: "Please answer the following questions:"
            },
            {
                type: 'multi-choice',
                prompt: 'Did you read the instructions and do you think you did the task correctly?', 
                name: 'correct', 
                options: ['Yes', 'No', 'I was confused']
            },
            {
                type: 'drop-down',
                prompt: 'Gender:',
                name: 'gender',
                options: ['Female', 'Male', 'Non-binary/Non-conforming', 'Other']
            },
            {
                type: 'text',
                prompt: 'Age:',
                name: 'age',
                textbox_columns: 10
            },
            {
                type: 'drop-down',
                prompt: 'Level of education:',
                name: 'education',
                options: ['Some high school', 'Graduated high school', 'Some college', 'Graduated college', 'Hold a higher degree']
            },
            {
                type: 'text',
                prompt: "Native language? (What was the language spoken at home when you were growing up?)",
                name: 'language',
                textbox_columns: 20
            },
            {
                type: 'drop-down',
                prompt: 'Where in the U.S. do you live?',
                name: 'region',
                options: ['Midwest - IA, IL, IN, KS, MI, MN, MO, ND, NE, OH, SD, WI', 'Northeast - CT, DC, DE, MA, MD, ME, NH, NJ, NY, PA, RI, VT', 'Southeast - AL, AR, FL, GA, KY, LA, MS, NC, SC, TN, VA, WV', 'Southwest - AZ, NM, OK, TX', 'West - AK, CA, CO, HI, ID, MT, NV, OR, UT, WA, WY']
            },
            {
                type: 'drop-down',
                prompt: 'Do you think the payment was fair?',
                name: 'payment',
                options: ['The payment was too low', 'The payment was fair']
            },
            {
                type: 'drop-down',
                prompt: 'Did you enjoy the experiment?',
                name: 'enjoy',
                options: ['Worse than the average experiment', 'An average experiment', 'Better than the average experiment']
            },
            {
                type: 'text',
                prompt: "Do you have any other comments about this experiment?",
                name: 'comments',
                textbox_columns: 30,
                textbox_rows: 4
            }
        ]
    ],
    on_finish: function(){
        jsPsych.setProgressBar(1); // set progress bar to 85% full.
    }
};
timeline.push(questionnaire);

// THANKS //
const thanks = {
    type: jsPsychHtmlButtonResponse,
    choices: ['Finish'],
    stimulus: "Thank you for your time! Please click 'Finish' and then wait a moment until you're directed back to Prolific.<br><br>"
};
timeline.push(thanks);

//RUN//
jsPsych.run(timeline);