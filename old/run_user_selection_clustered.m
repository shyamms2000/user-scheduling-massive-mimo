MC = 10000;                                                                % Size of the outer Monte Carlo ensemble (Varies the channel realizarions)
L = 13;                                                                    % Number of selected users
snr_db = 10;                                                               % SNR in dB

for M = [64]                                                           % Number of antennas at the base station
    for K = [36 72]                                                           % Number of users at the cell
        for theta_mid = [0 pi/4]
            for theta_step = pi/180:pi/180:pi/9 
                run user_selection_clustered.m
            end
        end
    end
end