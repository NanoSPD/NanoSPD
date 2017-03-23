
function analyze_filopodia(hObject, eventdata, handles)

% Get size of data struct, reuse filopodia/_max variable
[~,filopodia_max,~] = size(handles.data)

% Addressing the handles structure appears to cause trouble for parfor
% Copy entire struct out of the handles struct. 
data = handles.data
globals = handles.globals

if globals.MULTICORE == 0 %waitbar is not functional with parfor()
    wait = waitbar(0,'Processing data...');
else %must be YES
    matlabpool % initialize pool
    wait = 0; %fix for counter being uninitialized.
end

tic

for i = 1:filopodia_max    
    i % for debugging counter
    
    % Note that parfor appears to count down in reverse when matlabpools is
    % not called
    if globals.MULTICORE == 0   
        waitbar(i / filopodia_max, wait); % update waitbar
    end
    
    % To make parfor functional, need to copy data out of indexed array
    temp = data(i);
    temp.Include = 1; %includes all data in analysis by default

    % ==========================================================
    % PEAK FINDING + TRACE ALIGNMENT
    % ==========================================================

    % Copy data_array into data_array_raw. All of the aligning and trimming opeations will be mimicked on 
    % this data set, BUT IT WILL NOT BE NORMALIZED.
    temp.data_array_raw = temp.data_array;
    
    % Normalize bait signal to maximum value in track. WARNING MAX CAN BE TRICKED BY SPURIOUS PEAKS 
    [bait_max, bait_peak_index] = max(temp.data_array(:,2));  
    temp.data_array(:,2) = temp.data_array(:,2) / bait_max;
    temp.Max_Bait_Raw = bait_max; % USED FOR AMPLITUDE ANALYSIS. UNNORMALIZED
    
    % If signal is saturated max() will peak at the most left leading edge. 
    % If this is the case, find bait values in excess of .99 and take mean position as the true peak.
    condition = temp.data_array(:,2) >= 0.99;
    
    if sum(condition) >= 6  %specifies minimum peak width, not scaled to um
        indices = find(condition); %get indexes where > 0.99
        bait_peak_index = round(mean(indices)); %find average and round to nearest integer. Overwrites existing value.       
    end
    
    temp.Peaks(:,1) = [bait_peak_index, temp.data_array(bait_peak_index, 1)]; % Save peak position [index + um] into struct

    % TRIM SIGNAL ACCORDING TO ALIGN_WINDOW
    condition = temp.data_array(:,1) <= temp.Peaks(2) + globals.ALIGN_WINDOW(1);
    temp.data_array(condition,:)=[];
    temp.data_array_raw(condition,:)=[];

    % Update all distance measurements to the bait peak. 
    temp.data_array(:,1) = temp.data_array(:,1) - temp.Peaks(2);
    temp.data_array_raw(:,1) = temp.data_array_raw(:,1) - temp.Peaks(2);

    shift = sum(condition); % how many cells was the peak shifted?
    temp.Peaks(1) = temp.Peaks(1) - shift;  
    temp.Peaks(2) = temp.data_array(temp.Peaks(1), 1);

    % Delete signal more than ALIGNWINDOW(2) after the peak.
    condition = temp.data_array(:,1) >= temp.Peaks(2) + globals.ALIGN_WINDOW(2);
    temp.data_array(condition,:)=[];
    temp.data_array_raw(condition,:)=[];
   
    %Finally, normalize prey. Prey does not always have signal like bait, so normalization can be biased
    % by signals elsewhere in the trace. 
    [prey_max, ~] = max(temp.data_array(:,3));   
    temp.data_array(:,3) = temp.data_array(:,3) / prey_max;

    % ==========================================================
    % SIGNAL CONDITIONING
    % ==========================================================
    % Check that the data covers 90% of the ALIGN_WINDOW range
    diff = abs(temp.data_array(1,1) - temp.data_array(end,1));
    [elements,~] = size(temp.data_array);

    if diff <= 0.9 * abs(globals.ALIGN_WINDOW(1) - globals.ALIGN_WINDOW(2))
        temp.Include = 0; %This means the i is too short. Exclude it. 
        string = temp.Exclusion_Criteria; %Read current string, append to it.
        temp.Exclusion_Criteria = strcat(string, sprintf('\nData does not fully cover ALIGN_WINDOW'));
    end
    
    % Test data resolution
    if (diff / elements) > 0.15
        temp.Include = 0; %exclude it
        string = temp.Exclusion_Criteria; %Read current string, append to it.
        temp.Exclusion_Criteria = strcat(string, sprintf('\nData has too few data points'));
    end
    
    % Get mean within MEANWINDOW(1) to MEANWINDOW(2) 
    % The condition vector is also used to calculate means + stdevs for the thresholding analysis.
    condition = (temp.data_array(:,1) >= globals.MEAN_WINDOW(1)) & (temp.data_array(:,1) <= globals.MEAN_WINDOW(2));
    
    if sum(condition) <= 3 %There is not sufficient data to do a background average, filopodia was probably too short!!
        % Exclude this filopodia
        temp.Include = 0;
        % Why.
        string = temp.Exclusion_Criteria; %Read current string, append to it.
        temp.Exclusion_Criteria = strcat(string, sprintf('\nToo few data point in MEAN_WINDOW region'));
    else
        % There is sufficient data, so do the analysis. Calc mean + stdevs of the filopodial background 
        means = mean(temp.data_array(condition,:));
        stdevs = std(temp.data_array(condition,:));
   
        % Update struct with threshold values
        temp.Bait_Threshold = (means(2)+ (globals.SD*stdevs(2)));
        temp.Prey_Threshold = (means(3)+ (globals.SD*stdevs(3)));
        
        % Compare bait to threshold
        if temp.data_array(temp.Peaks(1),2) >= temp.Bait_Threshold
            temp.Bait_Positive = 1;
        else
            % Bait is not sufficiently above background
            temp.Bait_Positive = 0;
            
            % Exclude from analysis, since there was no bait accumulation.             
            temp.Include = 0;
            string = temp.Exclusion_Criteria; %Read current string, append to it.
            temp.Exclusion_Criteria = strcat(string, sprintf('\nBait fails to meet threshold'));
        end 
     
        % Find the maximum prey signal, within the interval (-PREY_WOBBLE =< x =< +PREY_WOBBLE ).
        % Compare to pre threshold
        condition = (temp.data_array(:,1) >= -globals.PREY_WOBBLE) & (temp.data_array(:,1) <= globals.PREY_WOBBLE);
        max_prey = max(temp.data_array(condition,3));
        temp.Max_Prey_Raw = max(temp.data_array_raw(condition,3)); % FOR AMPLITUDE ANALYSIS
        
        if max_prey >= temp.Prey_Threshold
            temp.Prey_Positive = 1;
        else
            temp.Prey_Positive = 0;
        end
        
     
        %%%%%%%%%%%%%%%%%%%%%%%%%%%
        % XCORR ANALYSIS
        %%%%%%%%%%%%%%%%%%%%%%%%%%%

        % Calculate XCorr, store result in struct. Store max XCorr value too.
        [temp.XCorr(:,1), temp.XCorr(:,2)] = xcorr(temp.data_array(:,2), temp.data_array(:,3), 'coeff');
        [temp.Max_XCorr, ~] = max(temp.XCorr(:,1));
    
        
        
        %###########################################
        %Permutation Test by prey randomization
        %###########################################
    
        %Calculate Rho - unscrambled
        temp.Rho = corr(temp.data_array(:,2),temp.data_array(:,3), 'type', globals.CORR_TYPE.mode);
    
        %Calculate block size and convert data to a cell array
        
        % pixel size (assuming linear spacing of first pair).
        pixel = temp.data_array(1:2,1);
        pixel = abs(pixel(1) - pixel(2));
        block_size = floor(globals.BLOCK_SIZE / pixel);
      
        [temp1, ~] = size(temp.data_array);
        blocks = floor(temp1 ./ block_size); % number of block required in cell array
        bait_data = cell(blocks,1); %create cell array. 
        prey_data = cell(blocks,1); %create cell array.
   
        for j = 1:blocks
            bait_data{j,:,1} = temp.data_array( (((j-1)*block_size)+1):j*block_size, 2); %loads bait only
            prey_data{j,:,1} = temp.data_array( (((j-1)*block_size)+1):j*block_size, 3); %loads prey only
        end    
        
        
        %Convert bait_data back to a regular array. 
        bait_data = cell2mat(bait_data);
    
        %Randomize prey many times, calculate Rho for each permutation
        temp.Rho_array = zeros(globals.BLOCK_TRIALS,1);
   
        for j = 1:globals.BLOCK_TRIALS
            %Randomize cell array
            perm_index = randperm(length(prey_data));
            scrambled_prey_data = prey_data(perm_index);
    
            %Convert scrambled cell array back to regular array
            scrambled_prey_data = cell2mat(scrambled_prey_data);
        
            %Calc new Rho value
            [temp.Rho_array(j), ~] = corr(bait_data(:,1), scrambled_prey_data(:,1), 'type', globals.CORR_TYPE.mode);        
        end
    
        %Calculates the P-value for rejecting the null hypothesis. 
        temp.Rho_pval = prctile(temp.Rho_array, globals.PERCENTILE);
    
        %Assess INTERACTION BY Rho significance flag. 
        if(temp.Rho >= temp.Rho_pval)
            temp.Rho_interact = 1;
        else
            temp.Rho_interact = 0;
        end 
      
        % Calculate ~ FWHM of bait signal (assume that background is 0)
        % smoothing?
        fwhm_condition = temp.data_array(:,2) >= 0.5;
        fwhm_condition = bwlabel(fwhm_condition); % categorized connected '1's
        category = fwhm_condition(temp.Peaks(1)); % which object intersects the peak?
        fwhm_condition = fwhm_condition(:) == category; %select all objects connected to peak. This is the FWHM.
        
        if (sum(fwhm_condition) * pixel) >= globals.FWHM
            temp.Include = 0; %exclude it
             
            string = temp.Exclusion_Criteria; %Read current string, append to it. 
            temp.Exclusion_Criteria = strcat(string, sprintf('\nBait exceeds FWHM'));
        end    
    end
    
    %###########################################
    % FINAL ASSESSMENT OF CONSENSUS INTERACTION
    %###########################################
    if temp.Include == 1 %if data is still included
        %Test interaction depending upon user mode selected
        switch globals.INTERACTION_MODE.mode
            case 'Threshold' % Threshold only
                if temp.Prey_Positive & temp.Bait_Positive
                    temp.Consensus_interact = 1;
                else
                    temp.Consensus_interact = 0;
                end
                
            case 'Correlation' % Correlation only
                if temp.Rho_interact == 1
                    temp.Consensus_interact = 1;
                else
                    temp.Consensus_interact = 0;
                end
                
            case 'Thres_plus_Corr' % Threshold + Correlation
                if temp.Prey_Positive & temp.Bait_Positive & temp.Rho_interact
                    temp.Consensus_interact = 1;
                else
                    temp.Consensus_interact = 0;
                end  
        end    
    else %data is not included
        temp.Consensus_interact = 0; % no interaction....but not strictly neccessary.
    end
    
    % PARFOR - copy temp struct back into array
    data(i) = temp;
    
end

toc

% ##############################################################
% PARFOR CLEAN UP 
% ##############################################################

if globals.MULTICORE == 0 
    close(wait);
else %must be YES
    matlabpool close
end

% Copy full array back into handles structure
handles.data = data
guidata(hObject,handles);

%Initialize the slider according to the number of filopodia analyzed
set(handles.slider2,'Min', 1, 'Value', 1, 'Max', filopodia_max, 'SliderStep', [1/(filopodia_max-1), 1/(filopodia_max-1)]);
slider2_Callback(hObject, eventdata, handles); % Call slider2 function to update graphs and status window.  

end


