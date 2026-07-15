function [sumBit, carryBit] = full_adder(a, b, cin)
%FULL_ADDER Simulates a one-bit full-adder
%
% Inputs:
%   a   - First binary input
%   b   - Second binary input
%   cin - Carry input
%
% Outputs:
%   sumBit   - Sum output
%   carryBit - Carry output
%
% The function supports scalar values and equally sized vectors.
    validate_binary_input(a, "a");
    validate_binary_input(b, "b");
    validate_binary_input(cin, "cin");

    %Convert numeric binary values to logical values.
    a = logical(a);
    b = logical(b);
    cin = logical(cin);

    %Full-Adder equations
    sumBit = xor(xor(a, b), cin);
    carryBit = (a & b) | ...
                (a & cin) | ...
                (b & cin);

    %Convert logical result back to numeric 0 and 1
    sumBit = double(sumBit);
    carryBit = double(carryBit);

end

function validate_binary_input(value, inputName)
%Validate_Binary_Input Ensures an input contains only zeros and ones.
    if ~(isnumeric(value) || isLogical(value))
        error("%s must be numeric or logical.", inputName);
    end

    if any(~ismember(value(:), [0, 1]))
        error("%s must contain onyl binary values 0 and 1.", inputName);
    end
end
