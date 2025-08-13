Hi! Wellcome to digi!Flute, a digital tool to assist beginner flute learners by providing real-time feedback on technique, tone, and musicality

## Introduction ##
The task of developing the "Digi!Flute" focuses on providing effective and affordable practice tools for beginning flute learners, addressing significant access and learning challenges. This digital flute education support tool aims to democratize music learning by offering real-time feedback on technique, tone, and musicality in a cost-effective manner. Our design objectives, shaped by rigorous research into novice players' needs such as embouchure adjustment and pitch steadiness, emphasize creating an intuitive, reliable system adaptable to various learning stages. The Digi!Flute is designed to be scalable, ensuring it remains useful as users' skills develop, incorporating functionalities like note logging, rest entry, tempo adjustment, and vibrato effects. This design is considered optimal as it meets these needs efficiently, backed by empirical research and user feedback, guiding its adaptation towards full-scale implementation.

Despite its current capabilities, the prototype of the Digi!Flute represents only the initial step towards a comprehensive solution that fulfills the broader requirements of music education technology. The full-scale design will expand upon the foundational features tested in the prototype, incorporating enhanced interactive elements and a broader range of instrument sounds to cater to diverse musical tastes and practices. Additionally, the design will address user feedback regarding interface usability and feature accessibility, crucial for ensuring that the system is not only functional but also enjoyable to use. By leveraging detailed user interaction data and feedback, the full-scale Digi!Flute will be refined to provide a more personalized learning experience, supporting the nuanced needs of flute learners at various stages of their musical journey.

## System Overview ##
Our project is aimed at addressing the issues beginner flute players face by developing an adaptable system, the Digi!Flute, that allows them to actively practice playing the flute with direct feedback on any errors in their playing in order to give them access to supplemental learning tools outside of the classroom. The following subsections detail the Digi!Flute’s two systems: the synthesizer and transcriber.

1. The Synthesizer System
The following sub-subsections will detail the Digi!Flute synthesizer’s graphic user interface (GUI), as well as the subsystems within. These nine subsystems include: logging notes, changing note duration, logging rests, changing tempo, vibrato, flute audio, deletion of notes, ending a song, and recording user input.

1.1 GUI
The user can interact with the synthesizer through the note entry system, that is composed of a labeled keyboard for logging notes, toggle buttons to determine the duration of notes played, and buttons for logging rests of various durations, as well as buttons to change tempo, enable vibrato, switch to the sound of a flute, and delete previous entries. The user will be able to engage with these features before clicking the end button to save a file to transcriber. There will also be a button to record the user’s playing. Each of the button types has been assigned a different color for easier differentiation for the user. The delete and end buttons in particular have darker colors to emphasize their function to the user. The red for the delete button and green for the end button were chosen specifically for their association with negatives and positives. The appearance and location of each of these subsystems has been determined using the Gtk package within Julia

1.2 Logging Notes
Each note key is assigned a Musical Instrument Digital Interface (MIDI) number, which are musical frequencies represented by integers so that A440, or note A at 440 Hz, is equivalent to the MIDI number 69. When the user presses a key, our synthesizer uses the MIDI to frequency conversion formula, as described by Equation 1, to determine the frequency of the pressed note:

f = 2(midi - 69)/12*440   (1)

where f is the frequency of the note and midi is the MIDI number.

This will be used in the sinusoidal wave equation, as described by Equation 2, to produce a signal of the correct duration:

x=cos(2𝛑*N*f / S)       (2)

where x is the sinusoidal wave, N is number of samples, f is the frequency of the note, and S is the sampling rate necessary to cover a range of audible frequencies (44100 samples per second).

This signal is dependent on the desired note length a user has chosen, or N as seen in Equation 1. For further detail on how note duration is changed, see subsection 2.1.3. After the signal has been synthesized, it will be played aloud for the user using the julia Sound package and then saved within an internal song vector. This feature has been completed.

1.3 Note Duration Toggle
There are duration options for a quarter, half, or whole note. When the user presses one of the duration toggle buttons, the number of samples necessary to play a note for that long will be determined by utilizing the ratio of how many quarter notes are equivalent to the pressed button note, as seen in equation 3:

Nkey = Nquarter*(Lkey/Lquarter)    (3)

where Nnote is the number of samples for the key played, Nquarter is number of samples to play a quarter key, Lnote is the length of the key (¼, ½, or 1), and Lquarter is the length of a quarter key (¼).

This equation will find the number of samples later used in the sinusoidal wave equation, thus determining how long each newly logged note is played for. The user will be able to toggle between multiple note durations by pressing a different note duration button.

1.4 Logging Rests
There are options for a quarter, half, or whole rest. When the user presses one of the rest toggle buttons, the number of samples necessary to be silent for that long will be determined by utilizing the ratio of how many quarter rests are equivalent to the pressed button note as seen in Equation 3. Then a frequency of zero amplitude of the determined number of samples will be generated to create a “silent sinusoidal wave” that will then be saved within the internal song vector. The user will be able to enter rests of multiple durations by pressing any rest duration button. 

1.5 Changing Tempo
Once users click on the tempo button, they will be guided to a popup window where they get the option to choose from specific tempo options ranging from 60 to 120 incrementing by 20 by clicking on their respective buttons. These increments have been chosen due to several factors. Our team had difficulty implementing a slider or type-in box for the user to use, and believing a wider array of options may intimidate beginner players, we opted to offer a small variety of tempo choices instead. The program then stores the value for the tempo chosen and uses it to calculate the number of samples a quarter note should have using Equation 4:

