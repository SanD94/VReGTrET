% Helper function for if-else in fprintf
function r = iif(condition, trueResult, falseResult)
    if condition
        r = trueResult;
    else
        r = falseResult;
    end
end