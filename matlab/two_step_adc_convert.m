function D_out = two_step_adc_convert(Vin, N_stage, Vref)
%TWO_STEP_ADC_CONVERT  Ideal two-step (sub-ranging) flash ADC conversion.
%   D_out = TWO_STEP_ADC_CONVERT(Vin, N_stage, Vref) converts each element of
%   Vin to a (2*N_stage)-bit code. The loop body is identical to the one in
%   two_step_adc_model.m; it is packaged as a function so the sweep-step
%   study can call it with different input grids.

D_out = zeros(size(Vin));
for i = 1:length(Vin)
   LSB_c = Vref / (2^N_stage);                     % coarse-stage LSB
   D_coarse = floor(Vin(i) / LSB_c);               % coarse quantizer
   D_coarse = min(D_coarse, 2^N_stage - 1);        % clamp to 4-bit range
   V_dac = D_coarse * LSB_c;                       % DAC reconstruction
   V_residue = (Vin(i) - V_dac) * (2^N_stage);     % subtract and amplify (x16)
   D_fine = floor(V_residue / LSB_c);              % fine quantizer
   D_fine = min(D_fine, 2^N_stage - 1);            % clamp to 4-bit range
   D_out(i) = (D_coarse * 2^N_stage) + D_fine;     % digital recombination
end
end
