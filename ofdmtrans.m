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
conf.pilot_frequency = 1;

conf.npreamble  = 100;
conf.bitsps     = 16; % bits per audio sample
conf.offset     = 0;
conf.redondancy = 1;

conf.os_factor  = conf.f_s/(conf.f_spacing * conf.n_carriers);
Ng = 128;
conf.n_g = Ng/conf.n_carriers;

channels = zeros(conf.nframes, conf.n_carriers);

for i = 1:conf.nframes
    fprintf("sending frame %d\n", i)
    
    %sending image
    [txbits, real_length] = image_to_binary("shrek.jpg", conf.n_carriers);
    
    conf.n_ofdm_symbols = (length(txbits) / (2*conf.n_carriers));
    
    % length(bits)
    
    % Generate random data
    % txbits = randi([0 1], conf.n_ofdm_symbols * conf.n_carriers * 2, 1);
    % txbits_redondancy = repelem(txbits, conf.redondancy);
    
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
    
    grouped_bits = reshape(rxbits, conf.redondancy, []);
    
    rxbits = sum(grouped_bits, 1) >= ceil(conf.redondancy / 2);
    rxbits = rxbits.';
    
    
    %image decoding
    rxbits = rxbits(1:real_length);
    % % save('rxbits.mat', "rxbits")
    % % rxbits = load('rxbits.mat').rxbits.';
    % size(rxbits)
    image_from_binary(rxbits, 256)
    
    
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

