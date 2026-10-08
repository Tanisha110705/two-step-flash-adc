function [code_transitions, DNL, INL] = transition_linearity(Vin, D_out, N, LSB)
%TRANSITION_LINEARITY  DNL/INL from a swept-input transfer characteristic.
%   Uses the same method as two_step_adc_model.m: the transition voltage of
%   code k is the first swept input whose output code is >= k. DNL is the
%   normalised spacing of consecutive transitions minus one, with a leading
%   zero for code 0; INL is the cumulative sum of DNL.

num_codes = 2^N;
code_transitions = zeros(1, num_codes);
for k = 0:num_codes-1
   idx = find(D_out >= k, 1);
   if ~isempty(idx)
       code_transitions(k+1) = Vin(idx);
   end
end
actual_steps = diff(code_transitions);
DNL = (actual_steps - LSB) / LSB;
DNL = [0, DNL];
INL = cumsum(DNL);
end
