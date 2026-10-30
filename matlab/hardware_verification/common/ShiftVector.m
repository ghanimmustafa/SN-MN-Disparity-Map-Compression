function out = ShiftVector(input_vector, shifted_amount)
out = zeros(size(input_vector));
out(shifted_amount+1:end)=input_vector(1:end-shifted_amount);

end