##make synthesizer
using MAT: matread
using Sound: record, sound
using FFTW: fft, ifft
using WAV: wavread, wavwrite
using Gtk

# initialize global variables used throughout
S = 44100 # sampling rate
N = Int(0.5*S) #play for half a second ## change with tempo button
song = Float32[] # initialize "song" as an empty vector to record numbers
recsong = Float32[] # start off the recording as "empty"
(d, S_f) = wavread("/digiFlute/Flute Notes Recording - g4-g5.wav") #file pathway for the synth flute sounds
L = length(d) #length of one flute note in the recording
num_notes = 26 #num notes in flute recording
L_note = floor(Int, L/num_notes)
#dyn = false
N_determined = 0 #start without any note length
N_length = 0 #start with zero rest length
Delete_length = 0 #this will keep track of how long the last entry was
delete_store = Float32[] # intialize an empty vector to hold last entered note lengths
#start all toggle buttons as "off"
vstatus = false
fstatus = false

function miditone(midi::Int) #determines what sound to play when the user presses a note
    f = 2^((midi-69)/12) * 440 # find frequency from midi number
    if vstatus == true #if vibrato is "on" and flute is not "on", play note with vibrato
        t = (0:N_determined-1)/S
        c = 1 ./ (1:(2.5/5):2.5) # amplitudes
        freqs = (0.8:((1.2-0.8)/5):1.2) * f # frequencies, allow for minor pitch shifting
        x = cos.(2pi*(1:N_determined)*f/S)
        lfo = 0.005 * cos.(2π*4*t) / 4 # about 0.5% pitch variation
        for k in 1:length(c)
            x = +(c[k] * sin.(2π * freqs[k] * t + freqs[k] * lfo))
        end
        Delete_lengths_assign(N_determined) #track last entered key
    elseif fstatus == true #if the flute button is "on" and vibrato is not "on", play notes with flute
        x = cos.(2pi*(1:N_determined)*f/S)
        #cycle through the note thresholds to find the correct note
        if midi == 67; #G
            x = d[1 : floor(Int, (L_note)/5)]
        elseif midi == 68; #G#
            x = d[L_note : (L_note)+ floor(Int,(L_note)/5)]
        elseif midi == 69; #A
            x = d[2(L_note) : 2(L_note)+ floor(Int,(L_note)/6)]
        elseif midi == 70; #A#
            x = d[3(L_note) : 3(L_note)+ floor(Int,(L_note)/6)]
        elseif midi == 71; #B
            x = d[4(L_note) : 4(L_note)+ floor(Int,(L_note)/6)]
        elseif midi == 72; #C
            x = d[5(L_note) : 5(L_note)+ floor(Int,(L_note)/6)]
        elseif midi == 73; #C#
            x = d[6(L_note) : 6(L_note)+ floor(Int,(L_note)/6)]
        elseif midi == 74; #D
            x = d[7(L_note) : 7(L_note)+ floor(Int,(L_note)/6)]
        elseif midi == 75; #D#
            x = d[8(L_note) : 8(L_note)+ floor(Int,(L_note)/6)]
        elseif midi == 76; #E
            x = d[9(L_note) : 9(L_note)+ floor(Int,(L_note)/6)]
        elseif midi == 77; #F
            x = d[10(L_note) : 10(L_note)+ floor(Int,(L_note)/6)]
        elseif midi == 78; #F#
            x = d[11(L_note) : 11(L_note)+ floor(Int,(L_note)/6)]
        elseif midi == 79; #G(Higher octave)
            x = d[12(L_note) : 12(L_note)+ floor(Int,(L_note)/6)]
        end
        Delete_lengths_assign(length(x)) #track last entered key
    else #if status of notes to play is "normal"
        x = cos.(2pi*(1:N_determined)*f/S) # generate sinusoidal tone for note length
        Delete_lengths_assign(N_determined) #track last entered key
    end
    sound(x, S) # play note so that user can hear it immediately
    global song = [song; x] # append note to the (global) song vector
    return song
end

# define the keys and their midi numbers
key_entry = ["G" 67; "G#" 68; "A" 69; "A#" 70; "B" 71; "C" 72; "C#" 73; "D" 74; "D#" 75; "E" 76; "F" 77; "F#" 78; "G" 79] #FIXED numbers
# define note selection
note_header = ["Notes: " ; "Rests: "]
note_length = ["quarter" 1; "half" 2; "whole" 4]

g = GtkGrid() # initialize a grid to hold buttons
set_gtk_property!(g, :row_spacing, 5) # gaps between buttons
set_gtk_property!(g, :column_spacing, 5)
set_gtk_property!(g, :row_homogeneous, true) # stretch with window resize
set_gtk_property!(g, :column_homogeneous, true)


