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

% bw = 1280; % Total bandwidth

conf.npreamble  = 35;
conf.bitsps     = 16;   % bits per audio sample
conf.offset     = 0;

conf.os_factor  = conf.f_s/(conf.f_spacing * conf.n_carriers);
Ng = 100;
conf.n_g = Ng/conf.n_carriers;

%
% Load BER and distance data if it exists

conf.f_spacing = 2;
conf.n_carriers = floor(bw / conf.f_spacing);
conf.os_factor = (conf.f_s / (conf.f_spacing * conf.n_carriers))

data_file = 'ber_distance_data.mat';
if isfile(data_file)
    load(data_file, 'ber_values', 'distance_values');
else
    ber_values = [];
    distance_values = [];
end

% Current distance from the speaker
initial_distance = 20; % cm
increment = 20; % cm
current_distance = initial_distance + increment * length(ber_values);

fprintf("Current Distance: %d cm\n", current_distance)
%


%BER and Spacing Tracking
data_file = 'ber_spacing_data.mat';
if isfile(data_file)
    load(data_file, 'ber_values', 'spacing_values');
else
    ber_values = [];
    spacing_values = [];
end

% Carrier Spacing
spacing_step = 1; % Hz
current_spacing = 1 + spacing_step * length(ber_values);

if current_spacing > 6
    error('BER vs. Spacing analysis is complete. Check ber_spacing_data.mat for results.');
end

fprintf("Current Spacing: %.1f Hz\n", current_spacing);


% Calculate number of carriers dynamically
conf.f_spacing = current_spacing
conf.n_carriers = floor(bw / conf.f_spacing);
conf.os_factor = (conf.f_s / (conf.f_spacing * conf.n_carriers))
%%

channels = zeros(conf.nframes, conf.n_carriers);


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
    
    
    % save("rx_signal.mat", 'rxsignal');
    % save("txbits.mat", 'txbits');
    
    % figure()
    % plot(rxsignal)
    % title("rxsignal")
    
    % rxsignal = rawtxsignal(:, 1);
    % load("rx_signal.mat");
    % load("txbits.mat")
    
    %freq offset simulation
    % [rxbits conf]       = ofdm_rx_freq_offset(rxsignal, conf, i);

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


    % Store BER and distance
    ber_values = [ber_values, ber];
    distance_values = [distance_values, current_distance];

    % Save data for future runs
    save(data_file, 'ber_values', 'distance_values');

    % Plot results if this is the 7th run
    if length(ber_values) == 7
        figure;
        plot(distance_values, ber_values, '-o', 'LineWidth', 1.5);
        title('BER vs. Distance');
        xlabel('Distance from Speaker (cm)');
        ylabel('Bit Error Rate (BER)');
        grid on;
    end
    %   

    %%
    % Store BER and spacing
    ber_values = [ber_values, ber];
    spacing_values = [spacing_values, current_spacing];

    % Save data for future runs
    save(data_file, 'ber_values', 'spacing_values');

    % Plot results if the maximum spacing has been reached
    if current_spacing >= 6
        figure;
        plot(spacing_values, ber_values, '-o', 'LineWidth', 1.5);
        title('BER vs. Spacing');
        xlabel('Carrier Spacing (Hz)');
        ylabel('Bit Error Rate (BER)');
        grid on;
    end
%% 
end