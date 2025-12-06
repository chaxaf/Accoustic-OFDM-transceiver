clc
% Configuration Values
conf.audiosystem = 'matlab'; % Values: 'matlab','native','bypass'

conf.f_s     = 48000;   % sampling rate
conf.f_sym   = 100;     % symbol rate
conf.nframes = 1;       % number of frames to transmit
% conf.nbits   = 2000;    % number of bits
conf.n_ofdm_symbols = 10;
conf.modulation_order = 2; % BPSK:1, QPSK:2
conf.f_c     = 4000;
conf.n_carriers = 256;
conf.f_spacing = 5;

conf.npreamble  = 100;
conf.bitsps     = 16;   % bits per audio sample
conf.offset     = 0;
conf.n_channel_training = 200;


conf.os_factor  = conf.f_s/(conf.f_spacing * conf.n_carriers);
conf.n_g = 0.5;


for i = 1:conf.nframes
    
    
    % Generate random data
    % txbits = randi([0 1], conf.n_ofdm_symbols * conf.n_carriers * 2, 1);
    
    % channels measurements
    txbits = lfsr_framesync(conf.n_channel_training * conf.n_carriers); % 1 is encoded as -1, 0 is 1
    txbits_bpsk = 1 - 2*txbits;
    % size(txbits)
    % txbits = 1-2*ones(1, conf.n_channel_training * conf.n_carriers).';
    % size(txbits)
    
    % TODO: Implement tx() Transmit Function
    [txsignal conf] = ofdm_tx_channel(txbits_bpsk, conf);
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
    
    
    
    
    [rxbits conf channels auto_cors]       = ofdm_rx_channel(rxsignal, conf, txbits_bpsk);
    % max(abs(rxbits - txbits))
    rxnbits      = length(rxbits);
    % % size(txbits)
    biterrors    = sum(rxbits ~= txbits);
    ber = biterrors/sum(rxnbits)
    diff = rxbits ~= txbits;
    
    
end

% channels

% size(auto_cors)

avg_channel = mean(auto_cors, 2);
% size(avg_channel)
pdp = ifft(avg_channel);
db = 10*log10(abs(real(pdp(1:conf.n_carriers))));
save('pdp_exterior.mat','db')
save('channels_exterior', 'channels')
bar(db)
% plot()
% mag_channel = sqrt(real(avg_channel).^2 + imag(avg_channel).^2);
% mag_channel = repelem(mag_channel, conf.f_spacing);
% plot(mag_channel)

% plot(diff)
% window_size = 100; % Window size
% num_bins = ceil(length(diff) / window_size); % Number of bins
% counts = zeros(1, num_bins); % Initialize count storage

% % Count the number of 1s in each window
% for i = 1:num_bins
%     start_idx = (i-1)*window_size + 1; % Start index of the window
%     end_idx = min(i*window_size, length(diff)); % End index of the window
%     counts(i) = sum(diff(start_idx:end_idx) == 1); % Count 1s in the window
% end

% % Plot the histogram
% figure;
% bar(1:num_bins, counts);
% xlabel('Window (100 positions)');
% ylabel('Count of 1s');
% title('Histogram of 1s count every 100 positions');
% grid on;