% Create enumerated data type to represent different correlation modes
classdef Correlation_Type
    properties
        mode = 'Pearson';
    end
    
    methods
        % Create constructor class
        function c = Correlation_Type(setmode)
            c.mode = setmode;
        end    
    end
    
    enumeration
        Pearson ('Pearson')
        Spearman ('Spearman')
    end
end

