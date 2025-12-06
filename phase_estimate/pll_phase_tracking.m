function [corrected_signal, phase_estimates] = pll_phase_tracking(rx_signal, conf)

    % Configuration Parameters
    pll_gain = conf.pll_gain; % Gain of the loop filter
    initial_phase = conf.initial_phase; % Initial phase guess
    max_iterations = conf.max_iterations; % Prevent runaway corrections
    num_samples = length(rx_signal);

    % Initialize Variables
    phase_estimates = zeros(1, num_samples);
    phase_estimates(1) = initial_phase; % Start with initial phase
    corrected_signal = zeros(size(rx_signal));

    % PLL Loop
    for n = 1:num_samples
        % Current phase estimate
        current_phase = phase_estimates(n);
        
        % Generate local reference
        local_ref = exp(-1j * current_phase);
        
        % Correct the received signal
        corrected_signal(n) = rx_signal(n) * conj(local_ref);
        
        % Estimate the phase error
        phase_error = angle(rx_signal(n) * conj(local_ref));
        
        % Adaptive gain for better dynamic response
        dynamic_gain = pll_gain * (1 - exp(-n / max_iterations));
        
        % Update phase estimate
        if n < num_samples
            phase_estimates(n + 1) = current_phase + dynamic_gain * phase_error;
        end
    end
end

