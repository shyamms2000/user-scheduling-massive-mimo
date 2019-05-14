clear;
close all;
clc;

addpath('./functions/')

root_downlink = './results/downlink/rate_downlink_auto_scheduling_mf_';
root_uplink   = './results/uplink/rate_uplink_auto_scheduling_mf_';

MC    = 10000;                                                             % Size of the outer Monte Carlo ensemble (Varies the channel realizarions)
N_ALG = 2;

M = 64;                                                                    % Number of antennas at the base station
K = 18;                                                                    % Number of users at the cell

commcell.nAntennas       = M;                                              % Number of Antennas
commcell.nUsers          = K;                                              % Number of Users
commcell.radius          = 200;                                            % Cell's raidus (circumradius) in meters
commcell.bsHeight        = 32;                                             % Height of base station in meters
commcell.userHeight      = [1 2];                                          % Height of user terminals in meters ([min max])
commcell.nPaths          = 30;                                             % Number of Multipaths
commcell.frequency       = 1.9e9;                                          % Carrier frequency in Hz
commcell.meanShadowFad   = 0;                                              % Shadow fading mean in dB
commcell.stdDevShadowFad = 8;                                              % Shadow fading standard deviation in dB
commcell.city            = 'large';                                        % Type of city

linkprop.bsPower         = 10;                                             % in Watts
linkprop.userPower       = 0.2;                                            % in Watts
linkprop.AntennaGainBS   = 0;                                              % in dBi
linkprop.AntennaGainUser = 0;                                              % in dBi
linkprop.noiseFigureBS   = 9;                                              % in dB
linkprop.noiseFigureUser = 9 ;                                             % in dB
linkprop.bandwidth       = 20e6;                                           % in Hz

[snr_u_db,snr_d_db] = linkBudgetCalculation(linkprop);                     % SNR in dB
                
beta_db = -135;

% snr_u_eff = round(snr_u_db + beta_db);
% snr_d_eff = round(snr_d_db + beta_db);

snr_u_eff = 20;
snr_d_eff = 20;

snr_u = 10.^((snr_u_eff)/10);                                              % Uplink SNR
snr_d = 10.^((snr_d_eff)/10);                                              % Downlink SNR

tau = 0.2;

% Initialization

L = zeros(MC,N_ALG);

user_set = cell(MC,N_ALG);

gamma_u_alg = cell(MC,N_ALG);
gamma_d_alg = cell(MC,N_ALG);

rate_u_alg = cell(MC,N_ALG);
rate_d_alg = cell(MC,N_ALG);

psi_alg = cell(MC,N_ALG);

channel_type = 'ur-los';

for mc = 1:MC
    mc
    
    [G,beta] = massiveMIMOChannel(commcell,channel_type);
    
    % Correlation-based Selection
    
    [user_set{mc,1},H_cbs] = userScheduling(G,'correlation-based selection','automatic',[],tau);
    
    L(mc,1) = size(H_cbs,2);
    
    h_norm_cbs     = vecnorm(H_cbs);
    h_norm_cbs_mtx = repmat(h_norm_cbs,M,1);
    
    H_norm_cbs = H_cbs./h_norm_cbs_mtx;    
    
    Q_mf_cbs = H_norm_cbs;
    W_mf_cbs = conj(H_norm_cbs);

    pow_upl_cbs = ones(L(mc,1),1);
    pow_dow_cbs = ones(L(mc,1),1)/L(mc,1);
                                                
    [rate_u_alg{mc,1},gamma_u_alg{mc,1}] = rateCalculation(H_cbs,Q_mf_cbs,pow_upl_cbs,snr_u,'uplink');
    [rate_d_alg{mc,1},gamma_d_alg{mc,1}] = rateCalculation(H_cbs,W_mf_cbs,pow_dow_cbs,snr_d,'downlink');

    psi_alg{mc,1} = ici(H_cbs);
    
    % ICI-based Selection
    
    [user_set{mc,2},H_icibs] = userScheduling(G,'ici-based selection','automatic',[],tau);
    
    L(mc,2) = size(H_icibs,2);
    
    h_norm_icibs     = vecnorm(H_icibs);
    h_norm_icibs_mtx = repmat(h_norm_icibs,M,1);
    
    H_norm_icibs = H_icibs./h_norm_icibs_mtx;    
    
    Q_mf_icibs = H_norm_icibs;
    W_mf_icibs = conj(H_norm_icibs);

    pow_upl_icibs = ones(L(mc,2),1);
    pow_dow_icibs = ones(L(mc,2),1)/L(mc,2);
    
    [rate_u_alg{mc,2},gamma_u_alg{mc,2}] = rateCalculation(H_icibs,Q_mf_icibs,pow_upl_icibs,snr_u,'uplink');
    [rate_d_alg{mc,2},gamma_d_alg{mc,2}] = rateCalculation(H_icibs,W_mf_icibs,pow_dow_icibs,snr_d,'downlink');

    psi_alg{mc,2} = ici(H_icibs);
end

save([root_downlink channel_type '_M_' num2str(M) '_K_' num2str(K) '_tau_' num2str(tau) '_SNR_' num2str(snr_u_eff) '_dB_MC_' num2str(MC) '.mat'], ...
      'gamma_d_alg','rate_d_alg','user_set','psi_alg','L');

save([root_uplink channel_type '_M_' num2str(M) '_K_' num2str(K) '_tau_' num2str(tau) '_SNR_' num2str(snr_u_eff) '_dB_MC_' num2str(MC) '.mat'], ...
      'gamma_u_alg','rate_u_alg','user_set','psi_alg','L');