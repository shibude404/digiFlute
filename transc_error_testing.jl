#error testing
using Plots; 
using MAT: matread;
using Sound;

rows= [696, 770, 852, 940];
cols=[1208, 1336, 1476];
keypad=[1 2 3; 4 5 6; 7 8 9; 0 0 0];

x = cos.(2*pi*(1:N)/S*696) + cos.(2*pi*1208*(1:N)/S) #FIX
errors = zeros(Int, 10); snr = zeros(10)

for level in 1:10 # 10 different noise levels
	noisesum = 0;


	for trial in 1:100 # 100 trials for each noise level
		noise = 5 * level * randn(size(x))
		y = x + noise # this will be very noisy!
		noisesum += sum(abs2, noise) # sum of noise.^2
		# apply your transcriber to signal "y" here 
		cRow = cos.(2π/S * rows * (0:4095)') * y
		sRow = sin.(2π/S * rows * (0:4095)') * y
		corrRow = cRow.^2 + sRow.^2
		IRow = argmax(corrRow)

        cCol = cos.(2π/S * cols * (0:4095)') * y
		sCol = sin.(2π/S * cols * (0:4095)') * y
		corrCol = cCol.^2 + sCol.^2
		ICol = argmax(corrCol) #find col

		foundDig=keypad[IRow, ICol];
        

		if foundDig != 1
			errors[level] += 1 # count errors
		end
	end


	snr[level] = 10*log10(sum(abs2, x) / (noisesum/100))
end
p1=plot(snr, errors, marker=:circle, xlabel="SNR [db]", ylabel="% errors", title="Transcriber error rate vs. SNR", grid=false, legend=false)