% Create enumerated data type to represent different interaction modes
classdef Interaction_Mode
    properties
        mode = 'Threshold';
    end
    
    methods
        % Create constructor class
        function c = Interaction_Mode(setmode)
            c.mode = setmode;
        end    
    end
    
    enumeration
        Threshold ('Threshold')
        Correlation ('Correlation')
        Threshold_plus_Correlation ('Thres_plus_Corr')
    end
end

