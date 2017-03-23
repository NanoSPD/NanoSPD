% Create enumerated data type to represent different interaction modes
classdef Data_Type
    properties
        mode = 'Dist:Bait:Prey';
    end
    
    methods
        % Create constructor class
        function c = Data_Type(setmode)
            c.mode = setmode;
        end    
    end
    
    enumeration
        Linescan_D_B_P ('Dist:Bait:Prey')
        Linescan_D_P_B ('Dist:Prey:Bait')
    end
end

