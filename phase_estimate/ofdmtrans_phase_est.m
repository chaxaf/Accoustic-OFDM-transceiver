clc
% Configuration Values
conf.audiosystem = 'matlab'; % Values: 'matlab','native','bypass'

conf.f_s     = 48000;   % sampling rate
conf.f_sym   = 100;     % symbol rate
conf.nframes = 1;       % number of frames to transmit
% conf.nbits   = 2000;    % number of bits
conf.n_ofdm_symbols = 100;
conf.modulation_order = 2; % BPSK:1, QPSK:2
conf.f_c     = 4000;
conf.n_carriers = 256;
conf.f_spacing = 5;
conf.pilot_frequency = 0;

conf.npreamble  = 100;
conf.bitsps     = 16;   % bits per audio sample
conf.offset     = 0;

conf.os_factor  = conf.f_s/(conf.f_spacing * conf.n_carriers);
Ng = 35;
conf.n_g = Ng/conf.n_carriers;

channels = zeros(conf.nframes, conf.n_carriers);

conf.pll_gain = 0.05;      % Adjust based on dynamics
conf.initial_phase = 0;    % Assume initial phase is 0
conf.max_iterations = 10000; % Stabilization parameter

for i = 1:conf.nframes
    fprintf("sending frame %d\n", i)
    
    % Generate random data
    txbits = randi([0 1], conf.n_ofdm_symbols * conf.n_carriers * 2, 1);
    % size(txbits)
    
    % TODO: Implement tx() Transmit Function
    %freq offset simulation
    % [txsignal conf] = ofdm_tx_freq_offset(txbits, conf, i);
    [txsignal conf] = ofdm_tx(txbits, conf);
    % normalize values
    peakvalue       = max(abs(txsignal));
    normtxsignal    = txsignal / (peakvalue);
    % size(txsignal)
    
    % create vector for transmission
    rawtxsignal = [ zeros(conf.f_s,1) ; normtxsignal ;  zeros(conf.f_s,1) ]; % add padding before and after the signal
    rawtxsignal = [  rawtxsignal  zeros(size(rawtxsignal)) ]; % add second channel: no signal
    txdur       = length(rawtxsignal)/conf.f_s; % calculate length of transmitted signal
    % plot(rawtxsignal)
    % title("tx signal")
    % % audiowrite('out.wav', rawtxsignal, conf.f_s)
    
    
    disp('MATLAB generic');
    playobj = audioplayer(rawtxsignal, conf.f_s, conf.bitsps);
    recobj  = audiorecorder(conf.f_s, conf.bitsps, 1);
    record(recobj);
    disp('Recording in Progress');
    playblocking(playobj)
    pause(0.5);
    stop(recobj);
    disp('Recording complete')
    rawrxsignal  = getaudiodata(recobj, 'int16');
    rxsignal     = double(rawrxsignal(1:end))/double(intmax('int16')) ;

    % --- PLL Phase Tracking ---
    [corrected_signal, phase_estimates] = pll_phase_tracking(rxsignal, conf);

    % Visualize PLL Phase Estimates
    figure;
    plot(phase_estimates);
    title('PLL Phase Estimates');
    xlabel('Sample Index');
    ylabel('Phase (radians)');
    % --- Compare Signal Before and After Phase Correction ---
    % Plot real part of the received signal (before correction)
    figure;
    subplot(2, 1, 1);
    plot(real(rxsignal(1:500))); % Plot the first 500 samples
    title('Received Signal (Before Phase Correction)');
    xlabel('Sample Index');
    ylabel('Amplitude');
    grid on;

    % Plot real part of the corrected signal
    subplot(2, 1, 2);
    plot(real(corrected_signal(1:500))); % Plot the first 500 samples
    title('Received Signal (After Phase Correction)');
    xlabel('Sample Index');
    ylabel('Amplitude');
    grid on;
    % --- End PLL Phase Tracking ---
    
    
    % save("rx_signal.mat", 'rxsignal');
    % save("txbits.mat", 'txbits');
    
    figure()
    plot(rxsignal)
    title("rxsignal")
    
    % rxsignal = rawtxsignal(:, 1);
    % load("rx_signal.mat");
    % load("txbits.mat")
    
    %freq offset simulation
    % [rxbits conf]       = ofdm_rx_freq_offset(rxsignal, conf, i);
    
    % --- BER Calculation Before and After Phase Correction ---

% Decode the raw received signal (without phase correction)
[rxbits_raw, conf] = ofdm_rx(rxsignal, conf);
rxnbits_raw = length(rxbits_raw);
diff_raw = rxbits_raw ~= txbits;
biterrors_raw = sum(diff_raw);
ber_raw = biterrors_raw / rxnbits_raw;
fprintf("BER (Before Phase Correction): %f\n", ber_raw);

% Decode the phase-corrected signal
[rxbits_corrected, conf] = ofdm_rx(corrected_signal, conf);
rxnbits_corrected = length(rxbits_corrected);
diff_corrected = rxbits_corrected ~= txbits;
biterrors_corrected = sum(diff_corrected);
ber_corrected = biterrors_corrected / rxnbits_corrected;
fprintf("BER (After Phase Correction): %f\n", ber_corrected);

% Plot a comparison
figure;
bar([ber_raw, ber_corrected]);
xticks([1, 2]);
xticklabels({'Before Phase Correction', 'After Phase Correction'});
ylabel('Bit Error Rate (BER)');
title('BER Comparison');
grid on;


    %normal transmission
    [rxbits conf]       = ofdm_rx(rxsignal, conf);
    % max(abs(rxbits - txbits))
    rxnbits      = length(rxbits);
    % size(txbits)
    diff = rxbits ~= txbits;
    biterrors    = sum(diff);
    ber = biterrors/sum(rxnbits)
    if biterrors ~= 0
        idx = find(biterrors, 1, 'first');
        ofdm_symbol_index = ceil(idx / conf.n_carriers)
    end
    
    
end

