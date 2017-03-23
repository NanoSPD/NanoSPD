
function slider2_Callback(hObject, eventdata, handles)

% Get the new slider value
slider = round(get(handles.slider2,'Value'));

% Read status of 'Include' flag and update the GUI tick box
set(handles.checkbox2, 'Value', handles.data(slider).Include);

% Plot the filopodia trace data - whether it is included or not.
plot(handles.axes1, handles.data(slider).data_array(:,1), handles.data(slider).data_array(:,2),'-g',... 
    handles.data(slider).data_array(:,1), handles.data(slider).data_array(:,3), '-r');
xlim(handles.axes1, [handles.globals.ALIGN_WINDOW(1) handles.globals.ALIGN_WINDOW(2)]);
ylim(handles.axes1, [0 1]);

% Only update the XCorr and histogram + console if the data is included.
if handles.data(slider).Include == 1
    plot(handles.axes2, handles.data(slider).XCorr(:,2), handles.data(slider).XCorr(:,1)); % Plot XCorr

    % Calculate and draw Rho histogram
    [n, xout] = hist(handles.data(slider).Rho_array, 40); %Uses 40 bins
    plot(handles.axes3, xout, n);
    xlim(handles.axes3, [-1 1]);
    axes(handles.axes1);
    line([handles.globals.ALIGN_WINDOW], [handles.data(slider).Bait_Threshold handles.data(slider).Bait_Threshold],'Marker','.','LineStyle','--', 'Color','g');
    line([handles.globals.ALIGN_WINDOW], [handles.data(slider).Prey_Threshold handles.data(slider).Prey_Threshold],'Marker','.','LineStyle','--', 'Color','r');
    
    axes(handles.axes3);
    line([handles.data(slider).Rho_pval handles.data(slider).Rho_pval], get(handles.axes3,'YLim'),'Marker','.','LineStyle','--');
    line([handles.data(slider).Rho handles.data(slider).Rho], get(handles.axes3,'YLim'),'Marker','.','LineStyle','-');
    
    %Update the console. Use sprintf to format the string. 
    output = sprintf('\n%s\n%s %s', num2str(slider), handles.data(slider).Filename, num2str(handles.data(slider).FilopodiaID));
    output = strcat(output, sprintf('\n\nBait threshold = %5.2f', handles.data(slider).Bait_Threshold)); 
    output = strcat(output, sprintf('\nPrey threshold = %5.2f', handles.data(slider).Prey_Threshold)); 

    % were data significant? ## COULD USE AN ENUMERATED CLASS FOR THIS
    if handles.data(slider).Bait_Positive == 1
        bait = 'YES'; else bait = 'NO'; 
    end

    if handles.data(slider).Prey_Positive == 1
        prey = 'YES'; else prey = 'NO'; 
    end

    if handles.data(slider).Rho_interact == 1
        rho = 'YES'; else rho = 'NO'; 
    end
    
    if handles.data(slider).Consensus_interact == 1
        interact = '*******INTERACTION*******';
    else
        interact = 'No Interaction';
    end

    output = strcat(output, sprintf('\n\nBait exceeds threshold? %s', bait));
    output = strcat(output, sprintf('\nPrey exceeds threshold? %s', prey));
    output = strcat(output, sprintf('\nRho exceeds threshold? %s', rho));
    output = strcat(output, sprintf('\n\n%s', interact));
    set(handles.text1,'String', output);    
else
    %This filopodia has been excluded, so, just show blank axes  
    cla(handles.axes2);
    cla(handles.axes3);
    
    %Print info about why filopodium was excluded
    output = sprintf('\n%s\n%s %s', num2str(slider), handles.data(slider).Filename, num2str(handles.data(slider).FilopodiaID));
    output = strcat(output, sprintf('\n\nThis filopodium has been excluded'));
    
    %Get exclusion log, append and push to console 
    string = handles.data(slider).Exclusion_Criteria; %Read current string, append to it.
    output = strcat(output, string);
    set(handles.text1,'String', output);    
end
    
% Change background color to indicate interaction or not. 
defaultBackground = get(0,'defaultUicontrolBackgroundColor');
if handles.data(slider).Consensus_interact == 1 & handles.data(slider).Include == 1
    set(handles.text1,'BackgroundColor',[0.7 0.78 1.0]);
    set(handles.uipanel4,'BackgroundColor',[0.7 0.78 1.0]);
else
    set(handles.text1,'BackgroundColor', defaultBackground);
    set(handles.uipanel4,'BackgroundColor',defaultBackground);
end

end


