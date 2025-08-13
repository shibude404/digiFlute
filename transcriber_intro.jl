using WAV: wavread
using Gtk
using Plots

#This program looks at an individual note and compares its frequency to the expected value

#use envelope to break song into notes
function envelope(x2) #From lecture notes
	w = 201
	h = 100 # sliding window half-width (default 100)
	x2 = abs.(x2) # absolute value is crucial!
	avg(v) = sum(v) / length(v) # function for (moving) average
	for n in 1:length(x2)
		ret=[avg(x2[max(n-h,1):min(n+h,end)])]
	end
	return ret
end

#This function determines how many notes were played and pairs up the start and stop indexes of each note
function findNotes(xFind)
  env = envelope(xFind)
  env /= maximum(env)
  threshold = 0.03 #May have to be adjusted 
  playing = env .> threshold
  start=zeros(length(xFind))
  stop=zeros(length(xFind))
  notes=0;

  #create arrays of when a note begins and ends
  for i in 1:length(xFind)-1
    if playing[i]<=playing[i+1]
      start[i+1]=1;
      notes=notes+1;
    elseif playing[i]>=playing[i+1]
      stop[i]=1;
    end
    
  end

  #pair up start and stopping
  pairs=zeros(2, notes)
  currentA=1;
  currentB=1;
  for i in 1:notes

    if start[i]==1
      pairs[1, currentA]=playing[i]
      currentA=currentA+1;
   
    elseif stop[i]==1
      pairs[2, currentB]=playing[i]
      currentB=currentB+1;
    end
  end

  return notes, pairs, start
end

#tests duration accuracy by comparing number of samples in comparared notes
function accurateDur(subX, subY)
  lenX=length(subX)
  lenY=length(subY)
  tolerance=0.03; #must be accurate within 3%
  durRight=false;

  if((lenY-lenY*tolerance) <= lenX <= (lenY+lenY*tolerance ))
    durRight=true;
  end

  return durRight
end

#autocorrelation method for determining frequency
function findFreq(auto::Int, Sf::Int)
  big = auto .> 0.8 # find large values
  big[1:findfirst(==(false), big)] .= false # ignore peak near m=0
  peak2start = findfirst(==(true), big1)
  peak2end = findnext(==(false), big1, peak2start) # end of 2nd peak
  m = peak2start:peak2end
  big1[peak2end:end] .= false # ignore everything to right of 2nd peak
  m = argmax(big1 .* autocorr) - 1
  f = round(Sf/m, digits=2)
end


#Pitch accuracy between two notes
function accurateFreq(subX, subY, S)
  autocorr1 = real(ifft(abs2.(fft([subX; zeros(size(subX))])))) / sum(abs2, subX)
  autocorr2 = real(ifft(abs2.(fft([subY; zeros(size(subY))])))) / sum(abs2, subY)
  fUser=findFreq(autocorr1,S)
  fExpected=findFreq(autocorr2, S)

  rf=fUser/fExpected
  freqRight=false;

  centDiff=1200*log(rf)/log(2) #calculates how many cents the frequencies are seperated by

  if(abs(centDiff)<=12) #tolerance of 12 cents
    freqRight=true;
  end

  return freqRight, fUser, fExpected
end

#Determines pitch steadiness
function accurateStead(note, S)
  subN=length(note)/8; 
  numSamp=(length(note)-mod(length(note), subN))/subN; #Determines number of samples of length N/8 we can pull out of note
  freqVec=zeros(numSamp)

  #Uses autocorrelation to determine pitch of sub-samples
  for i in 1:numSamp
    N0=(i-1)*subN+1;
    Nf = N0 + subN-1;
    subNote=note[N0:Nf]

    freqVec=[1:numSamp]
    subAutocorr=real(ifft(abs2.(fft([subNote; zeros(size(subNote))])))) / sum(abs2, subNote)
    freqVec[i]=findFreq(subAutocorr, S)
  end
    
  #comparison of sub-sample frequencies
  for i = 2:length(freqVec)
    rf=(freqVec[i-1])/(freqVec[i])
    diff=1200*log(rf)/log(2)
    if(abs(diff) >= 7)
      steadRight=false
  end

  return steadRight