##styles section, --unique names, even if they don't match final color choices
greenend = GtkCssProvider(data="#wg {color:white; background:forestgreen;}") # add a style for the end button
reddelete = GtkCssProvider(data="#wr {color:white; background:red3;}") # add a style for the delete button
blackrec = GtkCssProvider(data="#wb {color:black; background:grey82;}") # add a style for the record button
turqtempo = GtkCssProvider(data="#wt {color:black; background:darkseagreen2;}") # add a style for the tempo button
purplevib = GtkCssProvider(data="#wp {color:black; background:thistle2;}") # add a style for the vibrato button
goldflute = GtkCssProvider(data="#ws {color:black; background:lightblue2;}") # add a style for the flute button
keystyle1 = GtkCssProvider(data="#wh1 {color:black; background:honeydew1;}") # add a style for the note duration buttons
keystyle2 = GtkCssProvider(data="#wh2 {color:black; background:honeydew2;}") # add a style for the rest buttons
lavnotes = GtkCssProvider(data="#wl {color:black; background:lavender;}") # add a style for the note buttons


##button clicked section
function end_button_clicked(w) # callback function for "end" button
    println("The end button was clicked.")
    sound(song, S) # play the entire song when user clicks "end"
    wavwrite(song, "touch.wav", Fs=S) # save song to file
end


function delete_button_clicked(w) # callback function for "delete" button
    if length(song) == 0 #if attempting to delete more notes than entered
        return println("Play more notes in order to delete an entry.") #remind the user there aren't any note entries
    end
    Delete_length = Int(delete_store[end]) #find the last entered key length
    if length(song) < (Delete_length+1) #if only one entry, empty song vector/delete vector
        empty!(song)
        empty!(delete_store)
    else #otherwise, delete the last entered key/rest from song/delete_store
        deleteat!( song, ( (length(song)-Delete_length+1):length(song) ) )
        deleteat!(delete_store, length(delete_store))
    end
    println("The delete button was clicked. \"", length(delete_store), "\" entrie(s) remaining in your song.") #report entries left
end

function vibrato_button_clicked(w) #callback function for turning vibrato on and off
    if fstatus == true #if flute button is on, don't allow the user to use the vibrato
        println("Turn off the flute button to use the vibrato feature.") #helpful reminder
    else
        global vstatus = !vstatus #switch the button state
        print("The vibrato button was clicked, vibrato is: ")
        if vstatus == true #report button status
            print("on.")
        else
            print("off.")
        end
        println("")
    end
end

function note_length_determined(time_played) #change the length of time for a note played
    global N_determined = N * time_played #change N_determined (from midi function) to change note lengths
    print("Note status is on: ") #report what the note length is on
    if time_played == 1
        print("quarter notes.")
    elseif time_played == 2
        print(" half notes.")
    else
        print(" whole notes.")
    end
    println("")
end

function rest_length_determined(time_played) #determine length of rest & insert into song
    N_length = N * time_played #find rest length from multiple of quarter note
    Delete_lengths_assign(N_length) #track last entered key
    z = zeros(N_length) #get N_length samples of "0" amplitude
    x = z/S #play for right amnt time
    global song = [song; x] # append rest to the (global) song vector
    print("Entered a: ")    #report the last entered rest.
    if time_played == 1
        print("quarter rest.")
    elseif time_played == 2
        print(" half rest.")
    else
        print(" whole rest.")
    end
    println("")
end

function dyn_button_clicked(w)
    println("dynamic switched")
    #dyn = !dyn
end

#dynbutton = GtkButton("dynamics")
#signal_connect(dyn_button_clicked, dynbutton, "clicked")
#set_gtk_property!(dynbutton, :name, "yb")

function tempo_button_clicked(w)
    #make a pop up grid
    t_win = GtkWindow("Tempo", 300, 300)
    tempo_grid = GtkGrid()
    set_gtk_property!(tempo_grid, :row_spacing, 2)
    set_gtk_property!(tempo_grid, :row_spacing, 2)
    set_gtk_property!(tempo_grid, :row_homogeneous, true)
    set_gtk_property!(tempo_grid, :column_homogeneous, true)

    #button labels
    B1 = GtkButton("60")
	B2 = GtkButton("80")
	B3 = GtkButton("100")
	B4 = GtkButton("120") 

    #connect the buttons to caculate the new tempo
    signal_connect((w) -> calc_N(60), B1, "clicked")
	signal_connect((w) -> calc_N(80), B2, "clicked")
	signal_connect((w) -> calc_N(100), B3, "clicked")
	signal_connect((w) -> calc_N(120), B4, "clicked")

    #fill in the grid
    tempo_grid[1, 1] = B1
	tempo_grid[2, 1] = B2
	tempo_grid[1, 2] = B3
	tempo_grid[2, 2] = B4
    push!(t_win, tempo_grid)
    showall(t_win)
end

function calc_N(tempo) #find the new length of a quarter note depending on the tempo
	New_N = (60 * S) / tempo
    global N = New_N #assign to the global N value and overwrite it
    return nothing
end

function Delete_lengths_assign(N_delete) #add the last entered key to the delete storage array
    if N_delete == 0 #if no note duration was chosen, have a helpful reminder
        println("Choose a note to play!")
    else
        append!(delete_store, N_delete) # append note to the (global) delete vector
    end
end