Nquarter = (60*S) / tempo		(4)

where Nquarter is the number of samples for a quarter key, S is the sampling rate necessary to cover a range of audible frequencies (44100 samples per second), and tempo is one of the offered tempo options (60 to 120 in increments of 20).

The new value for N will then lead to a different quarter note duration.

1.6 Vibrato Toggle
When the user clicks on the vibrato button, its internal status will be marked as true, or “on”, and any following note keys pressed by the user will be played back and saved in the internal song vector with synthesized vibrato. This vibrato will be created by taking the sine of a cosine that varies with time, thus causing minute “wavering” in the note’s frequency. Clicking the button again marks it as false, or “off”, thus disabling the synthesized vibrato.

1.7 Flute Sound Toggle
Once the user clicks on the flute button, its status in the code would be considered true. Any notes pressed on the keyboard will be played back as a prerecorded flute note of the same tone. The tones available range from a midi number of 67 to 79 for a total of 13 notes, and each would be played for about 3 seconds. The flute button was created with the intent of indexing into a pre-recorded wav file that contains all the notes from a midi of 67 to 79. When a user presses on one of such notes, the program would check the midi number of the note played and index into the wav file accordingly. This feature has been completed. Before releasing a beta version, we intend to implement further improvements that would allow for playing the recorded notes for various durations.

1.8 Delete Button
As each note or rest is logged within the internal song vector, the number of samples it contains are saved within a global deletion vector, to automatically keep track of the lengths of the every entered key. If the user clicks the delete button, then it will remove the last entered key from the song using the last element in the deletion vector. It will then remove the last entry within the deletion vector to allow the user to continue deleting notes within the song. To avoid indexing errors, if the last entered key was also the only key entered in the song, then the song vector and the deletion storage vector will be completely cleared.

1.9 End Button
When the user clicks the end button, it plays back the entire internal song vector using the julia Sound package and then writes it to a .wav file for the transcriber to use.

1.10 Record Button
Once pressed, the record button will record any sound made by the user and save it into a wav file for the transcriber. Each note's data, including the frequency and the samples per note, will also be in the wav file as a result, preparing it for the transcriber to interpret. The record button would record for a total of 10 seconds. This button is completed. We intend to experiment with higher time slots in the future, so that the user may change how long they record for if they wish.

2. The Transcriber System
Our transcriber is composed of an input stage, three main subsystems to determine the accuracy of specific parts of the played notes, and finally a stage that determines the overall accuracy of the song as a whole. Once both songs have been input, the user’s song and intended song, which will come either from our transcriber or a collection of pre-recorded options, the transcriber assesses the user’s accuracy in pitch, duration, and steadiness. Following this, an accuracy score is generated for each criteria. Finally, an average is taken of these scores, which is the reported final score.

2.1 Song Input
The input for this transcriber is quite simple. The user will have either downloaded one of the pre-synthesized options or created their own file, which will be read in by the transcriber, alongside the user recorder song. We are using wavread to accomplish this task, which reads in both the sampling rate and the signals. The input has been completed.

2.2 Frequency Accuracy
The accuracy of the song played will be determined using the autocorrelation method. Using this method, the samples stored at the wav file will be used as input. The samples will then be compared to multiple different frequencies using the best correlation to determine the highest value and therefore the correctly played frequency. Then, the frequency from the wav file will be compared to the expected frequency played, which will be used to determine the accuracy of the note played. 

2.3 Duration Accuracy
Our transcriber uses the envelope method to determine the duration accuracy. First the envelope method will be used to find the beginning and ending of each note, and then pair up each start with the next stop, essentially determining the indexes that each note covers. Once this has been done, the transcriber will subtract the stop index from the start index, thus finding the length of the note in samples. This is done for both the user recording file and the synthesized file before the two are compared. As we are targeting this product towards beginners in music education, a 3% tolerance has been included to be more useful for the user. Anything above this value is significantly different than expected, while any note length within 3% is acceptable for a musician at this skill level. 

2.4 Pitch Steadiness
For the task of determining pitch steadiness, our transcriber first breaks each individual note into smaller samples then compares them to each other. Unlike the frequency and duration tests, the pitch steadiness is not compared to the synthesized file, meaning that a user could theoretically play out of tune for the wrong amount of time, yet still be accurate for steadiness. To achieve this, we break each note into 8 subsamples and call the function that uses the autocorrelation method to find the frequency of each subsample. If the frequencies differ from each other by more than 7 cents, the pitch is determined to be unsteady. This tolerance range allows for small changes between subsamples, but still recognizes any substantial frequency differences.

2.5 Display of Final Score
To conclude our transcriber portion, a display of the final accuracy score and a note graph will be shown to the user. The SmartScore is a GUI display that shows the percentage breakdowns in the categories of duration accuracy, pitch accuracy, and pitch steadiness, along with an overall score that is the average of those previous three scores. A note graph will also be generated that displays the pitch of each note in sudo-staff notation, and the dot is plotted at the start of the note, rounded to the nearest quarter note. Therefore, both the duration and the frequency can be directly compared to the intended notes.