end
end #For some unknown reason this would not run without a 2nd "end" here


#Uses the other functions to determine total score and generate outputs
function transcriber(file1, file2)
	(x,S)=wavread(file1) #User recording
	(y,S2)=wavread(file2) #Synthesized recording

	(xNotes, xPairs, startU) = findNotes(x)
	(yNotes, yPairs, startE) = findNotes(y)
	
	#we ran into issues if the number of notes differed between files
	if yNotes!=xNotes
	  yNotes=xNotes
	end

	uScore=0.0; #user score
	pScore=0.0;
	fUser=zeros(xNotes)
	fExp=zeros(xNotes)

	#Breaks down each recording into individual notes, using the calculated pairs
	for i in 1:xNotes
	  subX=x[xPairs[1,i]:xPairs[2,i]]
	  subY=y[yPairs[1,i]:yPairs[2,i]]

	  #Calculation of scores
	  uDur=accurateDur(subX, subY)
	  (uFreq, fUser[i], fExp[i])=accurateFreq(subX, subY, S) #the variables fUser and fExp will be necessary later on
	  uStead=accurateStead(subX, S)

	  uScore+=uDur+uFreq+uStead
	  pScore+=3

	end  

	percentScore=(uScore/pScore)*100;

	#show the percent score
	win=GtkWindow("Final Scores", 300, 300)
	vbox=GtkBox(:v)
	push!(win, vbox)

	totalLab=GtkLabel("Your overall score is " * string(percentScore) * "%");
	totalPitch=GtkLabel("Your Pitch Accuracy was " * string(uFreq/(pScore/3)) * "%");
	totalDur=GtkLabel("Your Duration Accuracy was " * string(uDur/(pScore/3)) * "%");
	totalStead=GtkLabel("Your Note Steadiness was " * string(uStead/(pScore/3)) * "%");

	push!(vbox,totalLab);
	push!(vbox,totalPitch);
	push!(vbox,totalDur);
	push!(vbox,totalStead);

	#Graphical display
	V = [0 .5 .75 1 1.25 1.5 1.75 2 2.5 2.75 3 3.25 3.5 4 4.25 4.5]
	midiU=69.0 .+  12 * log2.(fUser./440)
	midiE=69.0 .+  12 * log2.(fExp./440)

	midiU=round.(midiU)
	midiE=round.(midiE)

	vU=V[Int.(midiU) .- 63]
	vE=V[Int.(midiE) .- 63]

	#Create an array of how many quarter notes each note occupies
	startingU=round((4*startU)/S)
	startingE=round((4*startE)/S)

	vUD=zeros(sum(startingU))
	vED=zeros(sum(startingE))

	#length of notes for graphs
	n=1;

	#creates an array where the start of the note will be displayed and a (-1) value is assigned to held notes
	for i in 1:startingU
		if startingU[i]==1
			vUD[n]=vU[i]
			n=n+1;
		elseif startingU[i]==2
			vUD[n]=vU[i];
			vUD[n+1]=-1;
			n=n+2;
		elseif startingU[i]==3
			vUD[n]=vU[i];
			vUD[n+1:n+2]=-1;
			n=n+3;
		elseif startingU[i]==4
			vUD[n]=vU[i];
			vUD[n+1:n+3]=-1;
			n=n+4;
		elseif startingU[i]==5
			vUD[n]=vU[i];
			vUD[n+1:n+4]=-1;
			n=n+5;
		end
	end

	n=1;
	#As we only provide quarter, half, or whole notes, less options are needed
	for i in 1:startingE
		if startingE[i]==1
			vED[n]=vE[i];
			n=n+1;
		elseif startingE[i]==2
			vED[n]=vE[i];
			vED[n+1]=-1;
			n=n+2;
		elseif startingE[i]==4
			vED[n]=vE[i];
			vED[n+1:n+3]=-1;
			n=n+4;
		end
	end

	#plot final results
	plot(vE, line=:stem, marker=:circle, markersize = 10, color=:black, label="Expected Note")
	plot!(vUD, line=:stem, marker=:circle, markersize = 10, color=:red, label="Played Note")
end