function flute_button_clicked(w) #turn the flute button on and off
    if vstatus == true #if vibrato is on, don't let the user use the flute button, have a reminder!
        println("Turn off vibrato to use the flute button feature.")
    else
        global fstatus = !fstatus #switch the button state
        print("The flute button was clicked, flute sound is now: ")
        if fstatus == true #print button status
            print("on.")
        else
            print("off.")
        end
        println("")
    end
end

function rec_button_clicked(w) #record user input
    println("Begin recording.") #alert user to begin recording
    (x, S) = record(10) #record for ten seconds (test for longer duration??) CHECK THIS IFHWEIGHWIORGHEIRG
    global recsong = [recsong; x]
    wavwrite(recsong, "recording.wav", Fs=S) # save song to file
end

#---------------------------------------------------ADDING buttons--------------------------------------------------------
##
dbutton = GtkButton("delete") # make a "delete" button
g[27:29, 1] = dbutton #keep at end of row 1/top of note buttons
signal_connect(delete_button_clicked, dbutton, "clicked") #callback :D
set_gtk_property!(dbutton, :name, "wr") # set style of the "delete" button
push!(GAccessor.style_context(dbutton), GtkStyleProvider(reddelete), 600)

ebutton = GtkButton("end") # make an "end" button
g[27:29, 2] = ebutton # keep at end of row 2/bottom of entry buttons
signal_connect(end_button_clicked, ebutton, "clicked") # callback
set_gtk_property!(ebutton, :name, "wg") # set style of the "end" button
push!(GAccessor.style_context(ebutton), GtkStyleProvider(greenend), 600)

vbutton = GtkButton("vibrato") #make vibrato button
g[15:18, 3:4] = vbutton #keep under tempo button, next to rest durations
signal_connect(vibrato_button_clicked, vbutton, "clicked") #callback
set_gtk_property!(vbutton, :name, "wp") # set "style" of vibrato key
push!(GAccessor.style_context(vbutton), GtkStyleProvider(purplevib), 600)

tbutton = GtkButton("tempo") # make an "tempo" button
g[11:14, 3:4] = tbutton #keep under keyboard, next to note durations
signal_connect(tempo_button_clicked, tbutton, "clicked") # callback
set_gtk_property!(tbutton, :name, "wt")# set style of the "tempo" button
push!(GAccessor.style_context(tbutton), GtkStyleProvider(turqtempo), 600)

fbutton = GtkButton("flute") # make a "flute" button
g[19:22, 3:4] = fbutton #keep under keyboard next to tempo/vibrato buttons
signal_connect(flute_button_clicked, fbutton, "clicked") #callback
set_gtk_property!(fbutton, :name, "ws") # set style of the "flute" button
push!(GAccessor.style_context(fbutton), GtkStyleProvider(goldflute), 600)

rbutton = GtkButton("[REC]") # make a "record" button
g[23:26, 3:4] = rbutton #keep under keyboard, next to flute's button
signal_connect(rec_button_clicked, rbutton, "clicked")
set_gtk_property!(rbutton, :name, "wb")# set style of the "record" button
push!(GAccessor.style_context(rbutton), GtkStyleProvider(blackrec), 600)

#add note/rest selection buttons beneath note entry system
g[(1:2), 3] = note_header[1]
g[(1:2), 4] = note_header[2]
for i in 1:size(note_length,1) # add the note length keys to the grid
    key, time_played = note_length[i,1:2]
    b = GtkButton(key) # make a button for this key
    signal_connect((w) -> note_length_determined(time_played), b, "clicked") # callback
    g[(1:2) .+ 2*(i-1) .+ 2, 3] = b # put the button in row 3 of the grid
    set_gtk_property!(b, :name, "wh1")    # set style of the "note length" button
    push!(GAccessor.style_context(b), GtkStyleProvider(keystyle1), 600)
end
for i in 1:size(note_length,1) # add the rest entry keys to the grid
    key, time_played = note_length[i,1:2]
    b = GtkButton(key) # make a button for this key
    signal_connect((w) -> rest_length_determined(time_played), b, "clicked") # callback
    g[(1:2) .+ 2*(i-1) .+ 2, 4] = b # put the button in row 4 of the grid
    set_gtk_property!(b, :name, "wh2")    # set style of the "rest entry" button
    push!(GAccessor.style_context(b), GtkStyleProvider(keystyle2), 600)
end

#note entry keys
for i in 1:size(key_entry,1) # add the note entry keys to the grid
    key, midi = key_entry[i,1:2]
    b = GtkButton(key) # make a button for this key
    signal_connect((w) -> miditone(midi), b, "clicked") # callback
    g[(1:2) .+ 2*(i-1), 1:2] = b # put the button in row 1-2 of the grid
    set_gtk_property!(b, :name, "wl")    # set style of the "note entry" button
    push!(GAccessor.style_context(b), GtkStyleProvider(lavnotes), 600)
end

win = GtkWindow("gtk3", 400, 300) # 400×300 pixel window for all the buttons
push!(win, g) # put button grid into the window
showall(win); # display the window full of buttons